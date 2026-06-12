/*
 * SM8750 / OnePlus 13 (OPlus dodge T0) Synaptics S3910 touchscreen ASL skeleton.
 *
 * Values below were verified against the user-provided official dtbo.img overlays:
 *   model = "Qualcomm Technologies, Inc. Sun MTP,dodge T0"
 *   oplus,project-id = 0x5d0d / 23821 and variants 0x5d55..0x5d57
 *   synaptics_tcm_hbp@0 status = "okay"
 *
 * DTBO touchscreen facts:
 *   compatible = "synaptics,tcm-spi-hbp"
 *   chip-name = "S3910", firmware_name = "AA545"
 *   spi-max-frequency = 19 MHz, spi-mode = 0, reg/chip-select = 0
 *   IRQ = TLMM GPIO162, flags 0x2008
 *   reset = TLMM GPIO161, flags 0x1
 *   AVDD enable = pm8550vs_j GPIO3, VDD supply name = "vdd"
 *   HBP panel-coords = <0x5a00 0xc600> = 23040 x 50688
 *   display-coords from non-HBP sibling = 1440 x 3168
 *   tx-rx default = 17 x 38; S3910_PANEL7 override = 18 x 40
 *
 * IMPORTANT:
 *   \_SB.GIO0 and \_SB.PMJ0 are symbolic placeholders for TLMM and PM8550VS-J
 *   GPIO controllers. Rename them to the real ACPI GPIO controller paths used in
 *   your platform namespace. Windows also needs a Synaptics S3910/SPI-HBP ACPI
 *   driver; this SSDT only describes resources and DT-compatible properties.
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
                // qupv3_se4_spi DT GIC_SPI 357 => ACPI GSIV 389.
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
                    Package () { "reg", 0 },
                    Package () { "spi-max-frequency", 19000000 },
                    Package () { "synaptics,vdd-name", "vdd" },
                    Package () { "touchpanel,panel-coords", Package () { 23040, 50688 } },
                    Package () { "touchpanel,display-coords", Package () { 1440, 3168 } },
                    Package () { "touchpanel,tx-rx-num", Package () { 17, 38 } },
                    Package () { "synaptics,s3910-panel7-tx-rx-num", Package () { 18, 40 } },
                    Package () { "panel_type", Package () { 10, 3, 3, 3 } },
                    Package () { "platform_support_project", Package () { 0x5D0D, 0x5D55, 0x5D56, 0x5D57 } },
                    Package () { "synaptics,power-on-state", 1 },
                    Package () { "synaptics,power-delay-ms", 200 },
                    Package () { "synaptics,irq-on-state", 0 },
                    Package () { "synaptics,reset-on-state", 0 },
                    Package () { "synaptics,reset-active-ms", 10 },
                    Package () { "synaptics,reset-delay-ms", 80 },
                    Package () { "synaptics,spi-mode", 0 },
                    Package () { "synaptics,spi-byte-delay-us", 0 },
                    Package () { "synaptics,spi-block-delay-us", 0 },
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

                    // Touch IRQ: TLMM GPIO162, DT flags 0x2008.
                    GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0,
                        "\\_SB.GIO0", 0, ResourceConsumer, , ) { 162 }

                    // Reset GPIO: TLMM GPIO161.
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
