#!/bin/bash

repo_owner=$INPUT_REPO_OWNER
repo_full=$INPUT_REPO_FULL
path=$INPUT_PATH
request=$INPUT_REQUEST
remove_pkgs=$INPUT_REMOVE_PKGS

assets=$(gh release view --json assets | jq -r '.assets[].name')

if [[ ${assets} =~ "$repo_owner.db.tar.gz" && ${assets} =~ "$repo_owner.files.tar.gz" ]]; then
	gh release download -p "$repo_owner.db.tar.gz" -R $repo_full -D $path
	gh release download -p "$repo_owner.files.tar.gz" -R $repo_full -D $path
else
	exit 0
fi

if [ $request = "add" ]; then
	repo-add -R $path/$repo_owner.db.tar.gz ./*.pkg.tar.zst
	for i in *.db *.files; do
		cp --remove-destination $(readlink $i) $i
	done
fi

if [ $request = "remove" ]; then
	repo-remove $path/$repo_owner.db.tar.gz $remove_pkgs
	for i in *.db *.files; do
		cp --remove-destination $(readlink $i) $i
	done
fi
