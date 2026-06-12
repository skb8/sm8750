#!/usr/bin/env python3
from __future__ import annotations
import struct
from pathlib import Path
from textwrap import dedent

OUT = Path(__file__).resolve().parents[1]
ACPI = OUT / 'acpi'
DOCS = OUT / 'docs'

OEM_ID = b'QCOMM '  # 6 bytes
OEM_TABLE_ID = b'SM8750  '  # 8 bytes
CREATOR_ID = b'VIKT'
CREATOR_REV = 0x20260612
OEM_REV = 1

GICD_BASE = 0x16000000
GICD_SIZE = 0x00010000
GIC_ITS_BASE = 0x16040000
GIC_ITS_SIZE = 0x00020000
GICR_BASE = 0x16080000
GICR_STRIDE = 0x00040000
GICR_SIZE = 0x00200000
GICC_BASE = 0x0  # GICv3 system-register CPU interface; no MMIO GICC region in DT
VGIC_MAINT_GSIV = 16 + 9

CPUS = [
    (0, 0x0000000000000000),
    (1, 0x0000000000000100),
    (2, 0x0000000000000200),
    (3, 0x0000000000000300),
    (4, 0x0000000000000400),
    (5, 0x0000000000000500),
    (6, 0x0000000000010000),
    (7, 0x0000000000010100),
]

# Device-tree arm,armv8-timer order: secure, non-secure, virtual, hypervisor/non-secure EL2.
TIMER_PPI = {
    'secure_el1': 13,
    'non_secure_el1': 14,
    'virtual': 11,
    'non_secure_el2': 10,
}
TIMER_GSIV = {k: 16 + v for k, v in TIMER_PPI.items()}
TIMER_FLAGS_LEVEL_LOW = 0x00000003  # GTDT: bit0 level-triggered, bit1 active-low
COUNTER_FREQ = 19200000
MEMTIMER_CTRL_BASE = 0x16800000
MEMTIMER_READ_BASE = 0x16802000


def acpi_header(signature: bytes, revision: int, length: int) -> bytes:
    # Checksum filled by finalize_table().
    return struct.pack('<4sIBB6s8sI4sI', signature, length, revision, 0,
                       OEM_ID, OEM_TABLE_ID, OEM_REV, CREATOR_ID, CREATOR_REV)


def finalize_table(data: bytes) -> bytes:
    b = bytearray(data)
    b[9] = (-sum(b)) & 0xff
    return bytes(b)


def build_madt() -> bytes:
    body = bytearray()
    body += struct.pack('<II', 0, 0)  # Local Interrupt Controller Address, Flags

    for uid, mpidr in CPUS:
        gicr_base = GICR_BASE + uid * GICR_STRIDE
        flags = 0x00000001  # Enabled
        sub = struct.pack(
            '<BBHIIIIIQQQQIQQBBH',
            0x0B, 80, 0,
            uid,              # CPU Interface Number
            uid,              # ACPI Processor UID
            flags,
            0,                # Parking Protocol Version
            0,                # Performance Interrupt GSIV (unknown/not described by DT)
            0,                # Parked Address
            GICC_BASE,        # Physical Base Address (0 for GICv3 sysreg interface)
            0,                # GICV
            0,                # GICH
            VGIC_MAINT_GSIV,  # VGIC Maintenance Interrupt (DT PPI 9 -> GSIV 25)
            gicr_base,        # GICR Base Address for this CPU
            mpidr,
            0,                # Processor Power Efficiency Class
            0,                # Reserved
            0,                # SPE overflow interrupt
        )
        assert len(sub) == 80
        body += sub

    gicd = struct.pack('<BBHIQIB3s', 0x0C, 24, 0, 0, GICD_BASE, 0, 3, b'\0\0\0')
    assert len(gicd) == 24
    body += gicd

    gicr = struct.pack('<BBHQI', 0x0E, 16, 0, GICR_BASE, GICR_SIZE)
    assert len(gicr) == 16
    body += gicr

    table = acpi_header(b'APIC', 5, 36 + len(body)) + body
    return finalize_table(table)


def build_gtdt() -> bytes:
    body = struct.pack(
        '<QI'  # Counter Control Base Physical Address, Reserved
        'IIIIIIII'  # four timer GSIV/Flags pairs
        'QII',  # Counter Read Block Base, Platform Timer Count, Platform Timer Offset
        MEMTIMER_CTRL_BASE,
        0,
        TIMER_GSIV['secure_el1'], TIMER_FLAGS_LEVEL_LOW,
        TIMER_GSIV['non_secure_el1'], TIMER_FLAGS_LEVEL_LOW,
        TIMER_GSIV['virtual'], TIMER_FLAGS_LEVEL_LOW,
        TIMER_GSIV['non_secure_el2'], TIMER_FLAGS_LEVEL_LOW,
        MEMTIMER_READ_BASE,
        0,
        0,
    )
    assert len(body) == 60
    table = acpi_header(b'GTDT', 3, 36 + len(body)) + body
    return finalize_table(table)


