# SM8750 / OnePlus 13 ACPI peripheral notes

These snippets are based on the official OnePlus 13 `dtbo.img` uploaded to the repository plus the matching OnePlusOSS SM8750 devicetree. The DTBO confirms the active branch/model as OPlus `dodge T0` (`Qualcomm Technologies, Inc. Sun MTP,dodge T0`), project `0x5d0d` / `23821`, with variant project IDs `0x5d55`, `0x5d56`, `0x5d57` (`23893/23894/23895`).

## Buttons

Sources:

- `qcom/pmk8550.dtsi`
  - `pon_hlos@1300`, `reg = <0x1300>, <0x800>`
  - `pwrkey`: `interrupts = <0x0 0x13 0x7 IRQ_TYPE_EDGE_BOTH>`, `linux,code = <KEY_POWER>`
  - `resin`: `interrupts = <0x0 0x13 0x6 IRQ_TYPE_EDGE_BOTH>`, `linux,code = <KEY_VOLUMEUP>`
- `qcom/sun-mtp.dtsi` included by `sun-mtp-v8.dtsi` / `sun-mtp-v8-overlay.dts` used by `dodge-23821-sun-overlay.dts`
  - `gpio_keys/vol_down`: `gpios = <&pm8550_gpios 6 GPIO_ACTIVE_LOW>`, `linux,code = <KEY_VOLUMEDOWN>`, wakeup, debounce `32 ms`
- `qcom/sun-pmic-overlay.dtsi`
  - `pm8550_gpios gpio6`: input, pull-up, `power-source = <1>`

ASL file: `sm8750-oneplus13-buttons.asl`.

The file uses symbolic controller paths (`\_SB.PON0`, `\_SB.PM85`). Replace these once PMK8550 PON and PM8550 GPIO controllers are represented in the platform DSDT.

## USB3 / DWC3

Source: `qcom/sun-usb.dtsi`.

- Wrapper: `usb0: ssusb@a600000`, compatible `qcom,dwc-usb3-msm`
  - `core_base`: `0x0A600000`, size `0x00100000`
  - `tcsr_dyn_en_dis`: `0x01FC6000`, size `0x4`
  - `pwr_event_irq`: `GIC_SPI 130` => ACPI GSIV `162`
  - PDC wake interrupts for DP/DM/SS PHY are present in DT but not emitted as plain GIC IRQs.
- DWC3 child: `dwc3@a600000`, compatible `snps,dwc3`
  - active register range inside wrapper: `0x0A600000`, size `0xD93C`
  - IRQ: `GIC_SPI 133` => ACPI GSIV `165`
  - `dr_mode = "otg"`
  - `maximum-speed = "super-speed-plus"`
  - DMA coherent
- HS PHY: `hsphy@88e3000`, compatible `qcom,usb-m31-eusb2-phy`
  - `0x088E3000` size `0x29C`
  - `0x088E2000` size `0x4`
  - `0x0C278000` size `0x4`
- SS/DP PHY: `ssphy@88e8000`, compatible `qcom,usb-ssphy-qmp-dp-combo`
  - `0x088E8000` size `0x3000`

ASL file: `sm8750-oneplus13-usb.asl`.

The ASL exposes a Windows-friendly `PNP0D10` xHCI device plus `_DSD` compatibility metadata. On real hardware, USB may still require UEFI/ABL to initialize clocks/resets/PHY/role-switch, or a Qualcomm-specific Windows ACPI driver.

## Touchscreen

Source: official `dtbo.img`, overlay model `Qualcomm Technologies, Inc. Sun MTP,dodge T0`.

- Active node: `synaptics_tcm_hbp@0`, status `okay`
- compatible `synaptics,tcm-spi-hbp`
- chip `S3910`, firmware `AA545`
- SPI bus: `&qupv3_se4_spi`, chip select `0`, max frequency `19000000`, SPI mode `0`
- IRQ GPIO: TLMM `gpio162`, DT flags `0x2008`
- reset GPIO: TLMM `gpio161`, DT flags `0x1`
- AVDD enable GPIO: `pm8550vs_j_gpios gpio3`
- VDD supply: `L4B`, name `vdd`
- HBP panel coords: `0x5a00 x 0xc600` = `23040 x 50688`
- display coords from the disabled non-HBP sibling: `0x5a0 x 0xc60` = `1440 x 3168`
- TX/RX: default `17 x 38`; nested `S3910_PANEL7` override `18 x 40`
- Project support list: `0x5d0d`, `0x5d55`, `0x5d56`, `0x5d57`

