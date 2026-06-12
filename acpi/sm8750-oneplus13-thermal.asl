/*
 * SM8750 / OnePlus 13 thermal sensor ACPI skeleton from official dtbo.img.
 *
 * DTBO exposes Qualcomm PMIC SPMI temp alarms and BCL thermal sensor resources:
 *   pm8010_m temp-alarm@0x2400, SPMI SID 0x0c, IRQ <0x0c 0x24 0x00 0x03>
 *   pm8010_n temp-alarm@0x2400, SPMI SID 0x0d, IRQ <0x0d 0x24 0x00 0x03>
 *   pm8550  temp-alarm@0x0a00, SPMI SID 0x01, IRQ <0x01 0x0a 0x00 0x03>, ADC channel 0x103
 *   pm8550  bcl@0x4700, size 0x100, IRQs level0/1/2 at periph 0x47
 *
 * This file deliberately keeps SPMI interrupt wiring symbolic because Windows
 * ACPI needs a real Qualcomm SPMI/PMIC interrupt controller namespace and driver.
 */

External (\_SB.SPMI, DeviceObj)  // Qualcomm SPMI bus/controller placeholder

Scope (\_SB)
{
    Device (THRM)
    {
        Name (_HID, "PRP0001")
        Name (_UID, 0)
        Name (_STA, 0x0F)

        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", Package () { "qcom,spmi-temp-alarm", "qcom,pm8550-bcl-v5" } },
                Package () { "dtbo-model", "Qualcomm Technologies, Inc. Sun MTP,dodge T0" },
                Package () { "oplus,project-id", Package () { 0x5D0D, 0x5D55, 0x5D56, 0x5D57 } },
                Package () { "pm8010m-temp-alarm", Package () { 0x0C, 0x2400 } },
                Package () { "pm8010n-temp-alarm", Package () { 0x0D, 0x2400 } },
                Package () { "pm8550-temp-alarm", Package () { 0x01, 0x0A00, 0x0103 } },
                Package () { "pm8550-bcl", Package () { 0x01, 0x4700, 0x0100 } },
                Package () { "pm8550-bcl-interrupt-names", Package () { "bcl-lvl0", "bcl-lvl1", "bcl-lvl2" } }
            }
        })
    }

    ThermalZone (TZP0)
    {
        Name (_TZP, 100)       // 10 seconds passive polling fallback.
        Method (_TMP, 0, NotSerialized) { Return (3002) } // 27 C in tenths Kelvin placeholder.
        Method (_CRT, 0, NotSerialized) { Return (3732) } // 100 C critical placeholder.
        Method (_HOT, 0, NotSerialized) { Return (3632) } // 90 C hot placeholder.
        Method (_PSV, 0, NotSerialized) { Return (3532) } // 80 C passive placeholder.
        Method (_TC1, 0, NotSerialized) { Return (2) }
        Method (_TC2, 0, NotSerialized) { Return (5) }
    }
}
