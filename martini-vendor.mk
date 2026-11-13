#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Nokia Lumia 930 (martini) proprietary files.
#
# 1. Firmware and calibration of the 930 (ADSP, modem + MBA, WCNSS, Venus,
#    Wi-Fi config, audio ACDB), as on the Lumia 950 XL vendor: the ROM zip is
#    self-sufficient. Two places, same layout:
#      proprietary-local/  extracted by extract-local.sh from the user's own
#                          phone; ignored by git; listed first, so it wins
#      proprietary/        committed, from the Windows driver package
#                          DEVICE.SOC_QC8974.MARTINI (see README and SOURCE)
#    The tree mirrors the install paths:
#      .../vendor/...  -> $(TARGET_COPY_OUT_VENDOR)/...
#      .../system/...  -> $(TARGET_COPY_OUT_SYSTEM)/...
#    PRODUCT_COPY_FILES keeps the first entry for a destination, so these win
#    over the generic files of the device tree. Phone-specific data (MAC
#    addresses, Wi-Fi calibration from DPP, modem EFS) is never here: the
#    installer copies it from the phone into persist and the modem partitions.
#
# 2. Camera: the 2014 mm-camera2 daemon, its modules and the C2D/CPP/JPEG
#    blobs of the OnePlus One (TheMuppets' proprietary_vendor_oneplus, bacon,
#    lineage-18.1), with the sensor list of libmmcamera2_sensor_modules.so
#    renamed to karma/skyphd (kit/camera/patch-sensor-list-bacon.py in the
#    workspace); the Karma module tuning (libchromatix_karma_*) and the
#    lumia-ois-<module>.bin focus/OIS firmware of the rear module. The sensor
#    and actuator plug-ins and the HAL are built from source.
#
# 3. Generic MSM8974 Android blobs (Adreno, QMI/RIL, location, ...) come
#    from TheMuppets' proprietary_vendor_oppo (msm8974-common), minus the
#    OnePlus One firmware that does not belong on the 930.

define martini-proprietary
$(foreach f,$(filter $(1)/vendor/%,$(2)), \
    $(f):$(TARGET_COPY_OUT_VENDOR)/$(patsubst $(1)/vendor/%,%,$(f))) \
$(foreach f,$(filter $(1)/system/%,$(2)), \
    $(f):$(TARGET_COPY_OUT_SYSTEM)/$(patsubst $(1)/system/%,%,$(f)))
endef

martini-files = $(wildcard \
    $(1)/vendor/firmware/*.mdt \
    $(1)/vendor/firmware/*.b[0-9][0-9] \
    $(1)/vendor/firmware/wlan/prima/* \
    $(1)/vendor/firmware/cpp_firmware_*.fw \
    $(1)/vendor/firmware/lumia-ois-*.bin \
    $(1)/vendor/bin/mm-qcamera-daemon \
    $(1)/vendor/lib/*.so \
    $(1)/system/etc/acdbdata/MTP/*.acdb)

MARTINI_LOCAL_PATH := vendor/nokia/martini/proprietary-local
MARTINI_PROPRIETARY_PATH := vendor/nokia/martini/proprietary

PRODUCT_COPY_FILES += \
    $(call martini-proprietary,$(MARTINI_LOCAL_PATH),$(call martini-files,$(MARTINI_LOCAL_PATH))) \
    $(call martini-proprietary,$(MARTINI_PROPRIETARY_PATH),$(call martini-files,$(MARTINI_PROPRIETARY_PATH)))

# Generic MSM8974 blobs. Venus (video codec) firmware of the OnePlus One is
# dropped: the 930 uses its own qcvss8974 image (venus.* above).
include vendor/oppo/msm8974-common/msm8974-common-vendor.mk

MARTINI_OPPO_FW := vendor/oppo/msm8974-common/proprietary/vendor/firmware
PRODUCT_COPY_FILES := $(filter-out $(MARTINI_OPPO_FW)/venus.%,$(PRODUCT_COPY_FILES))
