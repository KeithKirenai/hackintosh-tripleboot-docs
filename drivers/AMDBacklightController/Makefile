#
# Makefile para compilar AMDBacklightController.kext en macOS
# Requiere Xcode Command Line Tools instaladas en macOS
#

KEXT_NAME = AMDBacklightController
BUNDLE_DIR = $(KEXT_NAME).kext
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS

CXX ?= clang++
CXXFLAGS = -x c++ -std=c++17 -nostdinc++ -mkernel -fno-builtin -fno-common \
           -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables -fno-unwind-tables \
           -Wall -Wextra -O2 -arch x86_64 -isysroot $(shell xcrun --show-sdk-path)

INCLUDES = -Isrc \
           -I$(shell xcrun --show-sdk-path)/System/Library/Frameworks/Kernel.framework/Headers

LDFLAGS = -Xlinker -kext -nostdlib -lkmodc++ -lkmod -lcc_kext \
          -arch x86_64 -isysroot $(shell xcrun --show-sdk-path)

SOURCES = src/AMDBacklightController.cpp
OBJECTS = $(SOURCES:.cpp=.o)

all: $(BUNDLE_DIR)

$(BUNDLE_DIR): $(MACOS_DIR)/$(KEXT_NAME)
	@mkdir -p $(CONTENTS_DIR)
	@cp Info.plist $(CONTENTS_DIR)/Info.plist
	@echo "==> $(BUNDLE_DIR) compilado con éxito."

$(MACOS_DIR)/$(KEXT_NAME): $(OBJECTS)
	@mkdir -p $(MACOS_DIR)
	$(CXX) $(LDFLAGS) $(OBJECTS) -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(OBJECTS) $(BUNDLE_DIR)

.PHONY: all clean
