#!/bin/bash

repo_onwer=$1
path=$2

useradd builder -m
echo "builder ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
chmod -R a+rw .

pacman-key --init

cp $path/*/*.pkg.tar.zst ./
repo-add ./$repo_onwer.db.tar.gz ./*.pkg.tar.zst
for i in *.db *.files; do
  cp --remove-destination $(readlink $i) $i
done
