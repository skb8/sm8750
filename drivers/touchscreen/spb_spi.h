/*
 * spb_spi.h - SPI transport for Synaptics TCM (TouchComm) protocol.
 *
 * Replaces the I2C spb.h/spb.c from edk2-porting/SynapticsTouch_TCM for
 * the OnePlus 13 (SM8750) S3910 touchscreen, which is wired to QUPv3 SE4
 * via SPI-HBP (Host Bus Protocol) rather than I2C.
 *
 * TCM SPI-HBP framing (Synaptics TCM spec):
 *   Write: [0xA5, CMD, LEN_H, LEN_L, PAYLOAD...]
 *   Read:  [STATUS, LEN_H, LEN_L, PAYLOAD...]   <- host clocks out 0xFF padding
 *   Continued read (interrupt-driven): [0xA5, 0x03, LEN_H, LEN_L, PAYLOAD..., 0x5A]
 *
 * The context struct is API-compatible with the I2C SPB_CONTEXT so the rest
 * of the driver (touch_tcm.c, hid.c, report.c) can be used unchanged.
 */

#pragma once

#include <wdm.h>
#include <wdf.h>

#define DEFAULT_SPB_BUFFER_SIZE     256

// TCM SPI packet framing constants (from touch_tcm.h)
#define TCM_SPI_MARKER              0xA5
#define TCM_SPI_CONTINUED_READ      0x03
#define TCM_SPI_PADDING             0x5A
#define TCM_SPI_HEADER_SIZE         4       // [Marker, Code/Cmd, Len_H, Len_L]

// SPI transaction timeout (ms)
#define SPI_TRANSFER_TIMEOUT_MS     500

typedef struct _SPB_CONTEXT
{
    WDFIOTARGET    SpbIoTarget;

    // Resource hub ID -- same field name as the I2C version so device.c compiles
    // unchanged; here it refers to the SPI bus connection descriptor ID.
    LARGE_INTEGER  I2cResHubId;     // reused as SpiResHubId for API compat

    WDFMEMORY      WriteMemory;
    WDFMEMORY      ReadMemory;
    WDFWAITLOCK    SpbLock;
} SPB_CONTEXT;

NTSTATUS
SpbTargetInitialize(
    IN WDFDEVICE   FxDevice,
    IN SPB_CONTEXT *SpbContext
    );

VOID
SpbTargetDeinitialize(
    IN WDFDEVICE   FxDevice,
    IN SPB_CONTEXT *SpbContext
    );

NTSTATUS
SpbWriteDataSynchronously(
    IN SPB_CONTEXT *SpbContext,
    IN UCHAR        Command,
    IN PVOID        Data,
    IN ULONG        Length
    );

NTSTATUS
SpbReadDataSynchronously(
    IN  SPB_CONTEXT *SpbContext,
    IN  UCHAR        Command,
    OUT PVOID        Data,
    IN  ULONG        Length
    );

NTSTATUS
SpbReadContinuedData(
    IN  SPB_CONTEXT *SpbContext,
    OUT PVOID        Data,
    IN  ULONG        Length
    );
