#!/bin/bash
# ==============================================================================
# Telemetría Wi-Fi/BT para desarrollo de driver macOS
# Recolecta todo lo necesario para iniciar el porte de rtw88_8723de a macOS.
# Ejecutar DENTRO de macOS. Salida: ~/Desktop/rtl8723de_telemetry_*.log
# ==============================================================================

# Carpeta de logs compartida vía partición EFI si está montada
for d in "/Volumes/EFI/hackintosh" "/boot/efi/hackintosh"; do
  if [ -d "$d" ] && [ -w "$d" ]; then LOG_DIR="$d"; break; fi
done
LOG_DIR="${LOG_DIR:-$HOME/Desktop}"
mkdir -p "$LOG_DIR" 2>/dev/null
LOG_FILE="$LOG_DIR/rtl8723de_telemetry_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "======================================================================"
echo " TELEMETRÍA RTL8723DE Wi-Fi + BT — $(date)"
echo " macOS: $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo " Arquitectura: $(uname -m)   Kernel: $(uname -r)"
echo "======================================================================"

echo -e "\n### 1. IDENTIFICACIÓN PCI DEL DISPOSITIVO WIFI (10ec:d723) ###"
system_profiler SPPCIDataType | grep -B2 -A 20 -i "realtek\|network\|wireless"

echo -e "\n### 2. IDENTIFICACIÓN USB DEL BLUETOOTH (0bda:b009) ###"
system_profiler SPUSBDataType | grep -B2 -A 15 -i "realtek\|bluetooth"

echo -e "\n### 3. NODOS IOREGISTRY DEL DISPOSITIVO ###"
echo "--- Buscar nodo PCI Realtek ---"
ioreg -p IOService -l | grep -B5 -A 40 -i "10ec\|Realtek" | head -n 100
echo "--- Buscar nodos USB Bluetooth ---"
ioreg -p IOUSB -l | grep -i -B3 -A 20 "0bda\|bluetooth" | head -n 60

echo -e "\n### 4. KEXTS DE RED / WIFI / BT CARGADOS ###"
kmutil showloaded 2>/dev/null | grep -i -E "IO80211|IOBluetooth|IOEthernet|Apple|HoRNDIS|wifi|bluetooth" || \
kextstat | grep -i -E "IO80211|IOBluetooth|IOEthernet|Apple|HoRNDIS"

echo -e "\n### 5. INTERFACES Y STACK DE RED ###"
networksetup -listallhardwareports
ifconfig -l
echo "--- Rutas ---"
netstat -rn | head -10

echo -e "\n### 6. PROPIEDADES IOKIT RELEVANTES (personalities 802.11) ###"
ioreg -rc IO80211Interface 2>/dev/null | head -n 30
echo "--- DriverKit / IO80211 kexts disponibles en sistema ---"
ls /System/Library/Extensions/ | grep -i -E "IO80211|wifi"
ls /Library/Extensions/ 2>/dev/null

echo -e "\n### 7. BLUETOOTH: ESTADO Y SERVICIOS ###"
system_profiler SPBluetoothDataType | head -n 30
ps aux | grep -i bluetooth | grep -v grep

echo -e "\n### 8. BOOT-ARGS, SIP, NVRAM ###"
echo "boot-args: $(nvram boot-args 2>/dev/null)"
systemextensionsctl list 2>/dev/null | head
csrutil status 2>/dev/null || echo "(csrutil no disponible)"

echo -e "\n### 9. PERSONALITIES MATCHING PENDIENTES (IO80211 no reclama el hw) ###"
log show --last 2m --predicate 'eventMessage CONTAINS[c] "IO80211" OR eventMessage CONTAINS[c] "IOBluetooth"' 2>/dev/null | head -n 30

echo -e "\n### 10. EQUIVALENTE LINUX (si hay dual boot, pegar aquí) ###"
echo "En Linux ejecutar:"
echo "  lspci -nnk | grep -A4 -i -E 'network|realtek'"
echo "  dmesg | grep -i rtw88"
echo "  ls /sys/kernel/debug/rtw88_8723de/ 2>/dev/null"
echo "  lsusb | grep -i 0bda"
echo "  dmesg | grep -i -E 'bluetooth|rtl'"

echo -e "\n======================================================================"
echo " Telemetría guardada en: $LOG_FILE"
echo "======================================================================"
