/*
 * SM8750 / OnePlus 13 (OPlus dodge 23821) Synaptics S3910 touchscreen ASL skeleton.
 *
 * Source devicetree:
 *   oplus/tp/dodge-oplus-tp-23821.dtsi
 *     &qupv3_se4_spi status = "ok"
 *     synaptics_tcm_hbp@0 status = "okay"
 *       compatible = "synaptics,tcm-spi-hbp"
 *       reg = <0>; chip-name = "S3910"; spi-max-frequency = <19000000>
 *       interrupts = <162 0x2008>
 *       synaptics,irq-gpio = <&tlmm 162 0x2008>
 *       synaptics,reset-gpio = <&tlmm 161 0x1>
 *       synaptics,avdd-gpio = <&pm8550vs_j_gpios 3 0x1>
 *       vdd-supply = <&L4B>; synaptics,vdd-name = "vdd"
 *       touchpanel,panel-coords = <23040 50688>
 *       touchpanel,tx-rx-num = <17 38>
 *   qcom/sun-qupv3.dtsi
 *     qupv3_se4_spi: spi@a90000 reg = <0x0a90000 0x4000>
 *     interrupts = <GIC_SPI 357 IRQ_TYPE_LEVEL_HIGH> => ACPI GSIV 389
 *
 * IMPORTANT:
 *   \_SB.GIO0 and \_SB.PMJ0 are symbolic placeholders for TLMM and PM8550VS-J
 *   GPIO controllers. Rename to real ACPI GPIO controller paths. Windows will
 *   also need a Synaptics S3910/SPI-HBP ACPI driver; this is a resource
 *   description, not a replacement for that driver.
 */

External (\_SB.GIO0, DeviceObj)  // TLMM GPIO controller placeholder
External (\_SB.PMJ0, DeviceObj)  // PM8550VS-J GPIO controller placeholder

Scope (\_SB)
{
    Device (SPI4)
    {
        Name (_HID, "PRP0001")
        Name (_UID, 4)
        Name (_CCA, One)
        Name (_STA, 0x0F)

        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", "qcom,spi-geni" },
                Package () { "reg-names", "se_phys" },
                Package () { "spi-max-frequency", 50000000 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                Memory32Fixed (ReadWrite, 0x00A90000, 0x00004000)
                // DT GIC_SPI 357 => ACPI GSIV 389.
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, ) { 389 }
            })
        }

        Device (TCH0)
        {
            Name (_HID, "PRP0001")
            Name (_UID, 0)
            Name (_STA, 0x0F)

            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compatible", Package () { "synaptics,tcm-spi-hbp" } },
                    Package () { "chip-name", "S3910" },
                    Package () { "firmware-name", "AA545" },
                    Package () { "spi-max-frequency", 19000000 },
                    Package () { "touchpanel,panel-coords", Package () { 23040, 50688 } },
                    Package () { "touchpanel,display-coords", Package () { 1440, 3168 } },
                    Package () { "touchpanel,tx-rx-num", Package () { 17, 38 } },
                    Package () { "synaptics,power-on-state", 1 },
                    Package () { "synaptics,power-delay-ms", 200 },
                    Package () { "synaptics,irq-on-state", 0 },
                    Package () { "synaptics,reset-on-state", 0 },
                    Package () { "synaptics,reset-active-ms", 10 },
                    Package () { "synaptics,reset-delay-ms", 80 },
                    Package () { "synaptics,spi-mode", 0 },
                    Package () { "qcom,rt", 1 }
                }
            })

            Method (_CRS, 0, NotSerialized)
            {
                Return (ResourceTemplate () {
                    SPISerialBusV2 (0x0000, PolarityLow, FourWireMode, 0x08,
                        ControllerInitiated, 19000000, ClockPolarityLow,
                        ClockPhaseFirst, "\\_SB.SPI4", 0x00,
                        ResourceConsumer, , )

                    // Touch IRQ: TLMM GPIO162, DT flags 0x2008, active-low/edge style.
                    GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullNone, 0,
                        "\\_SB.GIO0", 0, ResourceConsumer, , ) { 162 }

                    // Reset GPIO: TLMM GPIO161, output, active-high in DT flags.
                    GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                        "\\_SB.GIO0", 0, ResourceConsumer, , ) { 161 }

                    // AVDD enable GPIO: pm8550vs_j_gpios GPIO3.
                    GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                        "\\_SB.PMJ0", 0, ResourceConsumer, , ) { 3 }
                })
            }
        }
    }
}
