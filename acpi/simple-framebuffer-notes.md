# SM8750 simple-framebuffer ACPI snippet

`sm8750-simple-framebuffer.asl` defines `\_SB.FB00` as a generic DT-compatible ACPI device (`_HID = "PRP0001"`) with `_DSD` properties for `simple-framebuffer`.

## Values

| Field | Value | Source / calculation |
| --- | ---: | --- |
| Framebuffer base | `0xFC800000` | `sun-sde-display.dtsi`, `splash_memory: splash_region`, `reg = <0x0 0xfc800000 0x0 0x02b00000>` |
| Reserved splash size | `0x02B00000` | Same DTS node |
| Width | `1440` | Requested resolution; also present in OPlus panel DTS files |
| Height | `3168` | Requested resolution; also present in OPlus panel DTS files |
| Bytes per pixel | `4` | `a8r8g8b8` / 32bpp splash framebuffer assumption |
| Stride | `5760` (`0x1680`) | `1440 * 4`; already 64-byte aligned |
| Active framebuffer size | `0x01167000` | `5760 * 3168 = 18,247,680` bytes |
| Active end address | `0xFD966FFF` | `0xFC800000 + 0x01167000 - 1` |
| Reserved end address | `0xFF2FFFFF` | `0xFC800000 + 0x02B00000 - 1` |

## Source paths checked

- `vendor/qcom/opensource/display-devicetree/display/sun-sde-display.dtsi`
  - `splash_memory: splash_region { reg = <0x0 0xfc800000 0x0 0x02b00000>; label = "cont_splash_region"; }`
- `vendor/qcom/opensource/display-devicetree/oplus/panel/dsi-panel-*-dsc-cmd*.dtsi`
  - multiple OnePlus/OPlus panels declare `qcom,mdss-dsi-panel-width = <1440>` and `qcom,mdss-dsi-panel-height = <3168>`.

## Windows note

This is the ACPI/ASL representation of a Linux-style `simple-framebuffer` device via `PRP0001` + `_DSD`. If Windows 11 ARM is expected to use a built-in display path without an additional simplefb-compatible ACPI driver, UEFI GOP/ConOut handoff may still be required; this snippet provides the framebuffer resource/properties for a driver that consumes `simple-framebuffer`-style `_DSD`.
