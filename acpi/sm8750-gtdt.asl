/*
 * SM8750 / Snapdragon 8 Elite ACPI GTDT data-table source.
 * ARM arch timer IRQs translated from qcom/sun.dtsi:
 *   DT PPI 13/14/11/10 -> ACPI GSIV 29/30/27/26 (PPI + 16).
 */
[000h 0000   4]                    Signature : "GTDT"    [Generic Timer Description Table]
[004h 0004   4]                 Table Length : 00000060
[008h 0008   1]                     Revision : 03
[009h 0009   1]                     Checksum : B4
[00Ah 0010   6]                       Oem ID : "QCOMM "
[010h 0016   8]                 Oem Table ID : "SM8750  "
[018h 0024   4]                 Oem Revision : 00000001
[01Ch 0028   4]              Asl Compiler ID : "VIKT"
[020h 0032   4]        Asl Compiler Revision : 20260612

[024h 0036   8] Counter Control Block Physical Address : 0000000016800000
[02Ch 0044   4]                    Reserved : 00000000
[030h 0048   4]        Secure EL1 Timer GSIV : 0000001D
[034h 0052   4]       Secure EL1 Timer Flags : 00000003    [level-triggered, active-low]
[038h 0056   4]    Non-secure EL1 Timer GSIV : 0000001E
[03Ch 0060   4]   Non-secure EL1 Timer Flags : 00000003    [level-triggered, active-low]
[040h 0064   4]            Virtual Timer GSIV : 0000001B
[044h 0068   4]           Virtual Timer Flags : 00000003    [level-triggered, active-low]
[048h 0072   4] Non-secure EL2 Timer GSIV : 0000001A
[04Ch 0076   4] Non-secure EL2 Timer Flags : 00000003      [level-triggered, active-low]
[050h 0080   8] Counter Read Block Physical Address : 0000000016802000
[058h 0088   4]          Platform Timer Count : 00000000
[05Ch 0092   4]         Platform Timer Offset : 00000000