`qcom/sun-qupv3.dtsi` gives the SPI controller resources:

- `qupv3_se4_spi: spi@a90000`
- register: `0x00A90000`, size `0x4000`
- interrupt: `GIC_SPI 357` => ACPI GSIV `389`
- pins from OPlus file: MISO `gpio48`, MOSI `gpio49`, CLK `gpio50`, CS `gpio51`

ASL file: `sm8750-oneplus13-touchscreen.asl`.

The touchscreen ASL uses `PRP0001` / `_DSD` with Linux-compatible properties and ACPI SPI/GPIO resources. Windows will not use this without a Synaptics S3910 SPI-HBP driver (or a compatibility layer) that binds to this ACPI description.

## Thermal sensors

Source: official `dtbo.img` PMIC fragments.

- `pm8010m-temp-alarm@2400`: compatible `qcom,spmi-temp-alarm`, SPMI SID `0x0c`, IRQ tuple `<0x0c 0x24 0x00 0x03>`
- `pm8010n-temp-alarm@2400`: compatible `qcom,spmi-temp-alarm`, SPMI SID `0x0d`, IRQ tuple `<0x0d 0x24 0x00 0x03>`
- `pm8550-temp-alarm@a00`: compatible `qcom,spmi-temp-alarm`, SPMI SID `0x01`, IRQ tuple `<0x01 0x0a 0x00 0x03>`, ADC channel `0x103`
- `bcl@4700`: compatible `qcom,pm8550-bcl-v5`, register `0x4700` size `0x100`, interrupt names `bcl-lvl0`, `bcl-lvl1`, `bcl-lvl2`

ASL file: `sm8750-oneplus13-thermal.asl`.

This is a skeleton: real temperature readings require a Qualcomm SPMI/PMIC thermal driver or ACPI control methods wired to firmware/PMIC services.

## Battery / charger

Source: official `dtbo.img` OPlus charging stack.

- `oplus,mms_wired`, compatible `oplus,mms_wired`
  - ADC info name `855`, topic update interval `5000 ms`
  - supports USB temperature protection v2 and wireless OTG non-coexistence
- `oplus,virtual_buck`, compatible `oplus,virtual_buck`
  - main charger, current ratio `100`
  - discharge GPIO: PM8550 GPIO6
  - USB temperature ADC channels `0x74a`, `0x75e`, conversion ratio `10`
  - charging UART GPIOs: TLMM GPIO62/TX and GPIO63/RX
- `oplus,mms_gauge` + `oplus,virtual_gauge`
  - nominal capacity `5610 mAh`
  - `silicon_p_770` override capacity `5920 mAh`
- `oplus_chg_core`: framework v2, battery type by SMEM
- `oplus,chg_wls`: wireless charging node present

ASL file: `sm8750-oneplus13-battery.asl`.

`BAT0` exposes a compiling ACPI Control Method Battery placeholder. Runtime `_BST`/real `_BIX` values still need an implementation backed by Qualcomm/OPlus gauge data, likely via PMIC/ADSP services.

## Display backlight / magnetic cover controller

Source: official `dtbo.img` display and fragment@75.

- Display panel nodes expose:
  - `qcom,platform-bklight-en-gpio = <&tlmm 100 0>`
  - `qcom,platform-reset-gpio = <&tlmm 98 0>`
  - max brightness level `0xfff` = `4095`, min `1`
  - external backlight control type `bl_ctrl_external`
- Magnetic/Hall devices are on `qupv3_hub_i2c9`:
  - `i2c@9a4000`, size `0x4000`, `GIC_SPI 473` => ACPI GSIV `505`
  - `magnachip@10`: compatible `oplus,dhall-ak09970`, IRQ GPIO97 flags `0x2008`
  - `magneticcover@11`: compatible `oplus,magcvr_mxm1120`, DT reg currently `0x0f`, IRQ GPIO65 flags `0x2002`, supplies `L1B`/`L2B`

ASL file: `sm8750-oneplus13-display-cover.asl`.

This records both the backlight GPIO resources and the magnetic cover/Hall resources. Actual Windows brightness or cover-state behavior still needs a panel/backlight driver and an OPlus magnetic-cover/Hall driver or control methods.
