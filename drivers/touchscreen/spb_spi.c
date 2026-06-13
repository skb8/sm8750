/*
 * spb_spi.c - SPI transport for Synaptics S3910 TCM (TouchComm) over SPI-HBP.
 *
 * Drop-in replacement for the I2C spb.c from edk2-porting/SynapticsTouch_TCM.
 * All public API signatures are identical; only this file and the device-resource
 * detection code in device.c need to change (see inline NOTE comments).
 *
 * Hardware facts (OnePlus 13, from DTBO dodge T0 + sun-qupv3.dtsi):
 *   SPI bus: QUPv3 SE4 @ 0x00A90000
 *   Chip select: 0 (TLMM GPIO51)
 *   Max clock: 19 MHz, Mode 0 (CPOL=0, CPHA=0)
 *   IRQ: TLMM GPIO162, edge-falling
 *   Reset: TLMM GPIO161, active-low
 *
 * NOTE for maintainers: in device.c OnPrepareHardware(), replace:
 *     res->u.Connection.Type == CM_RESOURCE_CONNECTION_TYPE_SERIAL_I2C
 * with:
 *     res->u.Connection.Type == CM_RESOURCE_CONNECTION_TYPE_SERIAL_SPI
 */

#include <internal.h>
#include <controller.h>
#include "spb_spi.h"
#include <spb.tmh>

static NTSTATUS
SpiWriteRaw(
    IN SPB_CONTEXT *SpbContext,
    IN PVOID        Buffer,
    IN ULONG        Length
)
{
    WDF_MEMORY_DESCRIPTOR memDesc;
    NTSTATUS status;

    WDF_MEMORY_DESCRIPTOR_INIT_BUFFER(&memDesc, Buffer, Length);

    status = WdfIoTargetSendWriteSynchronously(
        SpbContext->SpbIoTarget,
        NULL,
        &memDesc,
        NULL,
        NULL,
        NULL);

    if (!NT_SUCCESS(status))
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "SPI write failed (len=%u): 0x%08lX", Length, status);
    return status;
}

static NTSTATUS
SpiReadRaw(
    IN  SPB_CONTEXT *SpbContext,
    OUT PVOID        Buffer,
    IN  ULONG        Length
)
{
    WDF_MEMORY_DESCRIPTOR memDesc;
    NTSTATUS              status;
    ULONG_PTR             bytesRead = 0;

    WDF_MEMORY_DESCRIPTOR_INIT_BUFFER(&memDesc, Buffer, Length);

    status = WdfIoTargetSendReadSynchronously(
        SpbContext->SpbIoTarget,
        NULL,
        &memDesc,
        NULL,
        NULL,
        &bytesRead);

    if (!NT_SUCCESS(status) || bytesRead != Length)
    {
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "SPI read failed (expected=%u got=%u): 0x%08lX",
              Length, (ULONG)bytesRead, status);
        if (NT_SUCCESS(status)) status = STATUS_UNSUCCESSFUL;
    }
    return status;
}

/*
 * SpbWriteDataSynchronously
 * Sends: [0xA5, Command, Length_H, Length_L, Payload...]
 */
NTSTATUS
SpbWriteDataSynchronously(
    IN SPB_CONTEXT *SpbContext,
    IN UCHAR        Command,
    IN PVOID        Data,
    IN ULONG        Length
)
{
    PUCHAR   packet;
    ULONG    packetLen;
    WDFMEMORY memory = NULL;
    NTSTATUS  status;

    WdfWaitLockAcquire(SpbContext->SpbLock, NULL);

    packetLen = TCM_SPI_HEADER_SIZE + Length;

    if (packetLen <= DEFAULT_SPB_BUFFER_SIZE)
    {
        packet = (PUCHAR)WdfMemoryGetBuffer(SpbContext->WriteMemory, NULL);
    }
    else
    {
        PUCHAR tmp;
        status = WdfMemoryCreate(WDF_NO_OBJECT_ATTRIBUTES, NonPagedPool,
                                 TOUCH_POOL_TAG, packetLen, &memory, &tmp);
        if (!NT_SUCCESS(status))
        {
            Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
                  "SpbWriteDataSynchronously: alloc failed 0x%08lX", status);
            goto exit;
        }
        packet = tmp;
    }

    packet[0] = TCM_SPI_MARKER;
    packet[1] = Command;
    packet[2] = (UCHAR)((Length >> 8) & 0xFF);
    packet[3] = (UCHAR)(Length & 0xFF);

    if (Length > 0 && Data != NULL)
        RtlCopyMemory(packet + TCM_SPI_HEADER_SIZE, Data, Length);

    status = SpiWriteRaw(SpbContext, packet, packetLen);

exit:
    if (memory != NULL) WdfObjectDelete(memory);
    WdfWaitLockRelease(SpbContext->SpbLock);
    return status;
}

/*
 * SpbReadDataSynchronously
 * TX: [0xA5, Command, 0x00, 0x00]
 * RX: [STATUS, LEN_H, LEN_L, DATA...] -- caller receives DATA portion
 */
