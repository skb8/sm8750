/*
 * SM8750 / Snapdragon 8 Elite simple-framebuffer ACPI snippet.
 * Source DTS:
 *   vendor/qcom/opensource/display-devicetree/display/sun-sde-display.dtsi
 *     &reserved_memory/splash_memory: reg = <0x0 0xfc800000 0x0 0x02b00000>
 *   vendor/qcom/opensource/display-devicetree/oplus/panel directory
 *     OnePlus/OPlus panels: 1440x3168
 *
 * Framebuffer layout used here:
 *   base   = 0x00000000FC800000
 *   width  = 1440
 *   height = 3168
 *   format = a8r8g8b8 (32 bpp, little-endian BGRA byte order)
 *   stride = 1440 * 4 = 5760 = 0x1680
 *   size   = stride * height = 0x01167000 bytes
 *
 * The DTS splash reserved-memory window is 0x02B00000 bytes, so the
 * 0x01167000-byte 1440x3168x32bpp framebuffer fits inside it.
 */
Scope (\_SB)
{
    Device (FB00)
    {
        Name (_HID, "PRP0001")  // Generic DT-compatible ACPI device
        Name (_UID, Zero)
        Name (_STA, 0x0F)       // Present, enabled, shown, functioning

        Name (FBAS, 0x00000000FC800000)  // cont_splash_region base
        Name (FBRS, 0x0000000002B00000)  // full DTS splash reserved size
        Name (FBW,  1440)
        Name (FBH,  3168)
        Name (FBS,  5760)                // stride: 1440 * 4 bytes
        Name (FBSZ, 0x01167000)          // visible framebuffer byte size

        Name (_CRS, ResourceTemplate ()
        {
            // Expose only the active framebuffer bytes. The backing
            // reserved-memory window from DTS is 0x02B00000 at the same base.
            Memory32Fixed (ReadWrite,
                0xFC800000,         // BaseAddress
                0x01167000          // RangeLength = 1440 * 3168 * 4
            )
        })

        Name (_DSD, Package ()
        {
            ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
            Package ()
            {
                Package (2) { "compatible", "simple-framebuffer" },
                Package (2) { "reg",      Package () { 0x00000000FC800000, 0x01167000 } },
                Package (2) { "width",    1440 },
                Package (2) { "height",   3168 },
                Package (2) { "stride",   5760 },
                Package (2) { "format",   "a8r8g8b8" },

                // Extra explicit metadata for bring-up/debug consumers.
                Package (2) { "framebuffer-base", 0x00000000FC800000 },
                Package (2) { "framebuffer-size", 0x01167000 },
                Package (2) { "reserved-size",    0x02B00000 }
            }
        })
    }
}
