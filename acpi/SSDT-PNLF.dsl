/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of SSDT-PNLF.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000082 (130)
 *     Revision         0x02
 *     Checksum         0x86
 *     OEM ID           "CORP"
 *     OEM Table ID     "PNLF"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20250404 (539296772)
 */
DefinitionBlock ("", "SSDT", 2, "CORP", "PNLF", 0x00000000)
{
    External (_SB_.PCI0.GP17.VGA_, DeviceObj)

    Scope (\_SB.PCI0.GP17.VGA)
    {
        Device (PNLF)
        {
            Name (_HID, EisaId ("APP0002"))  // _HID: Hardware ID
            Name (_CID, "backlight")  // _CID: Compatible ID
            Name (_UID, 0x13)  // _UID: Unique ID
            Name (_STA, 0x0B)  // _STA: Status
        }
    }
}

