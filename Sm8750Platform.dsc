## @file
# Minimal EDK2 platform description for building XenonBoot on SM8750 / Snapdragon 8 Elite.
#
# Intended command when this repo is used as the EDK2 workspace root or is made
# visible through PACKAGES_PATH:
#   build -a AARCH64 -t GCC5 -p Sm8750Platform.dsc
#
# If the repo is checked out inside a larger EDK2 workspace as "sm8750", the
# same component path is: sm8750/edk2/XenonBoot/XenonBoot.inf. In that layout,
# either run with -p sm8750/Sm8750Platform.dsc or copy this DSC to the workspace
# root and change SM8750_XENONBOOT_PATH to sm8750/edk2.
##

[Defines]
  PLATFORM_NAME                  = Sm8750Platform
  PLATFORM_GUID                  = 8750A11B-5E34-4A5C-9E9E-534D38373530
  PLATFORM_VERSION               = 0.1
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/Sm8750Platform
  SUPPORTED_ARCHITECTURES        = AARCH64
  BUILD_TARGETS                  = DEBUG|RELEASE
  SKUID_IDENTIFIER               = DEFAULT

  # For the exact command requested above, this DSC sits at the same level as
  # the edk2/ directory in this repo. If your EDK2 workspace has this repo under
  # a sm8750/ subdirectory and the DSC at workspace root, set this to sm8750/edk2.
  DEFINE SM8750_XENONBOOT_PATH   = edk2

[Packages]
  MdePkg/MdePkg.dec
  MdeModulePkg/MdeModulePkg.dec
  EmbeddedPkg/EmbeddedPkg.dec
  ArmPkg/ArmPkg.dec

[LibraryClasses]
  # Core Base/Uefi library instances from MdePkg.
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  CacheMaintenanceLib|MdePkg/Library/BaseCacheMaintenanceLib/BaseCacheMaintenanceLib.inf
  DebugLib|MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
  DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLibDevicePathProtocol/UefiDevicePathLibDevicePathProtocol.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  ReportStatusCodeLib|MdePkg/Library/BaseReportStatusCodeLibNull/BaseReportStatusCodeLibNull.inf
  SynchronizationLib|MdePkg/Library/BaseSynchronizationLib/BaseSynchronizationLib.inf
  TimerLib|MdePkg/Library/BaseTimerLibNullTemplate/BaseTimerLibNullTemplate.inf
  UefiApplicationEntryPoint|MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf

  # ARM/AARCH64 support for current tianocore/edk2 master.
  # ArmBaseLib and CompilerIntrinsicsLib were moved from ArmPkg to MdePkg.
  ArmLib|MdePkg/Library/ArmLib/ArmBaseLib.inf
  NULL|MdePkg/Library/CompilerIntrinsicsLib/CompilerIntrinsicsLib.inf

[Components.AARCH64]
  $(SM8750_XENONBOOT_PATH)/XenonBoot/XenonBoot.inf
