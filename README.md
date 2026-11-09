# Vendor files for the Nokia Lumia 930 (martini)

Proprietary files for the LineageOS 18.1 port. **This repository is public
and contains no blob**: the files of the 930 are taken from your own phone
and stay in a local folder ignored by git.

**Status: not booted — the device is not available yet.** No file of a
Lumia 930 has been extracted with this script so far.

This tree is a copy of
[android_vendor_nokia_bandit](https://github.com/lumia-msm8974/android_vendor_nokia_bandit)
(Lumia 1520, `c2a1b54`) with the names changed to martini. The bandit
repository tracks no 1520 firmware or calibration either, so nothing of the
1520 is carried over: every phone-specific file below must be extracted
from a 930.

## Files of the 930 (local only)

`extract-local.sh` fills `proprietary-local/` (in `.gitignore`) from the
folder where the installer/kit extracted the phone's files
(`private/firmware-YYYYMMDD-HHMMSS/`, with `split/`, `stock/`, `registro/`
and their `.sha256` lists; the kit is `kit/scripts/01-estrai-firmware.sh`
of the Lumia 1520 project and is not device specific). It checks the
hashes, checks that the registry hives carry a Lumia 930 product code
(RM-1045 or RM-1087: the same kit also extracts 1520s), copies the files
and writes `proprietary-local/SHA256SUMS` and `SOURCE`.

```bash
./extract-local.sh /path/to/private/firmware-YYYYMMDD-HHMMSS
./extract-local.sh        # newest private/firmware-* above this folder
```

Run it in every checkout you build from (for example
`los18/vendor/nokia/martini`): the build container only sees the source tree.

| From the phone (`stock/Windows/system32`, `split/`) | Installed as |
|---|---|
| `qcadsp8974.mbn` → `adsp.mdt/.bNN` | `/vendor/firmware/adsp.*` |
| `qcdsp28974.mbn` → `modem.mdt/.bNN`, `qcdsp1v28974.mbn` → `mba.b00` + `mba.mdt` (headers) | `/vendor/firmware/modem.*`, `mba.mdt`, `mba.b00` |
| `qcwcnss8974.mbn` → `wcnss.mdt/.bNN` | `/vendor/firmware/wcnss.*` |
| `qcvss8974.mbn` → `venus.mdt/.bNN` | `/vendor/firmware/venus.*` |
| `qcwlan8974cfg.dat` (same format as `WCNSS_cfg.dat`) | `/vendor/firmware/wlan/prima/WCNSS_cfg.dat` |
| `<Name>_cal_8974.acdb` | `/system/etc/acdbdata/MTP/MTP_<Name>_cal.acdb` |

The file names are the ones of the 1520 Windows firmware (same MSM8974
family). TODO: confirm them on a 930 MainOS/FFU; the ACPI tables (PLAT) and
registry hives the kit saves are needed for the open items of the device
tree (sensors, NFC, keys).

`martini-vendor.mk` lists whatever is present in `proprietary-local/`
before the generic files, so the 930 files win. If the folder is missing the
build still works, without them (and without Venus firmware).

Not taken from the phone by this script: the WCNSS NV
(`WCNSS_qcom_wlan_nv.bin`; the generic one from `msm8974-common` is used, the
phone's own calibration comes from DPP through the installer), MAC and
Bluetooth addresses, EFS/modem data. Per-device data is never committed
here.

## Generic MSM8974 blobs

Adreno, QMI/RIL, location and the other common blobs come from TheMuppets
(`proprietary_vendor_oppo`, `msm8974-common`, lineage-18.1), included by
`martini-vendor.mk`. The OnePlus One Venus firmware it carries is filtered
out.

## Credits

- [TheMuppets](https://github.com/TheMuppets) — `proprietary_vendor_oppo`
  (generic MSM8974 blobs).
- [LineageOS](https://github.com/LineageOS) — `android_device_oppo_msm8974-common`
  (layout of the blob lists, Wi-Fi/audio configuration).
- [KorelisLabs/lumia-1520-mainline](https://github.com/KorelisLabs/lumia-1520-mainline)
  (HEAD `04f8972`) — list of the MSM8974 Lumia firmware images and
  `tools/pil-split.py`, used by the kit to split them into `.mdt`/`.bNN`.
- Markynose (Mark Buchok), [lumia930-linux](https://github.com/Markynose/lumia930-linux)
  — Lumia 930 hardware notes.
- [WPinternals](https://github.com/ReneLergner/WPinternals) (René Lergner,
  HeathCliff) — mass storage access used to extract the files from the phone.
