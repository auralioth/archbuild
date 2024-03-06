#!/bin/bash

repo_onwer=$1
repo_full=$2
path=$3

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

pacman-key --init

gh release download -p "$repo_onwer.db.tar.gz " -R $repo_full

cp $path/*/*.pkg.tar.zst ./
repo-add -R ./$repo_onwer.db.tar.gz ./*.pkg.tar.zst
for i in *.db *.files; do
	cp --remove-destination $(readlink $i) $i
done
