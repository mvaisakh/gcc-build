#!/bin/bash

CUR_DIR=$(pwd)
X86S=$(which strip)
A64S=$(which aarch64-linux-gnu-strip)
A32S=$(which arm-linux-gnu-strip)

find "$CUR_DIR" -type f -exec file {} \; >.file-idx

grep "x86" .file-idx |
	grep "not strip" | grep -v "relocatable" |
	tr ':' ' ' | awk '{print $1}' |
	while read -r file; do $X86S "$file"; done

grep "ARM" .file-idx | grep "aarch64" |
	grep "not strip" | grep -v "relocatable" |
	tr ':' ' ' | awk '{print $1}' |
	while read -r file; do $A64S "$file"; done

grep "ARM" .file-idx | grep "32.bit" |
	grep "not strip" | grep -v "relocatable" |
	tr ':' ' ' | awk '{print $1}' |
	while read -r file; do $A32S "$file"; done

rm ".file-idx"
