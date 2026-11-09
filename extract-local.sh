#!/usr/bin/env bash
#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# Fill proprietary-local/ (ignored by git) with the firmware and calibration
# files extracted from your own Lumia 930. Nothing is downloaded and nothing
# here is ever committed.
#
# Usage: extract-local.sh [EXTRACT_DIR]
#
# EXTRACT_DIR is the folder written by the installer / kit when it extracts
# the phone's files (kit/scripts/01-estrai-firmware.sh of the Lumia 1520
# project, e.g. private/firmware-YYYYMMDD-HHMMSS). It must contain:
#   split/                     adsp, modem, mba, wcnss, venus as .mdt/.bNN
#   split.sha256               hashes of split/
#   stock/Windows/system32/    qcwlan8974cfg.dat and *_cal_8974.acdb
#   stock.sha256               hashes of stock/
#   registro/SYSTEM, SOFTWARE  registry hives (product code check)
# Without an argument, the newest private/firmware-* folder found in a parent
# directory of this script is used.
#
# The same kit extracts the Lumia 1520 too, and a checkout may sit below the
# 1520 project folder: the product code in the registry hives must be a
# Lumia 930 one (RM-1045, RM-1087), otherwise nothing is copied.
# MARTINI_SKIP_MODEL_CHECK=1 skips the check (only when the hives hold no
# product code at all; TODO: confirm the code on a real 930 extraction).
#
# Run it in every checkout that is built (for example also in
# los18/vendor/nokia/martini): the build container only sees the source tree.

set -euo pipefail

here=$(cd -- "$(dirname -- "$0")" && pwd)
out="$here/proprietary-local"

find_extract_dir() {
	local d=$here
	while [ "$d" != / ]; do
		local c
		c=$(ls -1d "$d"/private/firmware-* 2>/dev/null | sort | tail -n 1 || true)
		if [ -n "$c" ]; then
			echo "$c"
			return 0
		fi
		d=$(dirname -- "$d")
	done
	return 1
}

src=${1:-}
if [ -z "$src" ]; then
	src=$(find_extract_dir) || {
		echo "No private/firmware-* folder found; pass it as argument." >&2
		exit 1
	}
fi
src=$(cd -- "$src" && pwd)
echo "Source: $src"

for f in split split.sha256 stock/Windows/system32 stock.sha256; do
	[ -e "$src/$f" ] || { echo "Missing $src/$f" >&2; exit 1; }
done

# Product codes (RM-NNN[N]) found in the registry hives, ASCII or UTF-16LE.
models=$(python3 -I - "$src/registro/SYSTEM" "$src/registro/SOFTWARE" <<'PY'
import re, sys
codes = set()
for path in sys.argv[1:]:
    try:
        d = open(path, 'rb').read()
    except OSError:
        continue
    codes.update(m.decode() for m in re.findall(rb'RM-[0-9]{3,4}', d))
    codes.update(m.decode('utf-16-le')
                 for m in re.findall(rb'R\x00M\x00-\x00(?:[0-9]\x00){3,4}', d))
print(' '.join(sorted(codes)))
PY
)
case " $models " in
*" RM-1045 "* | *" RM-1087 "*)
	echo "Lumia 930 product code: $models" ;;
*)
	if [ -z "$models" ] && [ "${MARTINI_SKIP_MODEL_CHECK:-0}" = 1 ]; then
		echo "No product code in the registry hives, check skipped" >&2
	else
		echo "Not a Lumia 930 extraction (product codes: ${models:-none})." >&2
		echo "Pass the folder extracted from the 930 as argument." >&2
		exit 1
	fi ;;
esac

# Verify the extraction before using it.
(cd "$src/split" && sha256sum --quiet -c ../split.sha256)
(cd "$src/stock" && sha256sum --quiet -c ../stock.sha256)
echo "Hashes OK"

rm -rf "$out"
fw="$out/vendor/firmware"
mkdir -p "$fw/wlan/prima" "$out/system/etc/acdbdata/MTP"

# Peripheral images for the kernel PIL loaders (names used by the 3.4
# msm8974 kernel: adsp, modem + mba.b00, wcnss, venus).
n=0
for img in adsp modem wcnss venus; do
	[ -f "$src/split/$img.mdt" ] || { echo "Missing split/$img.mdt" >&2; exit 1; }
	cp -p "$src/split/$img.mdt" "$src/split/$img".b[0-9][0-9] "$fw/"
	n=$((n + 1))
done
cp -p "$src/split/mba.b00" "$fw/mba.b00"

# The PIL of the 3.4 kernel loads the modem boot authenticator as
# mba.mdt + mba.b00. qcdsp1v28974.mbn is an ELF with a single segment and no
# hash segment, so the splitter writes only mba.b00: mba.mdt is the ELF
# header plus the program headers of the original image.
python3 -I - "$src/stock/Windows/system32/qcdsp1v28974.mbn" "$fw/mba.mdt" "$fw/mba.b00" <<'PY'
import struct, sys
d = open(sys.argv[1], 'rb').read()
if d[:4] != b'\x7fELF':
    sys.exit('qcdsp1v28974.mbn is not an ELF image')
phoff, = struct.unpack_from('<I', d, 28)
phentsize, phnum = struct.unpack_from('<HH', d, 42)
seg = open(sys.argv[3], 'rb').read()
_, off, _, _, filesz = struct.unpack_from('<5I', d, phoff)
if phnum != 1 or d[off:off + filesz] != seg:
    sys.exit('mba.b00 does not match the single segment of qcdsp1v28974.mbn')
open(sys.argv[2], 'wb').write(d[:phoff + phentsize * phnum])
PY

# WCNSS binary configuration: qcwlan8974cfg.dat has the same format as
# Android's WCNSS_cfg.dat (magic 01 0c 03 0b), tuned for the board (on the
# 1520; same file name expected on the 930, TODO: confirm).
sys32="$src/stock/Windows/system32"
cp -p "$sys32/qcwlan8974cfg.dat" "$fw/wlan/prima/WCNSS_cfg.dat"

# Audio calibration (ACDB) of the phone, under the MTP names that
# libacdbloader opens on msm8974.
for a in Bluetooth Codec General Global Handset Hdmi Headset Speaker; do
	if [ -f "$sys32/${a}_cal_8974.acdb" ]; then
		cp -p "$sys32/${a}_cal_8974.acdb" \
			"$out/system/etc/acdbdata/MTP/MTP_${a}_cal.acdb"
	fi
done

(cd "$out" && find . -type f ! -name SHA256SUMS -printf '%P\n' | sort |
	xargs sha256sum > SHA256SUMS)
{
	echo "device: martini"
	echo "models: $models"
	echo "source: $src"
	echo "date: $(date -Iseconds)"
} > "$out/SOURCE"

echo "Copied $(($(wc -l < "$out/SHA256SUMS"))) files into $out"