NTSTATUS
SpbReadDataSynchronously(
    IN  SPB_CONTEXT *SpbContext,
    IN  UCHAR        Command,
    OUT PVOID        Data,
    IN  ULONG        Length
)
{
    UCHAR    header[TCM_SPI_HEADER_SIZE];
    NTSTATUS status;

    WdfWaitLockAcquire(SpbContext->SpbLock, NULL);

    header[0] = TCM_SPI_MARKER;
    header[1] = Command;
    header[2] = 0;
    header[3] = 0;

    status = SpiWriteRaw(SpbContext, header, sizeof(header));
    if (!NT_SUCCESS(status))
    {
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "SpbReadDataSynchronously: write cmd failed 0x%08lX", status);
        goto exit;
    }

    status = SpiReadRaw(SpbContext, Data, Length);
    if (!NT_SUCCESS(status))
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "SpbReadDataSynchronously: read payload failed 0x%08lX", status);

exit:
    WdfWaitLockRelease(SpbContext->SpbLock);
    return status;
}

/*
 * SpbReadContinuedData
 * Plain SPI read -- used by TcmReadMessage to pull message header and payload
 * after IRQ fires. Master clocks out 0xFF on MOSI, reads MISO.
 */
NTSTATUS
SpbReadContinuedData(
    IN  SPB_CONTEXT *SpbContext,
    OUT PVOID        Data,
    IN  ULONG        Length
)
{
    NTSTATUS status;

    WdfWaitLockAcquire(SpbContext->SpbLock, NULL);
    status = SpiReadRaw(SpbContext, Data, Length);
    if (!NT_SUCCESS(status))
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "SpbReadContinuedData: read failed (len=%u) 0x%08lX",
              Length, status);
    WdfWaitLockRelease(SpbContext->SpbLock);
    return status;
}

VOID
SpbTargetDeinitialize(
    IN WDFDEVICE   FxDevice,
    IN SPB_CONTEXT *SpbContext
)
{
    UNREFERENCED_PARAMETER(FxDevice);
    if (SpbContext->SpbLock != NULL)   WdfObjectDelete(SpbContext->SpbLock);
    if (SpbContext->ReadMemory != NULL) WdfObjectDelete(SpbContext->ReadMemory);
    if (SpbContext->WriteMemory != NULL) WdfObjectDelete(SpbContext->WriteMemory);
}

NTSTATUS
SpbTargetInitialize(
    IN WDFDEVICE   FxDevice,
    IN SPB_CONTEXT *SpbContext
)
{
    WDF_OBJECT_ATTRIBUTES  objAttrs;
    WDF_IO_TARGET_OPEN_PARAMS openParams;
    UNICODE_STRING spbDeviceName;
    WCHAR  nameBuf[RESOURCE_HUB_PATH_SIZE];
    NTSTATUS status;

    WDF_OBJECT_ATTRIBUTES_INIT(&objAttrs);
    objAttrs.ParentObject = FxDevice;

    status = WdfIoTargetCreate(FxDevice, &objAttrs, &SpbContext->SpbIoTarget);
    if (!NT_SUCCESS(status))
    {
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "WdfIoTargetCreate failed 0x%08lX", status);
        goto exit;
    }

    RtlInitEmptyUnicodeString(&spbDeviceName, nameBuf, sizeof(nameBuf));

    status = RESOURCE_HUB_CREATE_PATH_FROM_ID(
        &spbDeviceName,
        SpbContext->I2cResHubId.LowPart,
        SpbContext->I2cResHubId.HighPart);
    if (!NT_SUCCESS(status))
    {
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "RESOURCE_HUB_CREATE_PATH_FROM_ID failed 0x%08lX", status);
        goto exit;
    }

    WDF_IO_TARGET_OPEN_PARAMS_INIT_OPEN_BY_NAME(
        &openParams, &spbDeviceName, GENERIC_READ | GENERIC_WRITE);
    openParams.ShareAccess    = 0;
    openParams.CreateDisposition = FILE_OPEN;
    openParams.FileAttributes = FILE_ATTRIBUTE_NORMAL;

    status = WdfIoTargetOpen(SpbContext->SpbIoTarget, &openParams);
    if (!NT_SUCCESS(status))
    {
        Trace(TRACE_LEVEL_ERROR, TRACE_SPB,
              "WdfIoTargetOpen (SPI) failed 0x%08lX", status);
        goto exit;
    }

    status = WdfMemoryCreate(WDF_NO_OBJECT_ATTRIBUTES, NonPagedPool,
                             TOUCH_POOL_TAG, DEFAULT_SPB_BUFFER_SIZE,
                             &SpbContext->WriteMemory, NULL);
    if (!NT_SUCCESS(status)) goto exit;

    status = WdfMemoryCreate(WDF_NO_OBJECT_ATTRIBUTES, NonPagedPool,
                             TOUCH_POOL_TAG, DEFAULT_SPB_BUFFER_SIZE,
                             &SpbContext->ReadMemory, NULL);
    if (!NT_SUCCESS(status)) goto exit;

    status = WdfWaitLockCreate(WDF_NO_OBJECT_ATTRIBUTES, &SpbContext->SpbLock);

exit:
    if (!NT_SUCCESS(status))
        SpbTargetDeinitialize(FxDevice, SpbContext);
    return status;
}
