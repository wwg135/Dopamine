.PHONY: all clean build_clean

all: Dopamine.tipa

Dopamine.tipa: build/Build/Products/Debug-iphoneos/Dopamine.app
	@echo Ad-Hoc signing Dopamine
	xattr -rc build/Build/Products/Debug-iphoneos/Dopamine.app
	ldid -SDopamine/Dopamine.entitlements build/Build/Products/Debug-iphoneos/Dopamine.app/Dopamine
	ldid -s build/Build/Products/Debug-iphoneos/Dopamine.app
	rm -rf Payload Dopamine.tipa
	mkdir Payload
	cp -r build/Build/Products/Debug-iphoneos/Dopamine.app Payload/Dopamine.app
	zip -Ar Dopamine.tipa Payload
	rm -rf Payload

build/Build/Products/Debug-iphoneos/Dopamine.app: FORCE
	xcodebuild -scheme Dopamine \
		-derivedDataPath build \
		-destination 'generic/platform=iOS' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		GCC_PREPROCESSOR_DEFINITIONS="GIT_COMMIT_HASH=`git describe --tags --abbrev=0`_`git rev-parse --short HEAD` \
			COMPILE_TIME=`TZ=UTC-8 date \"+%Y%m%d_%H%M%S\"` \
			BUNDLE_ID=page.liam.Dopamine.roothide"

clean:
	rm -rf build Payload Dopamine.tipa

build_clean:
	rm -rf Payload build

FORCE: ;
