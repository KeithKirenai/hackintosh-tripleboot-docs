#!/bin/bash
# ==============================================================================
# Script de Diagnóstico Integral para macOS (Hackintosh HP Laptop 14-cm0xxx)
# Recopila estado del Backlight/eDP, Batería, Gráficos (NootedRed),
# Controladores de red/Bluetooth, Subsistema ACPI y Kexts cargados.
# ==============================================================================

LOG_FILE="$HOME/Desktop/hackintosh_full_diag_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================================================"
echo "    REPORTE DE DIAGNÓSTICO INTEGRAL DE MACOS (HACKINTOSH HP 14)"
echo "    Fecha: $(date)"
echo "    Host: $(scutil --get ComputerName 2>/dev/null || hostname)"
echo "    Versión macOS: $(sw_vers -productVersion 2>/dev/null) (Build $(sw_vers -buildVersion 2>/dev/null))"
echo "======================================================================"

echo -e "\n[1. ESTADO DE KERNEL EXTENSIONS (Lilu, NootedRed, VirtualSMC, etc.)]"
echo "----------------------------------------------------------------------"
kmutil showloaded 2>/dev/null | grep -E "Lilu|NootedRed|VirtualSMC|SMCBattery|ECEnabler|BrightnessKeys|AppleALC|Voodoo" || \
kextstat | grep -E "Lilu|NootedRed|VirtualSMC|SMCBattery|ECEnabler|BrightnessKeys|AppleALC|Voodoo"

echo -e "\n[2. PANTALLA, BACKLIGHT Y FRAMEBUFFER (NootedRed)]"
echo "----------------------------------------------------------------------"
echo "--- Objetos PNLF y Backlight en IOReg ---"
ioreg -l | grep -i -E "PNLF|AppleBacklight|backlight-level|applbkl|brightness" | head -n 40

echo -e "\n--- Servicios de Display Activos ---"
ioreg -rc AppleDisplay
ioreg -rc IODisplayConnect

echo -e "\n--- Propiedades de GPU integrada ---"
ioreg -rc AMDRadeonX5000_AmdRadeon 2>/dev/null || ioreg -rc AMDAccelerator 2>/dev/null || echo "Acelerador no localizado directamente por clase estándar."

echo -e "\n[3. GESTIÓN DE ENERGÍA Y BATERÍA (SMC / ACPI)]"
echo "----------------------------------------------------------------------"
echo "--- Resumen de pmset ---"
pmset -g batt
pmset -g assertions

echo -e "\n--- Árbol AppleSmartBattery en IOReg ---"
ioreg -rc AppleSmartBattery

echo -e "\n--- Dispositivos ACPI de Batería detectados ---"
ioreg -p IODeviceTree -n BAT0
ioreg -p IODeviceTree -n EC0

echo -e "\n[4. INTERFACES DE RED Y CONECTIVIDAD (Wi-Fi / Ethernet / BT)]"
echo "----------------------------------------------------------------------"
echo "--- Dispositivos PCI (Búsqueda de RTL8723DE) ---"
system_profiler SPPCIDataType | grep -A 10 -i -E "network|wireless|ethernet|realtek"

echo -e "\n--- Adaptador Bluetooth (Búsqueda de USB 0bda:b009) ---"
system_profiler SPUSBDataType | grep -A 8 -i -E "bluetooth|realtek"

echo -e "\n--- Interfaces de red BSD reconocidas ---"
networksetup -listallhardwareports 2>/dev/null || ifconfig -l

echo -e "\n[5. ARGUMENTOS DE ARRANQUE Y NVRAM]"
echo "----------------------------------------------------------------------"
echo "boot-args: $(sysctl -n kern.bootargs)"

echo -e "\n[6. EVENTOS DE TECLAS DE BRILLO Y HOTKEYS]"
echo "----------------------------------------------------------------------"
echo "Buscando logs de BrightnessKeys en los últimos 5 minutos..."
log show --predicate 'process CONTAINS[c] "kernel" AND composedMessage CONTAINS[c] "Brightness"' --last 5m 2>/dev/null || echo "Sin eventos de log recientes."

echo -e "\n======================================================================"
echo "Diagnóstico completado."
echo "Archivo guardado en: $LOG_FILE"
echo "======================================================================"
