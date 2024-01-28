#!/bin/bash

pkgname=$1
repo_full=$2
tag=$3

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

pacman-key --init

assets=($(gh release view -R $repo_full --json assets | jq -cr '.assets[].name' | grep -o "^$pkgname-[0-9r].*pkg.tar.zst" | awk {print}))
if [ ${#assets[@]} -gt 0 ]; then
	for asset in "${assets[@]}"; do
		echo "Deleting asset: $asset"
		gh release delete-asset $tag $asset -R $repo_full -y
	done
else
	echo "No asset found matching the pattern."
fi