def hex8(v): return f'{v:08X}'
def hex16(v): return f'{v:016X}'

def madt_asl(checksum: int, length: int) -> str:
    lines = []
    lines.append(dedent(f'''\
        /*
         * SM8750 / Snapdragon 8 Elite ACPI MADT (APIC) data-table source.
         * Values are translated from OnePlusOSS qcom/sun.dtsi.
         * Compile target: ACPI data-table ASL/DSL style (iasl data table syntax).
         */
        [000h 0000   4]                    Signature : "APIC"    [Multiple APIC Description Table (MADT)]
        [004h 0004   4]                 Table Length : {hex8(length)}
        [008h 0008   1]                     Revision : 05
        [009h 0009   1]                     Checksum : {checksum:02X}
        [00Ah 0010   6]                       Oem ID : "QCOMM "
        [010h 0016   8]                 Oem Table ID : "SM8750  "
        [018h 0024   4]                 Oem Revision : {hex8(OEM_REV)}
        [01Ch 0028   4]              Asl Compiler ID : "VIKT"
        [020h 0032   4]        Asl Compiler Revision : {hex8(CREATOR_REV)}

        [024h 0036   4] Local Interrupt Controller Address : 00000000
        [028h 0040   4]        Flags (decoded below) : 00000000
        '''))
    off = 0x02C
    for uid, mpidr in CPUS:
        gicr = GICR_BASE + uid * GICR_STRIDE
        lines.append(dedent(f'''\

        [{off:03X}h {off:04d}   1]                 Subtable Type : 0B [Generic Interrupt Controller]
        [{off+1:03X}h {off+1:04d}   1]                        Length : 50
        [{off+2:03X}h {off+2:04d}   2]                      Reserved : 0000
        [{off+4:03X}h {off+4:04d}   4]          CPU Interface Number : {hex8(uid)}
        [{off+8:03X}h {off+8:04d}   4]             Processor UID : {hex8(uid)}
        [{off+12:03X}h {off+12:04d}   4]        Flags (decoded below) : 00000001
                                      Processor Enabled : 1
        [{off+16:03X}h {off+16:04d}   4]       Parking Protocol Version : 00000000
        [{off+20:03X}h {off+20:04d}   4]       Performance Interrupt GSIV : 00000000
        [{off+24:03X}h {off+24:04d}   8]          Parked Address : 0000000000000000
        [{off+32:03X}h {off+32:04d}   8]   Physical Base Address (GICC) : {hex16(GICC_BASE)}
        [{off+40:03X}h {off+40:04d}   8]       GICV Base Address : 0000000000000000
        [{off+48:03X}h {off+48:04d}   8]       GICH Base Address : 0000000000000000
        [{off+56:03X}h {off+56:04d}   4]  VGIC Maintenance Interrupt : {hex8(VGIC_MAINT_GSIV)}
        [{off+60:03X}h {off+60:04d}   8]       GICR Base Address : {hex16(gicr)}
        [{off+68:03X}h {off+68:04d}   8]                    MPIDR : {hex16(mpidr)}
        [{off+76:03X}h {off+76:04d}   1] Processor Power Efficiency Class : 00
        [{off+77:03X}h {off+77:04d}   1]                    Reserved : 00
        [{off+78:03X}h {off+78:04d}   2]          SPE Overflow Interrupt : 0000
        '''))
        off += 80
    lines.append(dedent(f'''\

        [{off:03X}h {off:04d}   1]                 Subtable Type : 0C [Generic Interrupt Distributor]
        [{off+1:03X}h {off+1:04d}   1]                        Length : 18
        [{off+2:03X}h {off+2:04d}   2]                      Reserved : 0000
        [{off+4:03X}h {off+4:04d}   4]                GIC ID : 00000000
        [{off+8:03X}h {off+8:04d}   8] Physical Base Address (GICD) : {hex16(GICD_BASE)}
        [{off+16:03X}h {off+16:04d}   4]        System Vector Base : 00000000
        [{off+20:03X}h {off+20:04d}   1]                  GIC Version : 03
        [{off+21:03X}h {off+21:04d}   3]                    Reserved : 000000
        '''))
    off += 24
    lines.append(dedent(f'''\

        [{off:03X}h {off:04d}   1]                 Subtable Type : 0E [Generic Interrupt Redistributor]
        [{off+1:03X}h {off+1:04d}   1]                        Length : 10
        [{off+2:03X}h {off+2:04d}   2]                      Reserved : 0000
        [{off+4:03X}h {off+4:04d}   8]     Discovery Range Base Address : {hex16(GICR_BASE)}
        [{off+12:03X}h {off+12:04d}   4]          Discovery Range Length : {hex8(GICR_SIZE)}
        '''))
    return ''.join(lines)


