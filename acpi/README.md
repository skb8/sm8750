# SM8750 ACPI MADT/GTDT

Initial ACPI table sources for Windows on ARM bring-up on SM8750 / Snapdragon 8 Elite (Oryon, 8 cores), translated from the OnePlusOSS device-tree `qcom/sun.dtsi`.

## Files

- `sm8750-madt.asl` — MADT/APIC data-table ASL/DSL source with GICC entries for 8 CPUs plus GICD/GICR.
- `sm8750-gtdt.asl` — GTDT data-table ASL/DSL source with ARM arch timer GSIVs.
- `sm8750-madt.dat`, `sm8750-gtdt.dat` — binary tables generated from the same values, with checksums filled.
- `sm8750-simple-framebuffer.asl` — `Device (FB00)` snippet for a 1440x3168 simple-framebuffer using the DTS continuous splash memory.
- `simple-framebuffer-notes.md` — framebuffer address, stride and source notes.
- `sm8750-oneplus13-buttons.asl` — OnePlus 13 / OPlus dodge button ASL skeleton for power, volume-up and volume-down.
- `sm8750-oneplus13-usb.asl` — USB3 / DWC3 xHCI ASL skeleton from `sun-usb.dtsi`.
- `sm8750-oneplus13-touchscreen.asl` — Synaptics S3910 touchscreen over QUPv3 SE4 SPI ASL skeleton.
- `oneplus13-peripherals-notes.md` — extracted DTS resources and caveats for buttons, USB and touchscreen.

## Extracted values

| Item | Device-tree value | ACPI value |
| --- | ---: | ---: |
| GICD base | `0x16000000`, size `0x10000` | MADT GIC Distributor base `0x0000000016000000` |
| GICC base | not present for GICv3 sysreg CPU interface | MADT GICC physical base `0x0000000000000000` |
| GICR range | `0x16080000`, size `0x200000`, stride `0x40000` | MADT GICR range `0x0000000016080000` / `0x00200000`; per-CPU GICR bases are `0x16080000 + CPU * 0x40000` |
| VGIC maintenance IRQ | DT `GIC_PPI 9` | MADT GICC VGIC maintenance GSIV `25` |
| Secure EL1 timer | DT `GIC_PPI 13`, level-low | GTDT GSIV `29`, flags `0x3` |
| Non-secure EL1 timer | DT `GIC_PPI 14`, level-low | GTDT GSIV `30`, flags `0x3` |
| Virtual timer | DT `GIC_PPI 11`, level-low | GTDT GSIV `27`, flags `0x3` |
| Non-secure EL2 timer | DT `GIC_PPI 10`, level-low | GTDT GSIV `26`, flags `0x3` |
| Counter frequency | `19200000` | Documented here; ACPI consumers usually read CNTFRQ_EL0 |

DT interrupt translation rule used: ARM GIC PPI `N` becomes ACPI GSIV `16 + N`.

## Source paths

Source repository: `OnePlusOSS/android_kernel_modules_and_devicetree_oneplus_sm8750`

- `kernel_platform/qcom/opensource/devicetree/qcom/sun.dtsi`
  - CPU MPIDRs: `cpus` node (`reg` values for CPU0..CPU7)
  - GIC: `interrupt-controller@16000000`
  - ARM arch timer: `arch_timer: timer`
  - memory-mapped timer block: `memtimer: timer@16800000`

## Notes / assumptions

- The SM8750/Snapdragon 8 Elite SoC in this tree is represented by Qualcomm codename `sun`; `sunp` inherits `sun.dtsi` values.
- GICv3 uses the CPU system-register interface, so there is no DT `GICC` MMIO region. The MADT GICC `Physical Base Address` is therefore set to `0`.
- Performance Monitor interrupt, parked address, GICV/GICH and SPE overflow interrupt are left `0` because they are not provided by the referenced DT nodes.
- GIC ITS exists in DT at `0x16040000` size `0x20000`; it is documented but not emitted in the requested minimal MADT because the request only named GICD/GICC/GICR. Add a MADT GIC ITS subtable if PCIe/MSI routing is needed during the next bring-up step.
