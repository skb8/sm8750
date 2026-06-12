/*
 * SM8750 / OnePlus 13 battery/charger ACPI skeleton from official dtbo.img.
 *
 * DTBO charging stack:
 *   oplus,mms_wired + oplus,virtual_buck
 *     adc_info_name = "855", topic-update-interval = 5000 ms
 *     USB temperature ADCs 0x74a/0x75e; PM8550 GPIO6 discharge control
 *     TLMM GPIO62/63 UART TX/RX for charging communication
 *   oplus,mms_gauge + oplus,virtual_gauge
 *     capacity = 5610 mAh; silicon_p_770 override = 5920 mAh
 *   oplus_chg_core framework v2, wireless charging node oplus,chg_wls
 *
 * Windows normally needs a real Control Method Battery implementation backed by
 * PMIC/ADSP fuel-gauge data. The BAT0 methods below are safe placeholders so
 * the namespace compiles while the vendor/Qualcomm gauge interface is brought up.
 */

External (\_SB.GIO0, DeviceObj)  // TLMM GPIO controller placeholder
External (\_SB.PM85, DeviceObj)  // PM8550 GPIO controller placeholder

Scope (\_SB)
{
    Device (CHG0)
    {
        Name (_HID, "PRP0001")
        Name (_UID, 0)
        Name (_STA, 0x0F)
        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", Package () { "oplus,mms_wired", "oplus,virtual_buck", "oplus,mms_gauge", "oplus,virtual_gauge" } },
                Package () { "oplus,chg-framework-version", 2 },
                Package () { "oplus,adc-info-name", "855" },
                Package () { "oplus,topic-update-interval-ms", 5000 },
                Package () { "oplus,batt-capacity-mah", 5610 },
                Package () { "oplus,silicon-p-770-capacity-mah", 5920 },
                Package () { "oplus,usbtemp-adc-channels", Package () { 0x074A, 0x075E } },
                Package () { "oplus,usbtemp-conversion-ratio", 10 },
                Package () { "oplus,uart-gpios", Package () { 62, 63 } },
                Package () { "oplus,dischg-gpio", 6 },
                Package () { "oplus,support-usbtemp-protect-v2", 1 },
                Package () { "oplus,support-wireless-charging", 1 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                // PM8550 GPIO6 discharge control.
                GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.PM85", 0, ResourceConsumer, , ) { 6 }

                // TLMM GPIO62/63 are used by the DTBO as charging UART pins.
                GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionNone,
                    "\\_SB.GIO0", 0, ResourceConsumer, , ) { 62, 63 }
            })
        }
    }

    Device (BAT0)
    {
        Name (_HID, EisaId ("PNP0C0A"))
        Name (_UID, 0)
        Name (_STA, 0x1F)

        // ACPI 4.x _BIX package. Runtime values are placeholders until gauge data is wired.
        Method (_BIX, 0, NotSerialized)
        {
            Return (Package () {
                0,          // Revision
                1,          // Power Unit: mA/mAh
                5610,       // Design Capacity (mAh) from DTBO virtual_gauge
                5610,       // Last Full Charge Capacity placeholder
                1,          // Battery Technology: rechargeable
                16000,      // Design Voltage placeholder (mV, 4S-equivalent unknown on phone packs)
                100,        // Design Capacity of Warning
                50,         // Design Capacity of Low
                1,          // Cycle Count unknown placeholder
                1,          // Measurement Accuracy placeholder
                5000,       // Max Sampling Time ms
                5000,       // Min Sampling Time ms
                0,          // Max Averaging Interval
                0,          // Min Averaging Interval
                1,          // Battery Capacity Granularity 1
                1,          // Battery Capacity Granularity 2
                "OP13-BAT", // Model Number
                "",         // Serial Number
                "LiP",      // Battery Type
                "OPLUS"     // OEM Information
            })
        }

        Method (_BST, 0, NotSerialized)
        {
            Return (Package () { 0, 0, 0, 0 }) // State, rate, remaining capacity, voltage unknown.
        }

        Method (_BTP, 1, NotSerialized) { Return (Zero) }
    }
}
