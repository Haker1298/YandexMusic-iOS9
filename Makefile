TARGET := iphone:clang:latest:9.0
ARCHS = armv7 arm64
INSTALL_TARGET_PROCESSES = YandexMusic

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = YandexMusic

YandexMusic_FILES = main.mm \
        AppDelegate.mm \
        WebViewController.mm \
        AudioPlayer.mm \
        OAuthViewController.mm \
        KeychainHelper.mm \
        MiniPlayerView.mm

YandexMusic_FRAMEWORKS = UIKit \
        WebKit \
        AVFoundation \
        CoreMedia \
        AudioToolbox \
        Security \
        CoreGraphics \
        Foundation

YandexMusic_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
YandexMusic_OBJCFLAGS = -fobjc-arc -Wno-deprecated-declarations

YandexMusic_RESOURCE_DIRS = resources

YandexMusic_LDFLAGS = -weak_framework WebKit

# Code signing for sideloading (Sideloadly/AltStore will re-sign)
YandexMusic_CODESIGN_FLAGS = --sign "-" --entitlements entitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
