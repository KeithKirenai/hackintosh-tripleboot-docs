# Plan: Driver Wi-Fi (RTL8723DE) + Bluetooth (RTL8723D) para macOS

Objetivo: driver funcional y open source para el adaptador inalámbrico
Realtek RTL8723DE (`10ec:d723`) del HP Laptop 14-cm0xxx, y soporte de
Bluetooth 4.2 (`0bda:b009`), usable por la comunidad.

## Hardware objetivo
- Wi-Fi: Realtek RTL8723DE (`10ec:d723`), PCIe. En Linux: `rtw88_8723de`.
- Bluetooth: Realtek 4.2 (`0bda:b009`), USB. Requiere firmware
  `rtl8723d_fw` / `rtl8723d_config`.

## Fase 0 — Telemetría (prerequisito)
Script `scripts/wifi_bt_telemetry.sh` que desde macOS recolecte:
- IDs PCI/USB exactos, BARs, capacidades (MSI, ASPM).
- Qué kexts de red/BT están cargados y qué clases publica IO80211Family.
- Árbol IORegistry del dispositivo PCIe/USB.
- Estado de matching IOKit para RTL8723DE (`ioreg -p IOService -l`).
- Boot-args, SIP, arquitectura de kernel.
- Equivalente Linux: `lspci -nnk`, `dmesg` de rtw88, registros debugfs.

## Fase 1 — PoC de matching
- Kext C++ (IOKit/DriverKit) que solo implemente `probe`/`start`.
- Verificar en `ioreg` que aparece el nodo y en `log show` los IOLog.
- Publicar propiedades mínimas del dispositivo.

## Fase 2 — Bring-up del hardware
- Port de init de firmware RTL8723D (binario `rtw88_8723d` de Linux).
- Mapeo MMIO de BARs, rings TX/RX, interrupciones MSI.
- Leer MAC address y estado de radio.

## Fase 3 — Funcional
- Integración con IO80211Family: scan, auth, assoc, TX/RX de datos.
- Gestión de antena (`ant_sel` fijo MAIN/AUX).
- Bluetooth: shim USB que cargue firmware y delegue en stack nativo
  (modelo BrcmPatchRAM).

## Fase 4 — Publicación
- Repo GitHub con fuentes, build (Xcode/Makefile), docs, README.
- Guía de instalación vía OpenCore (kext en EFI).

## Referencias
- Linux: driver `rtw88` (kernel mainline), debugfs en
  `/sys/kernel/debug/rtw88_8723de`.
- macOS: `IO80211Family`, `itlwm` (OpenIntelWireless) como modelo.
- BrcmPatchRAM como modelo para BT/firmware.

## Estado
- [x] Hardware identificado y documentado (README sección 7.C)
- [ ] Script de telemetría Fase 0
- [ ] PoC Fase 1
- [ ] ...
