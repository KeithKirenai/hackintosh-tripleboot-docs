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

### B. Control de Brillo: Arquitectura (GPU PWM vs. ACPI Firmware) y Solución macOS:
* **Diferencias de control en hardware:**
  1. **Control Firmware / ACPI (BIOS/EC):** Métodos como `_BCM` o interfaces propietarias WMI (HP Hotkeys). Windows y Linux pueden usarlo mediante el Embedded Controller, pero suele tener saltos discretos o causar colisiones cuando coexiste con el driver gráfico.
  2. **Control Directo de GPU (PWM Hardware):** El driver escribe directo a los registros del controlador de pantalla (`amdgpu_bl0`), modulando la señal de pulso (PWM) del bus eDP.
* **Comportamiento en macOS:**
  * macOS **no** utiliza métodos ACPI (`_BCM`/WMI) para regular la luz de fondo; depende exclusivamente de `AppleBacklight` interactuando con los registros de la GPU.
  * Para que macOS reconozca la pantalla interna eDP y active el driver de luz de fondo, requiere un dispositivo ACPI simulado `PNLF` (`Device (PNLF)`) situado bajo la ruta de la iGPU con el identificador adecuado para AMD Raven Ridge (`_UID = 0x11` / 17 decimal).
* **Ruta ACPI del Panel en HP Laptop 14-cm0xxx:**
  ```text
  \_SB.PCI0.GP17.VGA.LCD
  ```
* **Implementación aplicada:**
  1. **Tabla `SSDT-PNLF.aml`:**
     * **`Scope (\_SB)`**: Ubicación global requerida por la especificación de Apple para que el subsistema ACPI registre el dispositivo `PNLF` (`APP0002`) en el catálogo raíz de hardware de pantalla.
     * **`Name (_UID, 0x13)`**: Identificador 19 decimal requerido para motores de pantalla AMD **DCN1** (*Display Core Next 1.0*) presentes en la arquitectura Raven Ridge (`1002:15dd`).
  2. **Inyección de Conector eDP (`DeviceProperties -> Add -> PciRoot(0x0)/Pci(0x8,0x1)/Pci(0x0,0x0)`):**
     * Inyección forzada de **`@0,connector-type = <00 04 00 00>`** (eDP) y **`@0,built-in = <01 00 00 00>`**.
  3. **Argumentos de arranque (NVRAM -> boot-args):**
     * **`applbkl=3`**: Acopla el control PWM a los registros de la GPU AMD Vega.
     * **`radpg=15`**: Deshabilita el power-gating agresivo en los bloques DCN1 de Raven Ridge para prevenir el fallo `0xe00002bc` durante las transiciones de apagado.
  4. **Control por Teclado:**
     * Enlace de eventos de teclas de brillo con `BrightnessKeys.kext`.

---

## 6. Estado de Hardware Pendiente y Diagnóstico

### A. Batería (SMCBatteryManager - Funcional):
* **Estado:** Totalmente resuelto al habilitar `SMCBatteryManager.kext = True` junto a `ECEnabler.kext`. Porcentaje y estado de carga se leen nativamente desde `BAT0`.

### B. Corrupción gráfica del logo al apagar:
* **Diagnóstico profundo con reporte V2:**
  * El kernel reportó el fallo: `IOReturn IOAccelDisplayPipeTransaction2::set_transaction_args returning error 0xe00002bc for transaction(3/4)`.
  * Este error demuestra que el driver de aceleración Metal de AMD (`IOAcceleratorFamily2`) rechaza la transacción de cambio de modo de pantalla que el kernel solicita justo antes de apagar la GPU.
  * `DirectGopRendering = True` intensificaba la rotura al intentar escribir directo a un búfer UEFI desalineado; se restauró `DirectGopRendering = False` y se mantiene `SanitiseClearScreen = True` junto a `ProvideConsoleGop = True`.

### C. Conectividad Inalámbrica (Wi-Fi y Bluetooth):
* **Wi-Fi:** `Realtek RTL8723DE` (`10ec:d723` PCIe). No cuenta con soporte nativo en macOS.
  * *Estado actual:* Se utiliza tethering USB por teléfono con `HoRNDIS.kext`.
  * *Plan de desarrollo de Driver:* Para crear un driver comunitario o portar el soporte de Linux (`rtw88_8723de`) a macOS:
    1. Base en el framework **IO80211Family** / DriverKit de macOS.
    2. Adaptación del HAL de radio y calibración de antena de Linux (`rtw88`) hacia un kext de kernel C++ (similar a cómo *OpenIntelWireless* adaptó `iwlwifi` en `itlwm`).
    3. Manejo de conmutación de antena (el RTL8723DE en laptops HP suele tener 1 sola antena física conectada en AUX o MAIN, requiriendo fijar `ant_sel` para evitar señal nula).
* **Bluetooth:** `Realtek Bluetooth 4.2 Adapter` (`0bda:b009` USB).
  * Requiere inyección de firmware RAM (`rtl8723d_fw` / `rtl8723d_config`) vía USB stack durante la fase de inicialización.

---

## 7. Scripts de Diagnóstico Automatizado

Para depurar problemas desde macOS sin necesidad de adivinar el estado de IOReg o kernel logs:

