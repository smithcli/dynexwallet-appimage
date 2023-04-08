SHELL := /bin/bash
app_release_url := curl -s https://api.github.com/repos/dynexcoin/Dynex-Wallet-App/releases/latest | grep 'browser_' | cut -d\" -f4 | grep tar
app_release_tar := $(shell $(app_release_url) | cut -d/ -f9)
appimage_builder_release := curl -s https://api.github.com/repos/AppImageCrafters/appimage-builder/releases/latest | grep 'browser_' | cut -d\" -f4 | grep -v zsync
appimage_builder = $(shell $(appimage_builder_release) | cut -d/ -f9)

build:
	@podman run --rm\
		--volume ./:/root \
		--workdir /root \
		--cap-add SYS_ADMIN \
		--device /dev/fuse \
		docker.io/library/ubuntu:22.04 /bin/bash -c '\
	echo -e "Running build inside Container:\n";\
	cat /etc/os-release;\
	echo -e "\n";\
	apt update -y;\
	# if downloading
	apt install wget curl xz-utils -y;\
	# building dependencies\
	apt install make fuse gtk-update-icon-cache -y;\
	make install;\
	make create-appimage;\
	'
download:
	mkdir downloads
	# appimage-builder
	wget $$($(appimage_builder_release)) -O downloads/appimage-builder
	# app binary
	wget $$($(app_release_url))
	tar -xJf $(app_release_tar)
	rm *.tar.xz
	mv dynexwallet downloads/

install:
	# build dependencies
	install -Dm755 downloads/appimage-builder /usr/bin/appimage-builder
	# app artifacts
	install -D downloads/dynexwallet AppDir/usr/bin/dynexwallet
	install -Dm644 icons/dynex_64.png AppDir/usr/share/icons/hicolor/64x64/apps/org.dynexcoin.dynex-wallet-app.png
	install -Dm644 icons/dynex_128.png AppDir/usr/share/icons/hicolor/128x128/apps/org.dynexcoin.dynex-wallet-app.png
	install -Dm644 icons/dynex_256.png AppDir/usr/share/icons/hicolor/256x256/apps/org.dynexcoin.dynex-wallet-app.png
	install -Dm644 icons/dynex_512.png AppDir/usr/share/icons/hicolor/512x512/apps/org.dynexcoin.dynex-wallet-app.png
	install -Dm644 org.dynexcoin.dynex-wallet-app.desktop -t AppDir/usr/share/applications
	# app dependencies
	apt install libboost-all-dev libcurl4-openssl-dev -y

create-appimage:
	appimage-builder

clean:
	rm -rf AppDir/ appimage-build/ .wget-hsts

.PHONY: build download install create-appimage clean
