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

# Code signing disabled (jailbroken device, installed via Filza)
_THEOS_CODESIGN_DEFAULT_DISABLE_ = YES
YandexMusic_CODESIGN_FLAGS =

include $(THEOS_MAKE_PATH)/application.mk
