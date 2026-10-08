TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Larpgram

Larpgram_FILES = Tweak.m LarpgramConfig.m LarpgramSettingsViewController.m
Larpgram_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
Larpgram_FRAMEWORKS = UIKit Foundation
Larpgram_USE_SUBSTRATE = 0
Larpgram_LDFLAGS = -Wl,-rpath,@executable_path/Frameworks -Wl,-rpath,@loader_path/Frameworks

include $(THEOS_MAKE_PATH)/tweak.mk
