include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouTubeHDUnlocker
$(TWEAK_NAME)_FILES = /mnt/d/codes/youtubehdunlocker/Tweak.xm

$(TWEAK_NAME)_FRAMEWORKS = CydiaSubstrate

$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv6 armv7 armv7s arm64 arm64e
$(TWEAK_NAME)_ARCHS = armv6 armv7 armv7s arm64 arm64e

include $(THEOS_MAKE_PATH)/tweak.mk
