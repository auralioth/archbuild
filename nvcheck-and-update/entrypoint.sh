#!/bin/bash

nvfile=$INPUT_NVFILE
changed_files=$INPUT_CHANGED_FILES

# 初始化
# useradd builder -m
# echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
# chmod -R a+rw .

# cat <<EOM >>/etc/pacman.conf
# [multilib]
# Include = /etc/pacman.d/mirrorlist
# EOM

pacman -Syu --noconfirm
pacman -S jq pacman-contrib nvchecker --noconfirm

oldver_file=$(cat $nvfile | grep -n "^oldver" | awk -F '\"' '{print $2}')
# newver_file=$(cat $nvfile | grep -n "^newver" | awk -F '\"' '{print $2}')

levels=(warning warn error exception critical)
keys=(name old_version version event level)

data=$(nvchecker -t 3 --logger json -c $nvfile)

packages_need_update=()
versions=()

echo "$data" | jq -c '.' | while read -r group; do
	for key in "${keys[@]}";
	do
		declare "$key=$(echo "$group" | jq -r ".${key}")"
	done

	if [[ "${levels[@]}" =~ "${level}" ]]; then
		echo "::group::Nvchecker"
		echo "::error file=entrypoint.sh,line=27, endline=38, title=${name}::nvchecker error"
		echo "::endgroup::"
		exit 1
	fi

	if [ "$event" = "up-to-date" ]; then
		continue
	fi

	if comm -12 <(find "$name" -type f | sort) <(echo "$changed_files" | tr ' ' '\n' | sort) | grep -q .; then
        file_changed="true"
	else
		file_changed="false"
	fi

	if [ "$event" = "updated" ] || [ "$file_changed" = "true" ]; then
		
		packages_need_update+=($name)
		packages_newvers+=($version)

		nvtake -ignore-nonexistent -c $nvfile $name

		# 用于后续 delete-asset
		# old_pkgver=$(cat PKGBUILD | grep -n "^pkgver=" | awk -F= '{print $2}')

		# if ! grep -nq "^pkgver()" $name/PKGBUILD; then
		# 	sed -i "s/^pkgver=.*/pkgver=$version/" $name/PKGBUILD
		# fi
		# sudo -u builder updpkgsums
		# sudo -u builder bash -c 'export MAKEFLAGS=j$(nproc) && makepkg -s --noconfirm'
		# asset=$(basename $(sudo -u builder makepkg --packagelist))

		# echo "status=$status" >>$GITHUB_OUTPUT

		# echo "commit_file=$pkgname/PKGBUILD $pkgname/$oldver_file $pkgname/$newver_file" >>$GITHUB_OUTPUT

		# echo "asset=$asset" >>$GITHUB_OUTPUT
	fi
done

if [ ${#packages_need_update[@]} -eq 0 ]; then
	echo "status=false" >>$GITHUB_OUTPUT
else
	echo "status=true" >>$GITHUB_OUTPUT
	
	# matrix="{\"pkg\": ["
	# for package in "${packages_need_update[@]}"; do
	# matrix="${matrix}\"$package\", "
	# done
	# matrix="${matrix%, }]}"
	# echo "matrix=${matrix}" >> $GITHUB_OUTPUT

	matrix="{\"include\": ["
	for ((i=0; i<${#packages_need_update[@]}; i++)); do
	matrix="${matrix}{\"pkg\": \"${packages_need_update[i]}\", \"version\": \"${versions[i]}\"}"
	if [ $i -lt $(( ${#packages[@]} - 1 )) ]; then
		matrix="${matrix}, "
	fi
	done
	matrix="${matrix}]}"
	echo "matrix=${matrix}" >> $GITHUB_OUTPUT

	echo "oldver_file=$oldver_file" >>$GITHUB_OUTPUT
fi