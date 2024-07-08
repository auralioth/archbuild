#!/bin/bash

repo_owner=$INPUT_REPO_OWNER
repo_full=$INPUT_REPO_FULL
path=$INPUT_PATH
request=$INPUT_REQUEST
remove_pkgs=$INPUT_REMOVE_PKGS

if gh release download -p "$repo_owner.db.tar.gz" -R $repo_full -D $path; then
  echo "db.tar.gz exists. Download $repo_owner.db.tar.gz"
fi

if gh release download -p "$repo_owner.files.tar.gz" -R $repo_full -D $path; then
  echo "files.tar.gz exists. Download $repo_owner.files.tar.gz"
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
