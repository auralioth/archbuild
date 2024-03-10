#!/bin/bash

repo_owner=$INPUT_REPO_OWNER
repo_full=$INPUT_REPO_FULL
path=$INPUT_PATH

gh release download -p "$repo_owner.db.tar.gz" -R $repo_full -D $path

repo-add -R $path/$repo_owner.db.tar.gz ./*.pkg.tar.zst
for i in *.db *.files; do
	cp --remove-destination $(readlink $i) $i
done
