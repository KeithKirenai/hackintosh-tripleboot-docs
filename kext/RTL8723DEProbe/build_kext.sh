#!/bin/bash
# Compila RTL8723DEProbe.kext sin Xcode, solo con clang + SDK de macOS.
# Pensado para correr en un GitHub Actions macos-runner.
set -e

cd "$(dirname "$0")"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
KERN="$SDK/System/Library/Frameworks/Kernel.framework/Versions/A/Headers"
OUT="build"
KEXT="$OUT/RTL8723DEProbe.kext/Contents"

mkdir -p "$KEXT/MacOS" "$KEXT/Resources" "$OUT"

clang++ -arch x86_64 -target x86_64-apple-macos12 \
  -isysroot "$SDK" \
  -I"$KERN" -I"$KERN/libkern" -I"$KERN/IOKit" \
  -fno-exceptions -fno-rtti -fno-builtin -fvisibility=hidden \
  -fno-common -fasm-blocks -std=c++17 \
  -c RTL8723DEProbe.cpp -o "$OUT/RTL8723DEProbe.o"

cp Contents/Info.plist "$OUT/info.plist"

ld -arch x86_64 -bundle -undefined dynamic_lookup \
  -sectcreate __TEXT __info_plist "$OUT/info.plist" \
  "$OUT/RTL8723DEProbe.o" -o "$KEXT/MacOS/RTL8723DEProbe"

cp Contents/Info.plist "$KEXT/Info.plist"
mkdir -p "$KEXT/Resources"

echo "Kext empaquetado en $OUT/RTL8723DEProbe.kext"
ls -la "$KEXT/MacOS"
