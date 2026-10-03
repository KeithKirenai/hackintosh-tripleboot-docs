/*
 * AMDBacklightController.cpp
 * Implementación de bajo nivel para lectura/escritura en BAR5 (MMIO)
 * y modulación física de ancho de pulso (PWM) en macOS
 */

#include "AMDBacklightController.hpp"
#include <IOKit/IOLib.h>

#define super IOService
OSDefineMetaClassAndStructors(AMDBacklightController, IOService)

bool AMDBacklightController::init(OSDictionary* dictionary)
{
    if (!super::init(dictionary))
        return false;

    fPciDevice = nullptr;
    fMmioMap = nullptr;
    fMmioBase = nullptr;
    fCurrentLevel = 128; // 50% por defecto inicial

    IOLog("AMDBacklightController: Inicializado con soporte DCN1 (Raven Ridge).\n");
    return true;
}

void AMDBacklightController::free()
{
    if (fMmioMap) {
        fMmioMap->release();
        fMmioMap = nullptr;
    }
    super::free();
}

IOService* AMDBacklightController::probe(IOService* provider, SInt32* score)
{
    if (!super::probe(provider, score))
        return nullptr;

    IOPCIDevice* pci = OSDynamicCast(IOPCIDevice, provider);
    if (!pci)
        return nullptr;

    // Verificar si es la GPU AMD Raven Ridge (Vendor: 0x1002, Device: 0x15dd)
    uint16_t vendorId = pci->configRead16(kIOPCIConfigVendorID);
    uint16_t deviceId = pci->configRead16(kIOPCIConfigDeviceID);

    if (vendorId == 0x1002 && deviceId == 0x15dd) {
        IOLog("AMDBacklightController: Dispositivo Raven Ridge coincidente [1002:15dd] en probe().\n");
        *score += 500;
        return this;
    }

    return nullptr;
}

bool AMDBacklightController::start(IOService* provider)
{
    if (!super::start(provider))
        return false;

    fPciDevice = OSDynamicCast(IOPCIDevice, provider);
    if (!fPciDevice) {
        IOLog("AMDBacklightController: Error, el proveedor no es un IOPCIDevice válido.\n");
        return false;
    }

    // Mapear BAR 5 (Índice de memoria 5 según configuración PCI estándar)
    // Dirección física esperada: 0xfcd00000 (512 KB)
    fMmioMap = fPciDevice->mapDeviceMemoryWithIndex(5);
    if (!fMmioMap) {
        IOLog("AMDBacklightController: Advertencia al mapear BAR 5 por índice. Intentando fallback.\n");
        fMmioMap = fPciDevice->mapDeviceMemoryWithRegister(kIOPCIConfigBaseAddress5);
    }

    if (!fMmioMap) {
        IOLog("AMDBacklightController: Fallo crítico mapeando espacio MMIO de BAR 5.\n");
        return false;
    }

    fMmioBase = reinterpret_cast<volatile uint8_t*>(fMmioMap->getVirtualAddress());
    IOLog("AMDBacklightController: BAR 5 MMIO mapeado en memoria virtual: %p (Física: 0x%llx).\n",
          fMmioBase, fMmioMap->getPhysicalAddress());

    // Publicar capacidades en el árbol IOKit
    registerService();
    publishResource("AMDBacklightService", this);

    // Leer nivel actual del hardware
    fCurrentLevel = getBrightness();
    IOLog("AMDBacklightController: Nivel de brillo actual reportado por hardware: %u\n", fCurrentLevel);

    return true;
}

void AMDBacklightController::stop(IOService* provider)
{
    if (fMmioMap) {
        fMmioMap->release();
        fMmioMap = nullptr;
        fMmioBase = nullptr;
    }
    super::stop(provider);
}

uint32_t AMDBacklightController::readRegister(uint32_t offset)
{
    if (!fMmioBase || offset >= AMD_RAVEN_MMIO_SIZE)
        return 0;

    return *reinterpret_cast<volatile uint32_t*>(fMmioBase + offset);
}

void AMDBacklightController::writeRegister(uint32_t offset, uint32_t value)
{
    if (!fMmioBase || offset >= AMD_RAVEN_MMIO_SIZE)
        return;

    *reinterpret_cast<volatile uint32_t*>(fMmioBase + offset) = value;
}

uint32_t AMDBacklightController::getBrightness()
{
    uint32_t raw = readRegister(DCN1_LVTMA_BL_PWM_USER_LEVEL);
    return (raw & BL_PWM_USER_LEVEL_MASK) >> BL_PWM_USER_LEVEL_SHIFT;
}

IOReturn AMDBacklightController::setBrightness(uint32_t level)
{
    if (level < AMD_BACKLIGHT_MIN_LEVEL) level = AMD_BACKLIGHT_MIN_LEVEL;
    if (level > AMD_BACKLIGHT_MAX_LEVEL) level = AMD_BACKLIGHT_MAX_LEVEL;

    // Asegurar que el control PWM esté habilitado
    uint32_t pwmCntl = readRegister(DCN1_LVTMA_BL_PWM_CNTL);
    if (!(pwmCntl & 1)) {
        writeRegister(DCN1_LVTMA_BL_PWM_CNTL, pwmCntl | 1);
    }

    // Escribir el nuevo ciclo de trabajo al registro DCN1
    uint32_t currentReg = readRegister(DCN1_LVTMA_BL_PWM_USER_LEVEL);
    currentReg &= ~BL_PWM_USER_LEVEL_MASK;
    currentReg |= (level << BL_PWM_USER_LEVEL_SHIFT) & BL_PWM_USER_LEVEL_MASK;

    writeRegister(DCN1_LVTMA_BL_PWM_USER_LEVEL, currentReg);
    fCurrentLevel = level;

    return kIOReturnSuccess;
}

IOReturn AMDBacklightController::setBrightnessSmooth(uint32_t targetLevel, uint32_t durationMs)
{
    uint32_t start = getBrightness();
    if (start == targetLevel)
        return kIOReturnSuccess;

    int32_t diff = static_cast<int32_t>(targetLevel) - static_cast<int32_t>(start);
    uint32_t steps = (durationMs > 0) ? (durationMs / 8) : 10;
    if (steps < 5) steps = 5;

    uint32_t sleepUs = (durationMs * 1000) / steps;

    for (uint32_t i = 1; i <= steps; ++i) {
        float t = static_cast<float>(i) / steps;
        // Curva sigmoide suave cúbica (3t^2 - 2t^3)
        float factor = 3.0f * (t * t) - 2.0f * (t * t * t);
        uint32_t val = static_cast<uint32_t>(start + (diff * factor));
        setBrightness(val);
        IODelay(sleepUs);
    }

    return setBrightness(targetLevel);
}
