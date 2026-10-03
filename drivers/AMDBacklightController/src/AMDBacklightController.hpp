/*
 * AMDBacklightController.hpp
 * Definición del driver IOKit para modulación PWM directa en AMD Raven Ridge
 */

#ifndef AMD_BACKLIGHT_CONTROLLER_HPP
#define AMD_BACKLIGHT_CONTROLLER_HPP

#include <IOKit/IOService.h>
#include <IOKit/pci/IOPCIDevice.h>
#include "AMDBacklightRegisters.h"

class AMDBacklightController : public IOService
{
    OSDeclareDefaultStructors(AMDBacklightController)

private:
    IOPCIDevice*            fPciDevice;
    IOMemoryMap*            fMmioMap;
    volatile uint8_t*       fMmioBase;
    uint32_t                fCurrentLevel;

    uint32_t readRegister(uint32_t offset);
    void writeRegister(uint32_t offset, uint32_t value);

public:
    virtual bool init(OSDictionary* dictionary = nullptr) override;
    virtual void free() override;
    
    virtual IOService* probe(IOService* provider, SInt32* score) override;
    virtual bool start(IOService* provider) override;
    virtual void stop(IOService* provider) override;

    // Métodos de control de retroiluminación
    IOReturn setBrightness(uint32_t level);
    uint32_t getBrightness();
    IOReturn setBrightnessSmooth(uint32_t targetLevel, uint32_t durationMs = 180);
};

#endif /* AMD_BACKLIGHT_CONTROLLER_HPP */
