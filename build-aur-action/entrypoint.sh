#!/bin/bash

# 变量
pkgname=$1
vfile=$2

# 初始化
useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

cat <<EOM >>/etc/pacman.conf
[multilib]
Include = /etc/pacman.d/mirrorlist
EOM

pacman-key --init
pacman -Syu --noconfirm
pacman -S nvchecker --noconfirm

# 确定打包文件
if [ ! -d "$pkgname" ]; then
	git clone https://aur.archlinux.org/$pkgname.git
	chmod -R a+rw .
fi

cd "$pkgname" || exit

# 用于后续 delete-asset
old_asset=$(basename $(sudo -u builder makepkg --packagelist))

# Check 更新状态
status="false"
output=$(source PKGBUILD && declare -p pkgver || :)
pattern='declare -- pkgver="([^"]+)"'

if [[ $output =~ $pattern ]]; then
	pkgver="${BASH_REMATCH[1]}"
fi

newver=$(nvchecker -t 3 --logger json -c $vfile | jq -r '.version')

if [ "$pkgver" != "$newver" ]; then
	status="true"
	if ! grep -nq "^pkgver()" PKGBUILD; then
		sed -i "s/pkgver=$pkgver/pkgver=$newver/" PKGBUILD
	fi
	updpkgsums
	sudo -u builder bash -c 'export MAKEFLAGS=j$(nproc) && makepkg -s --noconfirm'
fi

asset=$(basename $(sudo -u builder makepkg --packagelist))

echo "old_asset=$old_asset" >>$GITHUB_OUTPUT
echo "status=$status" >>$GITHUB_OUTPUT
echo "asset=$asset" >>$GITHUB_OUTPUT
echo "newver=$newver" >>$GITHUB_OUTPUT
