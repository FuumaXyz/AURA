#!/bin/sh

echo "Installing"

# Install Node from Alpine v3.22 repositories
apk add --repository=https://dl-cdn.alpinelinux.org/alpine/v3.22/main --repository=https://dl-cdn.alpinelinux.org/alpine/v3.22/community nodejs npm --no-cache

# Install Chromium from Alpine v3.17 repositories
apk add --repository=https://dl-cdn.alpinelinux.org/alpine/v3.17/main --repository=https://dl-cdn.alpinelinux.org/alpine/v3.17/community chromium --no-cache

git clone https://github.com/FuumaXyz/AURA.git
cd AURA
bash aura.sh