/*
 * SM8750 / OnePlus 13 ACPI SSDT -- USB 3.2 (DWC3 + eUSB2 + QMP DP/USB PHY).
 *
 * Sources:
 *   kernel_platform/qcom/opensource/devicetree/qcom/sun-usb.dtsi
 *   dtbo.img overlay_04 (dodge T0, eusb2-repeater@fd00 on pmih010x)
 *
 * Topology:
 *   USB0 (PNP0D10 xHCI)
 *     DWC3 core:      0x0A600000 / 0x100000
 *     TCSR:           0x01FC6000 / 0x4
 *     eUSB2 HS PHY:   0x088E3000 / 0x29C   (hsphy@88e3000)
 *     eUSB2 ref clk:  0x088E2000 / 0x4
 *     USB3+DP QMP PHY: 0x088E8000 / 0x3000 (ssphy@88e8000, shared w/ DP)
 *
 * IRQs (GIC SPI N -> GSIV N+32):
 *   SPI 133 -> GSIV 165  DWC3/xHCI
 *   SPI 130 -> GSIV 162  Qualcomm wrapper pwr_event_irq
 *
 * Notes:
 *   1. ABL leaves PHYs initialised after fastboot; Windows inherits that
 *      state. PHY regions are listed here for resume re-init by a future
 *      Qualcomm USB ACPI driver.
 *   2. OTG/role-switch needs the _DSM below (UUID per USB Type-C ACPI spec);
 *      without it Windows defaults to host-only.
 *   3. USB3/QMP combo PHY 0x088E8000 is shared with DP display.
 */

Scope (\_SB)
{
    Device (USB0)
    {
        Name (_HID, "PNP0D10")      // Standard xHCI
        Name (_UID, Zero)
        Name (_CCA, One)
        Name (_STA, 0x0F)

        Name (_CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite, 0x0A600000, 0x00100000)  // DWC3 core
            Memory32Fixed (ReadWrite, 0x01FC6000, 0x00000004)  // TCSR
            Memory32Fixed (ReadWrite, 0x088E3000, 0x0000029C)  // eUSB2 HS PHY
            Memory32Fixed (ReadWrite, 0x088E2000, 0x00000004)  // eUSB2 ref clk
            Memory32Fixed (ReadWrite, 0x088E8000, 0x00003000)  // USB3+DP QMP PHY

            // DWC3 IRQ: GIC SPI 133 -> GSIV 165
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 165 }
            // Wrapper pwr_event IRQ: GIC SPI 130 -> GSIV 162
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 162 }
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package () { "compatible",
                             "snps,dwc3,qcom,dwc-usb3-msm" },
                Package () { "dr_mode",            "otg" },
                Package () { "maximum-speed",      "super-speed-plus" },
                Package () { "snps,dis-u1-entry-quirk",  1 },
                Package () { "snps,dis-u2-entry-quirk",  1 },
                Package () { "snps,dis_u2_susphy_quirk", 1 },
                Package () { "snps,ssp-u3-u0-quirk",     1 },
                Package () { "snps,has-lpm-erratum",     1 },
                Package () { "tx-fifo-resize",           1 },
                Package () { "num-hc-interrupters",      3 },
                Package () { "qcom,eusb2-phy",           1 },
            }
        })

        /*
         * USB Type-C Port  (ACPI0040)
         * Required for Windows to enable OTG/role-switch.
         * _PLD: bottom of device (rear-facing, Group 0).
         */
        Device (CON0)
        {
            Name (_HID, "ACPI0040")
            Name (_UID, Zero)
            Name (_STA, 0x0F)

            Name (_PLD, Package ()
            {
                Buffer ()
                {
                    0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x79, 0x0C, 0x80, 0x02, 0x00, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00
                }
            })

            /*
             * _DSM: USB Type-C role-switch (ACPI 6.4 ss6.1.9)
             * UUID: 6f8398c2-7ca4-11e4-ad36-631042b5008f
             *   Method 0: capabilities bitmap (0x07 = methods 0,1,2)
             *   Method 1: supported roles (0x3 = DRP)
             *   Method 2: current advertising mode (0x1 = default USB)
             */
            Method (_DSM, 4, NotSerialized)
            {
                If (LEqual (Arg0,
                    ToUUID ("6f8398c2-7ca4-11e4-ad36-631042b5008f")))
                {
                    If (LEqual (Arg2, Zero)) { Return (Buffer () { 0x07 }) }
                    If (LEqual (Arg2, One))  { Return (0x3) }
                    If (LEqual (Arg2, 0x2))  { Return (0x1) }
                }
                Return (Buffer () { 0x00 })
            }
        }
    }
}
