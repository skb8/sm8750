/*
 * SM8750 / OnePlus 13 (OPlus dodge 23821) button ACPI ASL skeleton.
 *
 * Source devicetree:
 *   qcom/pmk8550.dtsi:
 *     pon_hlos@1300 pwrkey interrupts = <0x0 0x13 0x7 IRQ_TYPE_EDGE_BOTH>, KEY_POWER
 *     pon_hlos@1300 resin  interrupts = <0x0 0x13 0x6 IRQ_TYPE_EDGE_BOTH>, KEY_VOLUMEUP
 *   qcom/sun-mtp.dtsi:
 *     gpio_keys/vol_down gpios = <&pm8550_gpios 6 GPIO_ACTIVE_LOW>, KEY_VOLUMEDOWN
 *   qcom/sun-pmic-overlay.dtsi:
 *     pm8550_gpios gpio6 input-enable, bias-pull-up, power-source = <1>
 *
 * IMPORTANT:
 *   \_SB.PON0 and \_SB.PM85 are symbolic placeholders for the PMK8550 PON
 *   interrupt provider and PM8550 GPIO controller. Rename them to match the
 *   actual ACPI PMIC/SPMI/GPIO controller device paths once those controllers
 *   exist in the platform DSDT.
 */

External (\_SB.PON0, DeviceObj)  // PMK8550 PON IRQ provider placeholder
External (\_SB.PM85, DeviceObj)  // PM8550 GPIO controller placeholder

Scope (\_SB)
{
    Device (PWRB)
    {
        Name (_HID, "PNP0C0C")  // ACPI Power Button
        Name (_UID, 0)
        Name (_STA, 0x0F)

        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "linux,code", 116 },        // KEY_POWER
                Package () { "dt-source", "pmk8550 pon_hlos@1300/pwrkey" },
                Package () { "pmic-peripheral", 0x13 },
                Package () { "pmic-irq", 0x07 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                // DT: interrupts = <0x0 0x13 0x7 IRQ_TYPE_EDGE_BOTH>
                GpioInt (Edge, ActiveBoth, ExclusiveAndWake, PullNone, 0,
                    "\\_SB.PON0", 0, ResourceConsumer, , ) { 7 }
            })
        }
    }

    Device (BTNS)
    {
        Name (_HID, "ACPI0011")  // Windows-compatible button array
        Name (_CID, "PNP0C40")
        Name (_UID, 1)
        Name (_STA, 0x0F)

        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "button-count", 2 },
                Package () { "button-0", "volume-up" },
                Package () { "button-0-linux-code", 115 },    // KEY_VOLUMEUP
                Package () { "button-0-dt-source", "pmk8550 pon_hlos@1300/resin" },
                Package () { "button-1", "volume-down" },
                Package () { "button-1-linux-code", 114 },    // KEY_VOLUMEDOWN
                Package () { "button-1-dt-source", "sun-mtp gpio_keys/vol_down" }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                // Volume-up: PMK8550 RESIN, DT interrupts = <0x0 0x13 0x6 IRQ_TYPE_EDGE_BOTH>
                GpioInt (Edge, ActiveBoth, ExclusiveAndWake, PullNone, 0,
                    "\\_SB.PON0", 0, ResourceConsumer, , ) { 6 }

                // Volume-down: PM8550 GPIO6, active-low, pull-up, wake-capable.
                GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0,
                    "\\_SB.PM85", 0, ResourceConsumer, , ) { 6 }
            })
        }
    }
}
