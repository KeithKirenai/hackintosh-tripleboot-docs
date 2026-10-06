# RTL8723DEProbe — Fase 1 (PoC matching)

Kext de diagnóstico mínimo: hace match con el PCI `10ec:d723` del RTL8723DE
para confirmar visibilidad del dispositivo desde IOKit.

## Compilar (en macOS / Xcode)
1. Xcode → New Project → macOS → I/O Kit Driver (kernel extension)
2. Copiar `RTL8723DEProbe.h` y `RTL8723DEProbe.cpp` al target
3. Reemplazar `Contents/Info.plist` generado por este (o editarlo: IOPCIMatch `0xD72310ec`)
4. Build → produce `RTL8723DEProbe.kext`

Alternativa rápida con xcodebuild desde terminal en el .xcodeproj:
```bash
xcodebuild -project RTL8723DEProbe.xcodeproj -scheme RTL8723DEProbe \
    -configuration Release build
```

## Instalar en la hackintosh
```bash
sudo cp -R RTL8723DEProbe.kext /Library/Extensions/
sudo kextcache --i-cache /
# reiniciar, o en OC: copiar el .kext a EFI/OC/Kexts y añadir entrada en config.plist
```

## Verificar
```bash
ioregistryentry -l -c RTL8723DEProbe
log show --last 2m --predicate 'eventMessage CONTAINS "RTL8723DEProbe"'
kextstat | grep RTL8723DEProbe
```

Si aparece el nodo y los IOLog, el siguiente paso (Fase 2) es mapear BARs y
extraer los recursos PCI con `provider->mapDeviceMemoryWithRegister(0)`.
