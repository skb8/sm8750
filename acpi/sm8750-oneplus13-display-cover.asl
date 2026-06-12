/*
 * SM8750 / OnePlus 13 display backlight + magnetic cover/Hall controller ACPI skeleton.
 *
 * The user request said "контроллер подставки экрана"; DTBO contains both the
 * display/backlight GPIO resources and a magnetic cover/Hall controller on the
 * QUPv3 hub I2C9 bus. This SSDT records both pieces so either interpretation is
 * available during bring-up.
 *
 * DTBO facts:
 *   display panels: qcom,platform-bklight-en-gpio = TLMM GPIO100,
 *                   qcom,platform-reset-gpio = TLMM GPIO98,
 *                   bl max = 4095, min = 1, external backlight control
 *   qupv3_hub_i2c9: i2c@9a4000, GIC_SPI 473 => ACPI GSIV 505
 *   magnachip@10: compatible "oplus,dhall-ak09970", IRQ GPIO97 flags 0x2008
 *   magneticcover@11: compatible "oplus,magcvr_mxm1120", DT reg currently 0x0f,
 *                     IRQ GPIO65 flags 0x2002, supplies L1B/L2B
 */

External (\_SB.GIO0, DeviceObj)  // TLMM GPIO controller placeholder

Scope (\_SB)
{
    Device (BL00)
    {
        Name (_HID, "PRP0001")
        Name (_UID, 0)
        Name (_STA, 0x0F)
        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", Package () { "qcom,mdss-dsi-bl", "pwm-backlight" } },
                Package () { "qcom,mdss-dsi-bl-pmic-control-type", "bl_ctrl_external" },
                Package () { "qcom,mdss-dsi-bl-max-level", 4095 },
                Package () { "qcom,mdss-dsi-bl-min-level", 1 },
                Package () { "qcom,platform-bklight-en-gpio", 100 },
                Package () { "qcom,platform-reset-gpio", 98 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer, , ) { 100 }
                GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer, , ) { 98 }
            })
        }
    }

    Device (I2C9)
    {
        Name (_HID, "PRP0001")
        Name (_UID, 9)
        Name (_CCA, One)
        Name (_STA, 0x0F)
        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", "qcom,i2c-geni" },
                Package () { "qcom,i2c-hub", 1 },
                Package () { "clock-frequency", 400000 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                Memory32Fixed (ReadWrite, 0x009A4000, 0x00004000)
                // qupv3_hub_i2c9 DT GIC_SPI 473 => ACPI GSIV 505.
                Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, ) { 505 }
            })
        }

        Device (HAL0)
        {
            Name (_HID, "PRP0001")
            Name (_UID, 0)
            Name (_STA, 0x0F)
            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compatible", "oplus,dhall-ak09970" },
                    Package () { "reg", 0x10 },
                    Package () { "magnachip,init-interval", 200 },
                    Package () { "threeaxis_hall_support", 1 },
                    Package () { "new_posupdate_support", 1 }
                }
            })

            Method (_CRS, 0, NotSerialized)
            {
                Return (ResourceTemplate () {
                    I2CSerialBusV2 (0x10, ControllerInitiated, 400000,
                        AddressingMode7Bit, "\\_SB.I2C9", 0x00,
                        ResourceConsumer, , )
                    GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0,
                        "\\_SB.GIO0", 0, ResourceConsumer, , ) { 97 }
                })
            }
        }

        Device (MCVR)
        {
            Name (_HID, "PRP0001")
            Name (_UID, 0)
            Name (_STA, 0x0F)
            Name (_DSD, Package () {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package () {
                    Package () { "compatible", "oplus,magcvr_mxm1120" },
                    Package () { "reg", 0x0F },
                    Package () { "magcvr_detect_step", 50 },
                    Package () { "magcvr_farmax_th", 50 },
                    Package () { "magcvr_far_threshold", 150 },
                    Package () { "magcvr_far_noise_threshold", 125 }
                }
            })

            Method (_CRS, 0, NotSerialized)
            {
                Return (ResourceTemplate () {
                    I2CSerialBusV2 (0x0F, ControllerInitiated, 400000,
                        AddressingMode7Bit, "\\_SB.I2C9", 0x00,
                        ResourceConsumer, , )
                    GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0,
                        "\\_SB.GIO0", 0, ResourceConsumer, , ) { 65 }
                })
            }
        }
    }
}
