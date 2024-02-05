#!/bin/bash

pkgname=$1
repo_full=$2

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

pacman-key --init
pacman -Syu --noconfirm
if [ -n "$INPUT_PREINSTALLPKGS" ]; then
	pacman -Syu --noconfirm "$INPUT_PREINSTALLPKGS"
fi

if [ ! -d "$pkgname" ]; then
	git clone https://aur.archlinux.org/$pkgname.git
	chmod -R a+rw .
fi

cd "$pkgname" || exit
status="true"
gh release download -p "$pkgname-[0-9r]*pkg.tar.zst" -R $repo_full
sudo -u builder makepkg -od --noprepare -A
sudo -u builder bash -c 'export MAKEFLAGS=j$(nproc) && makepkg -s --noconfirm' || status=$?
asset=$(basename $(sudo -u builder makepkg --packagelist))
new_ver=$(grep -oP 'pkgver=\K[^ ]+' PKGBUILD)
echo "status=$status" >>$GITHUB_OUTPUT
echo "asset=$asset" >>$GITHUB_OUTPUT
echo "new_ver=$new_ver" >>$GITHUB_OUTPUT
