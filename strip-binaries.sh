#!/bin/bash

CUR_DIR=$(pwd)

curl -LSsO "https://github.com/kdrag0n/proton-clang/raw/master/bin/strip"
chmod +x "$CUR_DIR/strip"
X86_STRIP="$CUR_DIR/strip"
find "$CUR_DIR" -type f -exec file {} \; \
    | grep "x86" | grep "not strip" | grep -v "relocatable" \
	| tr ':' ' ' | awk '{print $1}' \
	| while read -r file; do $X86_STRIP "$file"; done && rm "$CUR_DIR/strip"

curl -LSsO "https://github.com/kdrag0n/proton-clang/raw/master/bin/aarch64-linux-gnu-strip"
chmod +x "$CUR_DIR/aarch64-linux-gnu-strip"
ARM64_STRIP="$CUR_DIR/aarch64-linux-gnu-strip"
find "$CUR_DIR" -type f -exec file {} \; \
    | grep "ARM" | grep "aarch64" | grep "not strip" | grep -v "relocatable" \
	| tr ':' ' ' | awk '{print $1}' \
	| while read -r file; do $ARM64_STRIP "$file"; done && rm "$CUR_DIR/aarch64-linux-gnu-strip"

curl -LSsO "https://github.com/kdrag0n/proton-clang/raw/master/bin/arm-linux-gnueabi-strip"
chmod +x "$CUR_DIR/arm-linux-gnueabi-strip"
ARM32_STRIP="$CUR_DIR/arm-linux-gnueabi-strip"
find "$CUR_DIR" -type f -exec file {} \; \
    | grep "ARM" | grep "32.bit" | grep "not strip" | grep -v "relocatable" \
	| tr ':' ' ' | awk '{print $1}' \
	| while read -r file; do $ARM32_STRIP "$file"; done && rm "$CUR_DIR/arm-linux-gnueabi-strip"
