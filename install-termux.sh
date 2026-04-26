#!/bin/sh

echo "INSTALLING AURA"
apt -yq update
apt -yq upgrade
pkg install nodejs -y
pkg install wget -y
pkg install unzip -y
pkg install git -y
pkg install -yq proot-distro
proot-distro install alpine
proot-distro login alpine
