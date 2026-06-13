/*
 * SM8750 / OnePlus 13 ACPI SSDT -- Synaptics S3910 touchscreen (SPI-HBP).
 *
 * Sources:
 *   dtbo.img overlay_04 (dodge T0, project 0x5d0d):
 *     synaptics_tcm_hbp@0, compatible "synaptics,tcm-spi-hbp"
 *     chip-name "S3910", firmware "AA545", spi-max-frequency 19 MHz
 *     IRQ GPIO162 (TLMM, edge-falling, 0x2008)
 *     reset GPIO161 (TLMM, active-low, 0x1)
 *     AVDD enable: pm8550vs_j_gpios GPIO3
 *     VDD supply: regulator L4B
 *   sun-qupv3.dtsi / real commercial OnePlus 13 bus path:
 *     /soc/qupv3_1_geni_se@ac0000/spi@a90000
 *     qupv3_se4_spi @ 0x00A90000, parent QUPv3 wrapper @ 0x00AC0000
 *     GIC SPI 357 -> GSIV 389
 *     pins: MISO=GPIO48, MOSI=GPIO49, CLK=GPIO50, CS=GPIO51
 *
 * Windows driver:
 *   _HID "SYNA3910" matched by drivers/touchscreen/SynapticsTouch_S3910.inf
 *   Bus: SPI (SPISerialBusV2 resource, SpbCx framework)
 *   Transport: drivers/touchscreen/spb_spi.c (TCM-over-SPI framing)
 *
 * GIC SPI N -> ACPI GSIV N+32.
 */

External (\_SB.GIO0, DeviceObj)   // TLMM GPIO controller
External (\_SB.PMJ0, DeviceObj)   // PM8550VS-J GPIO controller (AVDD GPIO3)

Scope (\_SB)
{
    /*
     * QUPv3 SE4 SPI controller.
     * Real DT path: /soc/qupv3_1_geni_se@ac0000/spi@a90000
     * Parent wrapper: qupv3_1_geni_se @ 0x00AC0000
     * Registers: 0x00A90000 / 0x4000  (sun-qupv3.dtsi)
     * IRQ: GIC SPI 357 -> GSIV 389
     */
    Device (SPI4)
    {
        Name (_HID, "QCOM0400")
        Name (_UID, 4)
        Name (_CCA, One)
        Name (_STA, 0x0F)

        Name (_CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite, 0x00A90000, 0x00004000)
            Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 389 }
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible",             "qcom,geni-spi" },
                Package () { "qcom,dt-path",           "/soc/qupv3_1_geni_se@ac0000/spi@a90000" },
                Package () { "qcom,dt-parent",         "/soc/qupv3_1_geni_se@ac0000" },
                Package () { "qcom,qupv3-parent-base", 0x00AC0000 },
                Package () { "spi-max-frequency",      50000000 },
            }
        })

        /*
         * Synaptics S3910 touchscreen.
         *
         * _HID "SYNA3910" matched by SynapticsTouch_S3910.inf.
         * _CID "PNP0C50" triggers HID class enumeration.
         *
         * _CRS resource order (device.c reads them in index order):
         *   [0] SPISerialBusV2   SPI connection  (CM_RESOURCE_CONNECTION_TYPE_SERIAL_SPI)
         *   [1] GpioInt          IRQ GPIO162     (confirmed physical TLMM pin)
         *   [2] GpioIo           Reset GPIO161   (confirmed physical TLMM pin)
         *   [3] GpioIo           AVDD-en PMJ0 GPIO3
         */
        Device (TCH0)
        {
            Name (_HID, "SYNA3910")
            Name (_CID, "PNP0C50")
            Name (_UID, Zero)
            Name (_STA, 0x0F)

            Name (_CRS, ResourceTemplate ()
            {
                SPISerialBusV2 (
                    0x0000,                 // CS 0
                    PolarityLow,
                    FourWireMode,
                    0x08,
                    ControllerInitiated,
                    19000000,               // 19 MHz
                    ClockPolarityLow,       // CPOL=0
                    ClockPhaseFirst,        // CPHA=0
                    "\\_SB.SPI4",
                    0x00,
                    ResourceConsumer,,
                )

                // IRQ: TLMM GPIO162, edge-falling, wake-capable
                GpioInt (Edge, ActiveLow, ExclusiveAndWake, PullUp, 0,
                         "\\_SB.GIO0", 0, ResourceConsumer,,) { 162 }

                // Reset: TLMM GPIO161, active-low
                GpioIo (Exclusive, PullNone, 0, 0, IoRestrictionOutputOnly,
                        "\\_SB.GIO0", 0, ResourceConsumer,,) { 161 }

                // AVDD enable: PM8550VS-J GPIO3
                GpioIo (Exclusive, PullDown, 0, 0, IoRestrictionOutputOnly,
                        "\\_SB.PMJ0", 0, ResourceConsumer,,) { 3 }
            })

            Name (_DSD, Package ()
            {
                ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
                Package ()
                {
                    Package () { "touchscreen-size-x",         1440 },
                    Package () { "touchscreen-size-y",         3168 },
                    Package () { "touchscreen-max-pressure",   255 },
                    Package () { "synaptics,chip-name",        "S3910" },
                    Package () { "synaptics,firmware-name",    "AA545" },
                    Package () { "synaptics,tx-count",         17 },
                    Package () { "synaptics,rx-count",         38 },
                    Package () { "synaptics,reset-delay-ms",   80 },
                    Package () { "synaptics,power-on-delay-ms", 200 },
                    Package () { "synaptics,spi-mode",         0 },
                    Package () { "synaptics,spi-max-frequency", 19000000 },
                    Package () { "synaptics,irq-gpio",         162 },
                    Package () { "synaptics,reset-gpio",       161 },
                    Package () { "qcom,dt-parent-bus",         "/soc/qupv3_1_geni_se@ac0000/spi@a90000" },
                }
            })

            // _DSM: HID descriptor address (required for PNP0C50)
            Method (_DSM, 4, NotSerialized)
            {
                If (LEqual (Arg0,
                    ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de")))
                {
                    If (LEqual (Arg2, Zero)) { Return (Buffer () { 0x03 }) }
                    If (LEqual (Arg2, One))  { Return (One) }
                }
                Return (Buffer () { 0x00 })
            }
        }
    }
}
