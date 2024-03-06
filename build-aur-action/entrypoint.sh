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
pacman -S nvchecker jq pacman-contrib --noconfirm

# 确定打包文件
if [ ! -d "$pkgname" ]; then
	git clone https://aur.archlinux.org/$pkgname.git
	chmod -R a+rw .
fi

cd "$pkgname" || exit

# Check 更新状态
status="false"

# 只利用 new_ver 来反应更新前后状态
newver_file=$(cat $vfile | grep -n "^newver" | awk -F '\"' '{print $2}')
echo "newver_file=$newver_file" >>$GITHUB_OUTPUT

data=$(nvchecker -t 3 --logger json -c $vfile)
oldver=$(echo $data | jq -r '.old_version')

newver=$(echo $data | jq -r '.version')
echo "newver=$newver" >>$GITHUB_OUTPUT

if [ "$oldver" != "$newver" ]; then
	status="true"

	# 用于后续 delete-asset
	old_asset=$(basename $(sudo -u builder makepkg --packagelist))
	echo "old_asset=$old_asset" >>$GITHUB_OUTPUT

	if ! grep -nq "^pkgver()" PKGBUILD; then
		sed -i "s/^pkgver=.*/pkgver=$newver/" PKGBUILD
	fi
	sudo -u builder updpkgsums
	sudo -u builder bash -c 'export MAKEFLAGS=j$(nproc) && makepkg -s --noconfirm'
	asset=$(basename $(sudo -u builder makepkg --packagelist))
	echo "asset=$asset" >>$GITHUB_OUTPUT
fi

echo "status=$status" >>$GITHUB_OUTPUT
