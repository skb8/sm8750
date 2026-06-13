/*
 * SM8750 / OnePlus 13 ACPI SSDT snippet — MDSS Display Sub-System.
 *
 * Covers: MDSS MDP (core), DSI0, DSI1, DSI PHY0/PHY1, DP display.
 *
 * All register addresses and IRQs are cross-checked against:
 *   vendor/qcom/opensource/display-devicetree/display/sun-sde-common.dtsi
 *   vendor/qcom/opensource/display-devicetree/display/sun-sde.dtsi
 *   OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8750
 *   dtbo.img overlay_04 (dodge T0 / OnePlus 13 CPH2657)
 *
 * GIC SPI N  ->  ACPI GSIV N+32.
 *
 * Status:
 *   MDP0/DSI0/DSI1/DPD0 are documented hardware resources.
 *   A Qualcomm MDSS Windows driver does not yet exist for SM8750;
 *   until one binds, FB00 (sm8750-simple-framebuffer.asl) remains the
 *   active display path via the ABL splash framebuffer at 0xFC800000.
 *
 * GPIO numbers (reset, backlight-en) come from DTBO dodge T0 overlay:
 *   panel-reset-gpio    = TLMM 98  (active-low, post-reset delay 10 ms)
 *   bklight-enable-gpio = TLMM 100 (active-high, external backlight IC)
 */

/*
 * MDSS MDP — Snapdragon Display Sub-System core processor.
 *
 * Register regions (sun-sde-common.dtsi):
 *   mdp_phys    0x0AE00000  0x93800   — MDP core
 *   vbif_phys   0x0AEB0000  0x02008   — VBIF (memory bus interface)
 *   regdma_phys 0x0AF80000  0x07000   — Register DMA
 *   ipcc_reg    0x00400000  0x02000   — IPC (inter-processor communications)
 *   swfuse_phys 0x0AF50000  0x00128   — Software fuse readback
 *
 * IRQ: GIC SPI 83 -> GSIV 115 (level-high)
 */
Device (MDP0)
{
    Name (_HID, "QCOM0300")
    Name (_UID, Zero)
    Name (_CCA, One)

    Name (_CRS, ResourceTemplate ()
    {
        Memory32Fixed (ReadWrite, 0x0AE00000, 0x00093800)
        Memory32Fixed (ReadWrite, 0x0AEB0000, 0x00002008)
        Memory32Fixed (ReadWrite, 0x0AF80000, 0x00007000)
        Memory32Fixed (ReadWrite, 0x00400000, 0x00002000)
        Memory32Fixed (ReadWrite, 0x0AF50000, 0x00000128)

        // MDP core IRQ: GIC SPI 83 -> GSIV 115
        Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 115 }
    })

    Name (_DSD, Package ()
    {
        ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package ()
        {
            Package () { "compatible",              "qcom,sm8750-mdss,qcom,sde-kms" },
            Package () { "qcom,sde-off",            0x00AE00000 },
            Package () { "qcom,sde-len",            0x000093800 },
            Package () { "qcom,splash-memory-base", 0x0FC800000 },
            Package () { "qcom,splash-memory-size", 0x002B00000 },
        }
    })

    Device (DSI0)
    {
        Name (_HID, "QCOM0301")
        Name (_UID, Zero)
        Name (_CCA, One)

        /*
         * DSI0 register map (sun-sde-common.dtsi):
         *   dsi_ctrl   0xAE94000  0x1000
         *   DSI0 PHY   0xAE95000  0xA00
         *
         * Interrupt: MDP sub-IRQ 4 (routed through MDP0 domain).
         *
         * Panel reset GPIO:    TLMM 98  (active-low, DTBO dodge T0)
         * Backlight-en GPIO:   TLMM 100 (active-high, DTBO dodge T0)
         * Panel candidates:    AA545_P_3_A0005, BF262_P_3_A0021, AA569_P_3_A0019
         *                      (all BOE/CSOT AMOLED, WQHD+ 1440x3168, DSC 10bpc)
         */
        Name (_CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite, 0x0AE94000, 0x00001000)
            Memory32Fixed (ReadWrite, 0x0AE95000, 0x00000A00)

            GpioIo (Exclusive, PullUp, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer) { 98 }

            GpioIo (Exclusive, PullDown, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer) { 100 }
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package () { "compatible",            "qcom,sm8750-dsi-ctrl" },
                Package () { "qcom,master-dsi",       One },
                Package () { "panel-candidates",
                             "AA545_P_3_A0005_dsc_cmd,BF262_P_3_A0021_dsc_cmd,AA569_P_3_A0019_dsc_cmd" },
                Package () { "panel-width-mm",        71 },
                Package () { "panel-height-mm",       157 },
                Package () { "dsc-enable",            One },
                Package () { "dsc-bpc",               10 },
                Package () { "panel-reset-delay-ms",  10 },
                Package () { "panel-backlight-max",   4095 },
            }
        })
    }

    Device (DSI1)
    {
        Name (_HID, "QCOM0301")
        Name (_UID, One)
        Name (_CCA, One)

        Name (_CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite, 0x0AE96000, 0x00001000)
            Memory32Fixed (ReadWrite, 0x0AE97000, 0x00000A00)
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package () { "compatible",      "qcom,sm8750-dsi-ctrl" },
                Package () { "qcom,master-dsi", Zero },
            }
        })
    }

    Device (DPD0)
    {
        Name (_HID, "QCOM0302")
        Name (_UID, Zero)
        Name (_CCA, One)

        /*
         * DP register map (sun-sde.dtsi):
         *   dp_ahb        0xAF54000  0x104
         *   dp_aux        0xAF54200  0x0C0
         *   dp_link       0xAF55000  0x770
         *   dp_p0         0xAF56000  0x09C
         *   dp_phy        0x88EBC00  0x200   USB3/QMP DP combo PHY sub-range
         *   dp_ln_tx0     0x88EB400  0x200
         *   dp_ln_tx1     0x88EB800  0x200
         *   dp_pll        0x88EB000  0x200
         *   usb3_dp_com   0x88E8000  0x020
         *   hdcp_physical 0xAEE1000  0x034
         *   dp_p1         0xAF57000  0x09C
         *
         * Interrupt: MDP sub-IRQ 12.
         * NOTE: requires USB3/QMP PHY init + USB-C Alt-Mode negotiation.
         */
        Name (_CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite, 0x0AF54000, 0x00000104)
            Memory32Fixed (ReadWrite, 0x0AF54200, 0x000000C0)
            Memory32Fixed (ReadWrite, 0x0AF55000, 0x00000770)
            Memory32Fixed (ReadWrite, 0x0AF56000, 0x0000009C)
            Memory32Fixed (ReadWrite, 0x088EBC00, 0x00000200)
            Memory32Fixed (ReadWrite, 0x088EB400, 0x00000200)
            Memory32Fixed (ReadWrite, 0x088EB800, 0x00000200)
            Memory32Fixed (ReadWrite, 0x088EB000, 0x00000200)
            Memory32Fixed (ReadWrite, 0x088E8000, 0x00000020)
            Memory32Fixed (ReadWrite, 0x0AEE1000, 0x00000034)
            Memory32Fixed (ReadWrite, 0x0AF57000, 0x0000009C)
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package () { "compatible",            "qcom,sm8750-dp-display" },
                Package () { "dp-max-link-rate-mbps",  10000 },
                Package () { "dp-max-lanes",           4 },
            }
        })
    }
}
