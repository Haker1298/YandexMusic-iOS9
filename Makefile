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

# Copy Info.plist into .app bundle (Theos doesn't include it)
after-stage::
	@cp YandexMusic.plist $(THEOS_STAGING_DIR)/Applications/YandexMusic.app/Info.plist
	@echo "[OK] Info.plist copied to app bundle"

# Repack .deb with gzip for iOS 9 dpkg compatibility (lzma not supported)
after-package::
	@cd $(THEOS_PACKAGE_DIR) && \
		ar x $(THEOS_PACKAGE_NAME).deb && \
		lzma -dk data.tar.lzma && \
		rm -f data.tar.lzma && \
		gzip -f data.tar && \
		ar r $(THEOS_PACKAGE_NAME).deb debian-binary control.tar.gz data.tar.gz && \
		rm -f data.tar.gz && \
		echo "[OK] Repacked .deb with gzip for iOS 9"

include $(THEOS_MAKE_PATH)/application.mk
