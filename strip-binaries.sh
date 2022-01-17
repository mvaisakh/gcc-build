#!/bin/bash

CUR_DIR=$(pwd)
PROTON="https://github.com/kdrag0n/proton-clang/raw/master/bin"
A64S=aarch64-linux-gnu-strip && A32S=arm-linux-gnueabi-strip

curl -LSsO "$PROTON/strip" && chmod +x "$CUR_DIR/strip" && X86_STRIP="$CUR_DIR/strip"
curl -LSsO "$PROTON/$A64S" && chmod +x "$CUR_DIR/$A64S" && A64_STRIP="$CUR_DIR/$A64S"
curl -LSsO "$PROTON/$A32S" && chmod +x "$CUR_DIR/$A32S" && A32_STRIP="$CUR_DIR/$A32S"

find "$CUR_DIR" -type f -exec file {} \; > .file-idx

grep "x86" .file-idx \
    | grep "not strip" | grep -v "relocatable" \
    | tr ':' ' ' | awk '{print $1}' \
    | while read -r file; do $X86_STRIP "$file"; done

grep "ARM" .file-idx | grep "aarch64" \
    | grep "not strip" | grep -v "relocatable" \
    | tr ':' ' ' | awk '{print $1}' \
    | while read -r file; do $A64_STRIP "$file"; done

grep "ARM" .file-idx | grep "32.bit" \
    | grep "not strip" | grep -v "relocatable" \
    | tr ':' ' ' | awk '{print $1}' \
    | while read -r file; do $A32_STRIP "$file"; done

rm "$CUR_DIR/strip" "$CUR_DIR/$A64S" "$CUR_DIR/$A32S" ".file-idx"
