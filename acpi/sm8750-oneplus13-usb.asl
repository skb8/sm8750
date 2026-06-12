/*
 * SM8750 / OnePlus 13 USB3 ACPI ASL skeleton.
 *
 * Source devicetree: qcom/sun-usb.dtsi
 *   usb0: ssusb@a600000 compatible = "qcom,dwc-usb3-msm"
 *     reg = <0x0a600000 0x00100000>, <0x01fc6000 0x4>
 *     interrupts: GIC_SPI 130 pwr_event_irq => ACPI GSIV 162
 *   dwc3_0: dwc3@a600000 compatible = "snps,dwc3"
 *     reg = <0x0 0x0a600000 0x0 0x0000d93c>
 *     interrupts = <GIC_SPI 133 IRQ_TYPE_LEVEL_HIGH> => ACPI GSIV 165
 *     dr_mode = "otg"; maximum-speed = "super-speed-plus"
 *   hsphy@88e3000 and ssphy@88e8000 resources are listed in notes.
 *
 * Windows note:
 *   PNP0D10 describes a standard xHCI controller, but this Qualcomm DWC3 block
 *   usually still needs firmware/UEFI to leave clocks, resets, role-switch and
 *   PHYs initialized, or a Qualcomm-specific ACPI driver for full OTG/Type-C.
 */

Scope (\_SB)
{
    Device (USB0)
    {
        Name (_HID, "PNP0D10")  // xHCI USB controller
        Name (_UID, 0)
        Name (_CCA, One)        // DMA coherent per DT child node
        Name (_STA, 0x0F)

        Name (_DSD, Package () {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package () {
                Package () { "compatible", Package () { "snps,dwc3", "qcom,dwc-usb3-msm" } },
                Package () { "reg-names", Package () { "core_base", "tcsr_dyn_en_dis" } },
                Package () { "interrupt-names", Package () { "xhci", "pwr_event_irq" } },
                Package () { "dr_mode", "otg" },
                Package () { "maximum-speed", "super-speed-plus" },
                Package () { "snps,disable-clk-gating", 1 },
                Package () { "snps,has-lpm-erratum", 1 },
                Package () { "snps,hird-threshold", 0 },
                Package () { "snps,is-utmi-l1-suspend", 1 },
                Package () { "snps,dis-u1-entry-quirk", 1 },
                Package () { "snps,dis-u2-entry-quirk", 1 },
                Package () { "snps,dis_u2_susphy_quirk", 1 },
                Package () { "snps,ssp-u3-u0-quirk", 1 },
                Package () { "tx-fifo-resize", 1 },
                Package () { "num-hc-interrupters", 3 }
            }
        })

        Method (_CRS, 0, NotSerialized)
        {
            Return (ResourceTemplate () {
                // Wrapper/core window from ssusb@a600000.
                Memory32Fixed (ReadWrite, 0x0A600000, 0x00100000)

                // TCSR dyn_en_dis register from second reg tuple.
                Memory32Fixed (ReadWrite, 0x01FC6000, 0x00000004)

                // Main DWC3/xHCI event IRQ and Qualcomm wrapper power-event IRQ.
                // GIC_SPI n maps to ACPI GSIV n + 32 on this platform.
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, ) { 165 }
                Interrupt (ResourceConsumer, Level, ActiveHigh, Shared, ,, ) { 162 }
            })
        }
    }
}
