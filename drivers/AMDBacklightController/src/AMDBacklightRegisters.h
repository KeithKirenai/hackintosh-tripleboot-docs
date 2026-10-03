/*
 * AMDBacklightRegisters.h
 * Offsets y máscaras de registros de hardware para el transmisor eDP
 * en GPUs AMD Radeon Vega Mobile (Raven Ridge - DCN 1.0)
 *
 * Base física comprobada: BAR 5 (0xfcd00000)
 */

#ifndef AMD_BACKLIGHT_REGISTERS_H
#define AMD_BACKLIGHT_REGISTERS_H

#include <stdint.h>

// Dirección base física en HP Laptop 14-cm0xxx
#define AMD_RAVEN_MMIO_BASE             0xFCD00000
#define AMD_RAVEN_MMIO_SIZE             0x00080000 // 512 KB

// Offsets del bloque Display Controller Engine / DCN1
// Bloque LVTMA (Low Voltage Transmitter Macro / eDP Backlight Control)
#define DCN1_LVTMA_PWRSEQ_CNTL          0x16800
#define DCN1_LVTMA_PWRSEQ_STATE         0x16804
#define DCN1_LVTMA_BL_PWM_CNTL          0x16820
#define DCN1_LVTMA_BL_PWM_USER_LEVEL    0x16824

// Registro de control PWM de nivel de usuario
// Bits [15:0] o [7:0] determinan la fracción de ciclo de trabajo (Duty Cycle)
#define BL_PWM_USER_LEVEL_MASK          0x0000FFFF
#define BL_PWM_USER_LEVEL_SHIFT         0

// Rango de escala
#define AMD_BACKLIGHT_MIN_LEVEL         1
#define AMD_BACKLIGHT_MAX_LEVEL         255

#endif /* AMD_BACKLIGHT_REGISTERS_H */
