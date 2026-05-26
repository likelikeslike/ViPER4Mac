PROJECT    := ViPER4Mac.xcodeproj
CONFIG     := Release
ARCH       := arm64
BUILD_DIR  := build/$(CONFIG)

APP_NAME   := ViPER4Mac.app
APP_SRC    := $(BUILD_DIR)/$(APP_NAME)
APP_DST    := /Applications/$(APP_NAME)

VERSION            := 1.1.0
DSP_VERSION_CODE   := 20260526
DSP_VERSION_NAME   := 1.1.0

.PHONY: all build install uninstall clean

all: build

build:
	xcodebuild -project $(PROJECT) -target ViPERDSP -configuration $(CONFIG) \
		build ONLY_ACTIVE_ARCH=YES ARCHS=$(ARCH) BUILD_DIR=$(CURDIR)/build
	xcodebuild -project $(PROJECT) -target ViPER4Mac -configuration $(CONFIG) \
		build MARKETING_VERSION=$(VERSION) ONLY_ACTIVE_ARCH=YES ARCHS=$(ARCH) BUILD_DIR=$(CURDIR)/build \
		OTHER_CFLAGS='-DVIPER_VERSION_CODE=$(DSP_VERSION_CODE) -DVIPER_VERSION_NAME=\"$(DSP_VERSION_NAME)\"'

install: build
	@echo "Installing ViPER4Mac..."
	-osascript -e 'tell application "ViPER4Mac" to quit' 2>/dev/null
	@sleep 1
	sudo rm -rf $(APP_DST)
	sudo cp -R $(APP_SRC) $(APP_DST)
	open $(APP_DST)
	@echo "Done."

uninstall:
	@echo "Uninstalling ViPER4Mac..."
	-osascript -e 'tell application "ViPER4Mac" to quit' 2>/dev/null
	@sleep 1
	-sudo rm -rf $(APP_DST)
	@echo "Done."

clean:
	rm -rf build

format:
	swiftformat ViPER4Mac --swift-version 5
