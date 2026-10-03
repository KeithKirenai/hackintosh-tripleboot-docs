# Documentación Técnica: Triple Boot (Linux / Windows / macOS) & Hackintosh HP 14-cm0xxx

Este proyecto documenta la configuración del gestor de arranque, optimizaciones del sistema y soluciones de hardware aplicadas para el arranque múltiple en la **HP Laptop 14-cm0xxx**.

---

## 1. Especificaciones de Hardware

* **Equipo:** HP Laptop 14-cm0xxx (Placa base HP `84A2`)
* **Procesador / iGPU:** AMD Raven Ridge (Radeon Vega Mobile Series - `1002:15dd`)
* **Audio Códec:** Realtek ALC236 (`10ec:0236`) en controlador HDA AMD (`1022:15e3`)
* **Almacenamiento:** NVMe SSD (`/dev/nvme0n1`)
* **Sistemas Operativos:**
  1. **Debian GNU/Linux 13 (Trixie)** (`/dev/nvme0n1p3`)
  2. **Microsoft Windows 11** (`/dev/nvme0n1p4`)
  3. **macOS** (Partición APFS: `/dev/nvme0n1p5`)

---

## 2. Gestor de Arranque: rEFInd + OpenCore

Para lograr una interfaz gráfica limpia y moderna con exactamente **3 iconos horizontales**, se configuró **rEFInd** como gestor principal de la placa UEFI:

### Estructura en `/boot/efi/EFI/refind/refind.conf`:
* **Tema visual:** `refind-theme-regular` (iconos redondeados `128x128px` con fondo oscuro).
* **Escaneo:** `scanfor manual,external` (para ocultar entradas duplicadas y herramientas no deseadas).
* **Entradas declaradas:**
  * **Debian Linux:** `/EFI/debian/grubx64.efi`
  * **Windows 11:** `/EFI/Microsoft/Boot/bootmgfw.efi`
  * **macOS:** `/EFI/OC/OpenCore.efi`
* **Tiempo de espera:** `timeout 5`

### Configuración Directa de OpenCore:
Para evitar un menú secundario tras seleccionar macOS en rEFInd:
* `Misc -> Boot -> ShowPicker = False`
* `Misc -> Boot -> Timeout = 0`
* `Misc -> Boot -> PollAppleHotKeys = True` *(Permite mantener presionada la tecla `Alt`/`Option` o `Esc` si se necesita acceder al menú de OpenCore para reiniciar la NVRAM).*

---

## 3. Optimizaciones de Velocidad de Arranque

### En Linux (Debian):
* **Docker:** Se cambió de inicio automático como servicio a activación por socket bajo demanda para ahorrar más de 7 segundos en el camino crítico del arranque:
  ```bash
  sudo systemctl disable docker.service
  sudo systemctl enable docker.socket
  ```
* **GRUB:** Tiempo de espera reducido a 2 segundos si se ingresa mediante GRUB de respaldo.

### En macOS (OpenCore):
* **TRIM en NVMe:** `Kernel -> Quirks -> SetApfsTrimTimeout = 0` (elimina la demora de entre 10 y 25 segundos en SSDs NVMe no Apple durante el arranque).
* **Eliminación de banderas de depuración:** Se retiraron `debug=0x100` y `keepsyms=1` de los `boot-args` de NVRAM.

---

## 4. Audio (Realtek ALC236)

* **Problema:** Sin salida de sonido ni control de volumen con `alcid=1` (diseñado para Intel de escritorio).
* **Solución:**
  * Inyección de **`alcid=3`** en los argumentos de arranque de OpenCore:
    ```text
    boot-args: alcid=3 ...
    ```
  * Eliminación de la entrada obsoleta de Intel en `DeviceProperties` (`PciRoot(0x0)/Pci(0x1b,0x0)`).
* **Layouts alternativos documentados para ALC236 en HP:** `11`, `13`, `14`.

---

## 5. Gráficos, Apagado y Control de Brillo (NootedRed)

### A. Corrupción de pantalla al apagar:
* **Causa:** El argumento `-nredfbonly` forzaba a NootedRed a correr en modo Framebuffer Only sin aceleración completa de hardware Metal (QE/CI), rompiendo la sincronización de energía del panel eDP antes de cortar la corriente.
* **Solución:** Retirado `-nredfbonly` de `boot-args`.

### B. Control de Brillo Nativo (PWM):
* **Ruta ACPI del Panel:**
  ```text
  \_SB.PCI0.GP17.VGA.LCD
  ```
* **Implementación:**
  1. Tabla compilada **`SSDT-PNLF.aml`** instalada en `/boot/efi/EFI/OC/ACPI/`:
     * Alcance: `Scope (\_SB.PCI0.GP17.VGA)`
     * `_UID: 0x11` (17 decimal, valor requerido para controladores PWM en APUs AMD).
  2. Banderas de arranque para Lilu/NootedRed:
     * **`applbkl=3`** para enlazar la modulación PWM de la GPU integrada con `AppleBacklight`.

---

## 6. Copias de Respaldo

En la carpeta `./backups` se incluyen copias de los archivos de configuración funcionales:
* `backups/config.plist`: Configuración activa de OpenCore.
* `backups/refind.conf`: Configuración activa de rEFInd.
