TARGET := iphone:clang:latest:15.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Larpgram

Larpgram_FILES = Tweak.x LarpgramConfig.m LarpgramSettingsViewController.m
Larpgram_CFLAGS = -fobjc-arc
Larpgram_FRAMEWORKS = UIKit Foundation
Larpgram_LDFLAGS = -Wl,-rpath,@executable_path/Frameworks -Wl,-rpath,@loader_path/Frameworks

include $(THEOS_MAKE_PATH)/tweak.mk
