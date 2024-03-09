#!/bin/bash

repo_owner=$INPUT_REPO_ONWER
repo_full=$INPUT_REPO_FULL
path=$INPUT_PATH

gh release download -p "$repo_onwer.db.tar.gz" -R $repo_full

repo-add -R $path/$repo_owner.db.tar.gz ./*.pkg.tar.zst
ls -l
for i in *.db *.files; do
	cp --remove-destination $(readlink $i) $i
done
