/*
 * SM8750 / OnePlus 13 ACPI SSDT snippet — WCN7850 Wi-Fi 6E + BT 5.3.
 *
 * WCN7850 is the Qualcomm combo Wi-Fi/BT chip used in SM8750 devices,
 * including official Snapdragon X Elite Windows ARM laptops (same chip).
 * Windows Update distributes WCN7850 drivers for Snapdragon X Elite
 * devices; those drivers should bind here once this ACPI description
 * is in place and the PCIe link trains successfully.
 *
 * Connection topology:
 *   Wi-Fi: PCIe Root Complex 0 (pcie0 @ 0x1C00000)  ->  WCN7850 PCIe EP
 *   BT:    UART (qupv3_se*)  ->  WCN7850 BT UART (separate binding)
 *
 * PCIe0 register map (kernel_platform/qcom/.../sun-pcie.dtsi):
 *   parf        0x01C00000  0x3000   PCIe Application Register File
 *   phy         0x01C06000  0x2000   PCIe PHY
 *   dm_core     0x40000000  0xF1D    DWC core registers
 *   elbi        0x40000F20  0xA8     External Local Bus Interface
 *   iatu        0x40001000  0x1000   iATU
 *   conf        0x40100000  0x100000 PCIe ECAM config space
 *
 * PCIe address ranges:
 *   IO    0x40200000  0x100000
 *   MEM32 0x40300000  0x3D00000    WCN7850 BARs land here at runtime
 *
 * IRQs (GIC SPI -> GSIV = SPI+32):
 *   global_int  SPI 140 -> 172
 *   int_a       SPI 149 -> 181
 *   int_b       SPI 150 -> 182
 *   int_c       SPI 151 -> 183
 *   int_d       SPI 152 -> 184
 *
 * GPIOs (sun-pcie.dtsi):
 *   perst   TLMM 102  PCIe PERST# (active-low reset to WCN7850)
 *   wake    TLMM 104  PCIe WAKE# (device wakeup, input)
 *
 * OPlus commercial OnePlus 13 / dodge T0 overlay confirmation:
 *   wlan-en  TLMM 16 (0x10)  WCN7850 enable GPIO.
 *
 * Windows driver hardware IDs (from Qualcomm Windows Update packages):
 *   PCI\VEN_17CB&DEV_1107  WCN7850 Wi-Fi
 *   PCI\VEN_17CB&DEV_1103  WCN7850 BT (separate PCIe function)
 */

Device (PCI0)
{
    Name (_HID, "ACPI0016")         // PCI Express Root Complex
    Name (_UID, Zero)
    Name (_CCA, One)
    Name (_SEG, Zero)               // PCIe domain 0
    Name (_BBN, Zero)               // Bus 0

    Method (_CRS, 0, NotSerialized)
    {
        Return (ResourceTemplate ()
        {
            // parf (PCIe Application Register File)
            Memory32Fixed (ReadWrite, 0x01C00000, 0x00003000)
            // PCIe PHY
            Memory32Fixed (ReadWrite, 0x01C06000, 0x00002000)
            // DWC core (dm_core + elbi + iatu)
            Memory32Fixed (ReadWrite, 0x40000000, 0x00002000)
            // PCIe ECAM config space (buses 0-3, 1MB)
            Memory32Fixed (ReadWrite, 0x40100000, 0x00100000)

            // PCIe IO window. Use DWordIO because the translated MMIO
            // aperture is above the 16-bit range accepted by WordIO.
            DWordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                     0x00000000, 0x40200000, 0x402FFFFF, 0x00000000,
                     0x00100000)

            // PCIe MEM32 window (WCN7850 BARs land here)
            DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed,
                         NonCacheable, ReadWrite,
                         0x00000000, 0x40300000, 0x43FFFFFF, 0x00000000,
                         0x03D00000)

            // Global interrupt: GIC SPI 140 -> GSIV 172
            Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive) { 172 }
            // MSI/INTx: GIC SPI 149-152 -> GSIV 181-184
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 181 }
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 182 }
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 183 }
            Interrupt (ResourceConsumer, Level, ActiveHigh, Shared) { 184 }

            // PERST# GPIO: TLMM 102 (active-low, de-assert to bring up WCN7850)
            GpioIo (Exclusive, PullUp, 0, 0, IoRestrictionOutputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer) { 102 }

            // WAKE# GPIO: TLMM 104 (input, device wakeup)
            GpioIo (Shared, PullUp, 0, 0, IoRestrictionInputOnly,
                    "\\_SB.GIO0", 0, ResourceConsumer) { 104 }
        })
    }

    Name (_DSD, Package ()
    {
        ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package ()
        {
            Package () { "compatible",         "qcom,pcie-sm8750,qcom,pci-msm" },
            Package () { "qcom,pcie-phy-ver",  94 },
            Package () { "linux,pci-domain",   0 },
            // wlan-en GPIO: confirmed for commercial OnePlus 13 / dodge T0.
            Package () { "wlan-en-gpio",       0x10 },
        }
    })

    // INTx routing: all lines from slot 0 to GSIV 181-184
    Name (_PRT, Package ()
    {
        Package () { 0x0000FFFF, 0, Zero, 181 },
        Package () { 0x0000FFFF, 1, Zero, 182 },
        Package () { 0x0000FFFF, 2, Zero, 183 },
        Package () { 0x0000FFFF, 3, Zero, 184 },
    })
}