* **Script:** [`scripts/mac_full_diagnostic.sh`](file:///home/carlos/Proyectos/hackintosh-tripleboot-docs/scripts/mac_full_diagnostic.sh) (copiado también a `~/Desktop/mac_full_diagnostic.sh`).
* **Uso en macOS:**
  ```bash
  bash ~/Desktop/mac_full_diagnostic.sh
  ```
* **Cobertura del diagnóstico:**
  1. Kexts cargados en memoria de kernel (`kmutil showloaded`).
  2. Estado del panel eDP, servicios `AppleDisplay` y árbol `PNLF` en `IOReg`.
  3. Lecturas del subsistema de batería (`pmset`, `AppleSmartBattery`, nodos ACPI `BAT0`/`EC0`).
  4. Reconocimiento de hardware PCI/USB (RTL8723DE y Bluetooth).
  5. Interceptación de eventos de teclas de brillo en el registro unificado del sistema (`log show`).

---

## 8. Desarrollo de Parches Manuales & Contribución Comunitaria (GitHub)

### A. Diagnóstico de Bajo Nivel del Hardware (AMD Raven Ridge):
* **Por qué falló MonitorControl / DDC-CI:**
  Las herramientas de usuario como `MonitorControl` dependen de enviar comandos DDC/CI a través de líneas I2C. En portátiles con paneles internos conectados por el bus **eDP (Embedded DisplayPort)** de la APU AMD, el panel no responde a DDC/CI. Por esta razón, el OSD gráfico sube y baja pero la intensidad física de los LEDs de la pantalla permanece estática.
* **Mapeo de Hardware Real (Comprobado en Linux):**
  * Tarjeta gráfica: AMD Radeon Vega Mobile (`1002:15dd`) en `04:00.0`.
  * **BAR 5 (Registros MMIO del Motor Gráfico DCN1):** Dirección base física `0xfcd00000` (512 KB).
  * En Linux, el driver `amdgpu` modula los registros `LVTMA_BL_PWM_USER_LEVEL` directamente sobre este bloque de memoria para regular la corriente de la retroiluminación en `/sys/class/backlight/amdgpu_bl0`.
  * En ACPI, la BIOS de HP expone el método `AFN7 (Local0)` bajo `\_SB.PCI0.GP17.VGA` que actualiza el búfer `ATIB` y genera `Notify (VGA, 0x81)` para que el driver programe la GPU.

### B. Análisis de Causa Raíz de la Ausencia de `AppleBacklightDisplay`:
Al analizar exhaustivamente el reporte refinado `reporte_refinado_20261003_093800.txt` y el código fuente del subsistema de display de Apple y NootedRed, se descubrieron tres discrepancias críticas que impedían a macOS enlazar el controlador de brillo:
1. **Tipo de Conector en `DeviceProperties`:**
   * En `config.plist`, la salida `@0,connector-type` estaba configurada como `<00 04 00 00>` (`AAQAAA==`), que corresponde a un puerto **DisplayPort externo**. Por esta razón, macOS instanciaba la clase genérica `AppleDisplay` (monitor externo) en lugar de `AppleBacklightDisplay`.
   * **Corrección:** Se modificó a `<02 00 00 00>` (`AgAAAA==`), identificando explícitamente el puerto `@0` como pantalla interna de portátil (LVDS / eDP).
2. **Ruta y Alcance de ACPI para `SSDT-PNLF`:**
   * El dispositivo `PNLF` estaba declarado globalmente bajo `Scope (_SB)` con compatibilidad genérica `panldev`. macOS y el controlador gráfico exigen que `PNLF` resida dentro del alcance exacto de la GPU: `Scope (\_SB.PCI0.GP17.VGA)` y con `_CID = "backlight"`.
   * **Corrección:** Se recompiló `SSDT-PNLF.aml` bajo `Scope (\_SB.PCI0.GP17.VGA)`.
3. **Sensor de Luz Ambiental Simulado (`SSDT-ALS0` y `SMCLightSensor`):**
   * Desde macOS Catalina (10.15) y Monterey (12.x), el framework de control de pantallas exige la presencia de un sensor de luz ambiental (`ALS0`). Al carecer el portátil de sensor físico, se integró `SSDT-ALS0.aml` y `SMCLightSensor.kext` vinculado a VirtualSMC.

### C. Solución Inmediata sin Recompilación ni Consumo de Espacio (MonitorControl - Modo Software/Gamma):
* **Por qué falló el comando `make`:** Al invocar `make` en un macOS recién instalado, el sistema ejecuta un shim interceptor que exige instalar las *Xcode Command Line Tools* (las cuales solicitan 20 GB de espacio libre, superando los 15 GB disponibles). **No es necesario compilar nada.**
* **Solución inmediata 100% funcional con MonitorControl:**
  1. En macOS, abre el archivo `MonitorControl.dmg` ubicado en la raíz de la USB de rescate (`/Volumes/OPENCORE/MonitorControl.dmg`) y arrastra la app a `Aplicaciones`.
  2. Abre MonitorControl y ve a **Preferencias (Ajustes) -> Pantallas**.
  3. En el método de control de la pantalla integrada, cambia de **Hardware (DDC)** a **Software (Gamma/Shade)** o **Ambos (Combinado)**.
  4. ¡Listo! El control deslizante de la barra de menús y las teclas de brillo F2/F3 atenuarán suavemente la pantalla desde el 100% hasta el 0% mediante las tablas de color de macOS, sin requerir comandos DDC ni recompilación de kernel.

---

## 9. Copias de Respaldo

En la carpeta `./backups` se incluyen copias de los archivos de configuración funcionales:
* `backups/config.plist`: Configuración activa de OpenCore (con `SMCBatteryManager.kext`, `SMCLightSensor.kext`, `SSDT-ALS0`, `SSDT-PNLF` bajo `GP17.VGA`, `connector-type` LVDS y `AMDBacklight=1`).
* `backups/refind.conf`: Configuración activa de rEFInd.