def gtdt_asl(checksum: int, length: int) -> str:
    return dedent(f'''\
        /*
         * SM8750 / Snapdragon 8 Elite ACPI GTDT data-table source.
         * ARM arch timer IRQs translated from qcom/sun.dtsi:
         *   DT PPI 13/14/11/10 -> ACPI GSIV 29/30/27/26 (PPI + 16).
         */
        [000h 0000   4]                    Signature : "GTDT"    [Generic Timer Description Table]
        [004h 0004   4]                 Table Length : {hex8(length)}
        [008h 0008   1]                     Revision : 03
        [009h 0009   1]                     Checksum : {checksum:02X}
        [00Ah 0010   6]                       Oem ID : "QCOMM "
        [010h 0016   8]                 Oem Table ID : "SM8750  "
        [018h 0024   4]                 Oem Revision : {hex8(OEM_REV)}
        [01Ch 0028   4]              Asl Compiler ID : "VIKT"
        [020h 0032   4]        Asl Compiler Revision : {hex8(CREATOR_REV)}

        [024h 0036   8] Counter Control Block Physical Address : {hex16(MEMTIMER_CTRL_BASE)}
        [02Ch 0044   4]                    Reserved : 00000000
        [030h 0048   4]        Secure EL1 Timer GSIV : {hex8(TIMER_GSIV['secure_el1'])}
        [034h 0052   4]       Secure EL1 Timer Flags : {hex8(TIMER_FLAGS_LEVEL_LOW)}    [level-triggered, active-low]
        [038h 0056   4]    Non-secure EL1 Timer GSIV : {hex8(TIMER_GSIV['non_secure_el1'])}
        [03Ch 0060   4]   Non-secure EL1 Timer Flags : {hex8(TIMER_FLAGS_LEVEL_LOW)}    [level-triggered, active-low]
        [040h 0064   4]            Virtual Timer GSIV : {hex8(TIMER_GSIV['virtual'])}
        [044h 0068   4]           Virtual Timer Flags : {hex8(TIMER_FLAGS_LEVEL_LOW)}    [level-triggered, active-low]
        [048h 0072   4] Non-secure EL2 Timer GSIV : {hex8(TIMER_GSIV['non_secure_el2'])}
        [04Ch 0076   4] Non-secure EL2 Timer Flags : {hex8(TIMER_FLAGS_LEVEL_LOW)}      [level-triggered, active-low]
        [050h 0080   8] Counter Read Block Physical Address : {hex16(MEMTIMER_READ_BASE)}
        [058h 0088   4]          Platform Timer Count : 00000000
        [05Ch 0092   4]         Platform Timer Offset : 00000000
        ''')


def write_files():
    ACPI.mkdir(parents=True, exist_ok=True)
    DOCS.mkdir(parents=True, exist_ok=True)
    madt = build_madt()
    gtdt = build_gtdt()
    (ACPI / 'sm8750-madt.asl').write_text(madt_asl(madt[9], len(madt)), encoding='utf-8')
    (ACPI / 'sm8750-gtdt.asl').write_text(gtdt_asl(gtdt[9], len(gtdt)), encoding='utf-8')
    (ACPI / 'sm8750-madt.dat').write_bytes(madt)
    (ACPI / 'sm8750-gtdt.dat').write_bytes(gtdt)
    (ACPI / 'README.md').write_text(dedent(f'''\
        # SM8750 ACPI MADT/GTDT

        Initial ACPI table sources for Windows on ARM bring-up on SM8750 / Snapdragon 8 Elite (Oryon, 8 cores), translated from the OnePlusOSS device-tree `qcom/sun.dtsi`.

        ## Files

        - `sm8750-madt.asl` — MADT/APIC data-table ASL/DSL source with GICC entries for 8 CPUs plus GICD/GICR.
        - `sm8750-gtdt.asl` — GTDT data-table ASL/DSL source with ARM arch timer GSIVs.
        - `sm8750-madt.dat`, `sm8750-gtdt.dat` — binary tables generated from the same values, with checksums filled.

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
        '''), encoding='utf-8')
    print(f'MADT length={len(madt)} checksum=0x{madt[9]:02x}')
    print(f'GTDT length={len(gtdt)} checksum=0x{gtdt[9]:02x}')

if __name__ == '__main__':
    write_files()
