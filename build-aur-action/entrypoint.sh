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

oldver_file=$(cat $vfile | grep -n "^oldver" | awk -F '\"' '{print $2}')
newver_file=$(cat $vfile | grep -n "^newver" | awk -F '\"' '{print $2}')

data=$(nvchecker -t 3 --logger json -c $vfile)
event=$(echo $data | jq -r '.event')
level=$(echo $data | jq -r '.level')

if [ "$level" = "error" ]; then
	echo "::group::Nvchecker"
	echo "::error file=entrypoint.sh,line=39::nvchecker error"
	echo "::endgroup::"
	exit 1
fi

if [ "$event" = "up-to-date" ]; then
	echo "status=$status" >>$GITHUB_OUTPUT
	exit 0
fi

if [ "$event" = "updated" ]; then
	oldver=$(echo $data | jq -r '.old_version')
	newver=$(echo $data | jq -r '.version')
	cp $newver_file $oldver_file

	echo "newver=$newver" >>$GITHUB_OUTPUT

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

	echo "status=$status" >>$GITHUB_OUTPUT

	echo "commit_file=PKGBUILD $oldver_file $newver_file" >>$GITHUB_OUTPUT

	echo "asset=$asset" >>$GITHUB_OUTPUT

	exit 0
fi

echo "::group::Unknown"
echo "::error file=entrypoint.sh,line=77::something unknown happened"
echo "::endgroup::"
exit 1
