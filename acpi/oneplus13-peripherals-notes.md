# SM8750 / OnePlus 13 ACPI peripheral notes

These snippets are based on the OPlus `dodge` Snapdragon 8 Elite devicetree branch, project `23821`, which is the OnePlus 13 branch in the supplied tree.

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

Sources:

- `oplus/tp/dodge-oplus-tp-23821.dtsi`
  - SPI bus: `&qupv3_se4_spi`, status `ok`
  - Active node: `synaptics_tcm_hbp@0`, status `okay`
  - compatible `synaptics,tcm-spi-hbp`
  - chip `S3910`, firmware `AA545`
  - SPI chip select `0`, max frequency `19000000`
  - IRQ GPIO: TLMM `gpio162`, DT flags `0x2008`
  - reset GPIO: TLMM `gpio161`, DT flags `0x1`
  - AVDD enable GPIO: `pm8550vs_j_gpios gpio3`
  - VDD supply: `L4B`, name `vdd`
  - panel coords: `23040 x 50688`
  - display coords: `1440 x 3168`
  - TX/RX: `17 x 38`
- `qcom/sun-qupv3.dtsi`
  - `qupv3_se4_spi: spi@a90000`
  - register: `0x00A90000`, size `0x4000`
  - interrupt: `GIC_SPI 357` => ACPI GSIV `389`
  - pins from OPlus file:
    - MISO TLMM `gpio48`, function `qup1_se4_l0`
    - MOSI TLMM `gpio49`, function `qup1_se4_l1`
    - CLK TLMM `gpio50`, function `qup1_se4_l2`
    - CS TLMM `gpio51`, function `qup1_se4_l3`

ASL file: `sm8750-oneplus13-touchscreen.asl`.

The touchscreen ASL uses `PRP0001` / `_DSD` with Linux-compatible properties and ACPI SPI/GPIO resources. Windows will not use this without a Synaptics S3910 SPI-HBP driver (or a compatibility layer) that binds to this ACPI description.
