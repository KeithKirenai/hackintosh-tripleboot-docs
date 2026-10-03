#!/bin/bash
clear
echo "=========================================================="
echo "    DIAGNOSTICO INTEGRAL REFINADO V4 (USB MODE)          "
echo "    - Mapeo de Registros GPU / DCN1 y Subsistema Display - "
echo "=========================================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/DIAGNOSTICO_MAC_RESULTS_FULL"
mkdir -p "$OUTPUT_DIR"

LOG_FILE="$OUTPUT_DIR/reporte_refinado_$(date +%Y%m%d_%H%M%S).txt"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Fecha: $(date)"
echo "Darwin: $(uname -a)"
echo "macOS: $(sw_vers -productVersion) (Build $(sw_vers -buildVersion))"
echo "boot-args: $(sysctl -n kern.bootargs)"

echo -e "\n--- 1. MENSAJES DE KERNEL DE NOOTEDRED Y BACKLIGHT (dmesg) ---"
sudo dmesg | grep -i -E "NRed|NootedRed|backlight|AppleIntelPanel|AppleBacklight|dce_driver|dc_link|GOP|Console|display|IOAccelDisplayPipe"

echo -e "\n--- 2. DETALLE DE REGISTROS DE GPU EN IOREG (BARs y Memoria Mapeada) ---"
ioreg -p IOService -w0 -l -r -n "IGPU" | grep -E "assigned-addresses|IOPhysicalAddress|IOGPU|model|VRAM"

echo -e "\n--- 3. CLASES DE BACKLIGHT Y PANELES REGISTRADOS EN IOKIT ---"
ioreg -r -c AppleDisplay
ioreg -r -c IODisplayConnect
ioreg -r -c AppleBacklightDisplay 2>/dev/null || echo "AppleBacklightDisplay no presente."

echo -e "\n--- 4. OBJETOS ACPI RELEVANTES (_BCM / AFN7 / PNLF / LCD) ---"
ioreg -p IODeviceTree -w0 -l | grep -A 10 -i "PNLF"
ioreg -p IODeviceTree -w0 -l | grep -A 10 -i "LCD"

echo -e "\n--- 5. PRUEBA DE CONTROLADORES DE BRILLO POR SOFTWARE (MonitorControl) ---"
pgrep -fl "MonitorControl" || echo "MonitorControl no está corriendo actualmente."

sync
echo -e "\n=========================================================="
echo "  LISTO! Diagnostico V4 guardado con exito en la USB.    "
echo "=========================================================="
echo "Ya puedes cerrar la terminal y regresar a Linux."
read -p "Presiona ENTER para salir..." dummy
