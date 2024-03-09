#!/bin/bash

repo_onwer=$INPUT_REPO_ONWER
repo_full=$INPUT_REPO_FULL
path=$INPUT_PATH

pacman-key --init

gh release download -p "$repo_onwer.db.tar.gz" -R $repo_full

repo-add -R $path/$repo_onwer.db.tar.gz ./*.pkg.tar.zst
for i in *.db *.files; do
	cp --remove-destination $(readlink $i) $i
done
