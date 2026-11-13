# Vendor files for the Nokia Lumia 930 (martini)

Proprietary files for the LineageOS 18.1 port.

**Status: not booted — the device is not available yet.**

As on the Lumia 950 XL vendor, the firmware of the 930 is included, so the
ROM zip is self-sufficient. Phone-specific data (MAC addresses, the Wi-Fi
calibration in DPP, modem EFS) is never here: the installer copies it from
the phone into `persist` and the modem partitions.

## Firmware of the 930 (`proprietary/`, committed)

Taken from the Windows Phone driver package of the Lumia 930,
`DEVICE.SOC_QC8974.MARTINI` (and `qcwlan8974cfg.dat` from the shared
`OEM.SOC_QC8974.NMO` package), as collected in
[sonic011gamer/Lumia-Drivers](https://github.com/sonic011gamer/Lumia-Drivers)
(commit `c57daab`). The same repository's Lumia 1520 package was checked
against the files extracted from a real 1520's Windows: all eight files are
byte-identical. Compared with the official Windows Phone 8.1 FFU of the 930
(RM-1045, 02540.00019.15236.45005), the ADSP image, the Wi-Fi configuration and
all eight ACDB files are identical; MBA, modem, Venus and WCNSS are newer builds
(the driver packages match what a Windows 10 Mobile 1520 runs). `proprietary/SOURCE`
and `proprietary/SHA256SUMS` list the
files and their hashes; they are split into `.mdt`/`.bNN` as the 3.4 kernel
PIL loaders want them.

| Windows file | Installed as |
|---|---|
| `qcadsp8974.mbn` → `adsp.mdt/.bNN` | `/vendor/firmware/adsp.*` |
| `qcdsp28974.mbn` → `modem.mdt/.bNN`, `qcdsp1v28974.mbn` → `mba.b00` + `mba.mdt` (headers) | `/vendor/firmware/modem.*`, `mba.mdt`, `mba.b00` |
| `qcwcnss8974.mbn` → `wcnss.mdt/.bNN` | `/vendor/firmware/wcnss.*` |
| `qcvss8974.mbn` → `venus.mdt/.bNN` | `/vendor/firmware/venus.*` |
| `qcwlan8974cfg.dat` (same format as `WCNSS_cfg.dat`) | `/vendor/firmware/wlan/prima/WCNSS_cfg.dat` |
| `<Name>_cal_8974.acdb` | `/system/etc/acdbdata/MTP/MTP_<Name>_cal.acdb` |

The modem and MBA images are SSD-encrypted, as on the 1520: the kernel
decrypts them on the phone with the keys of its own `SSD` partition.

These files are the property of Microsoft, Nokia and Qualcomm and are
redistributed as on the other Lumia Android vendor trees, only to run Android
on the phones they were made for.

## Files from your own phone (`proprietary-local/`, optional)

`extract-local.sh` fills `proprietary-local/` (in `.gitignore`, same layout)
from the folder the installer writes with its "Firmware from Windows" step
(`private/firmware-YYYYMMDD-HHMMSS/`). It checks the hashes and the Lumia 930
product code in the registry hives (RM-1045, RM-1087). `martini-vendor.mk`
lists `proprietary-local/` first, so a phone's own files win over the
committed ones (useful if a firmware version on a phone differs).

```bash
./extract-local.sh /path/to/private/firmware-YYYYMMDD-HHMMSS
```

Not included anywhere: the WCNSS NV (`WCNSS_qcom_wlan_nv.bin`; the generic one
from `msm8974-common` is used, the phone's own calibration comes from DPP
through the installer), MAC and Bluetooth addresses, EFS/modem data.

## Camera (`proprietary/vendor/{bin,lib,firmware}`)

- The 2014 mm-camera2 stack of the OnePlus One (`mm-qcamera-daemon`, the
  `libmmcamera2_*` modules, C2D/CPP/JPEG libraries, `cpp_firmware_v1_2_0.fw`,
  the DW9714 AF tuning libraries), from TheMuppets' `proprietary_vendor_oneplus`
  (bacon, lineage-18.1). Only `libmmcamera2_sensor_modules.so` is changed: its
  sensor list is renamed to `karma` (rear) and `skyphd` (front), so the daemon
  loads the plug-ins built from `camera-sensors/` of the device tree.
- `libchromatix_karma_*.so`: the Karma module tuning (colour matrices, white
  balance references, colour shading) in the chromatix layout of that daemon.
- `lumia-ois-10454107.bin`: firmware, init and mode blocks of the rear focus /
  OIS controller for module 0x4541 revision 7, loaded by the kernel actuator.

## Generic MSM8974 blobs

Adreno, QMI/RIL, location and the other common blobs come from TheMuppets
(`proprietary_vendor_oppo`, `msm8974-common`, lineage-18.1), included by
`martini-vendor.mk`. The OnePlus One Venus firmware it carries is filtered
out.

## Credits

- Microsoft, Nokia and Qualcomm — the Lumia 930 firmware and calibration.
- sonic011gamer, [Lumia-Drivers](https://github.com/sonic011gamer/Lumia-Drivers)
  — collection of the Lumia Windows Phone driver packages the firmware is
  taken from.
- [TheMuppets](https://github.com/TheMuppets) — `proprietary_vendor_oppo`
  (generic MSM8974 blobs) and `proprietary_vendor_oneplus` (bacon camera stack).
- OnePlus and OPPO — the OnePlus One / Find 7 camera stack.
- [LineageOS](https://github.com/LineageOS) — `android_device_oppo_msm8974-common`
  (layout of the blob lists, Wi-Fi/audio configuration).
- [KorelisLabs/lumia-1520-mainline](https://github.com/KorelisLabs/lumia-1520-mainline)
  (HEAD `04f8972`) — list of the MSM8974 Lumia firmware images and
  `tools/pil-split.py`, used by the kit to split them into `.mdt`/`.bNN`.
- Markynose (Mark Buchok), [lumia930-linux](https://github.com/Markynose/lumia930-linux)
  — Lumia 930 hardware notes.
- [WPinternals](https://github.com/ReneLergner/WPinternals) (René Lergner,
  HeathCliff) — mass storage access used to extract the files from the phone.
