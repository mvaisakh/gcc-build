#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali

echo "******************************"
echo "* Building Bleeding Edge GCC *"
echo "******************************"

# TODO: Add more dynamic option handling
while getopts a: flag
do
    case "${flag}" in
        a) arch=${OPTARG};;
    esac
done

# TODO: Better target handling
case "${arch}" in
    "arm") TARGET="arm-eabi" ;;
    "arm64") TARGET="aarch64-elf" ;;
    "x86") TARGET="x86_64-elf" ;;
esac

export WORK_DIR="$PWD"
export PREFIX="$PWD/../gcc-${arch}"
export PATH="$PREFIX/bin:$PATH"

echo "Building Bare Metal Toolchain for ${arch} with ${TARGET} as target"

download_resources () {
    echo "Downloading Pre-requisites"
    git clone git://sourceware.org/git/binutils-gdb.git -b master binutils --depth=1
    git clone https://git.linaro.org/toolchain/gcc.git -b master gcc --depth=1
    cd ${WORK_DIR}
}

build_binutils () {
    cd ${WORK_DIR}
    echo "Building Binutils"
    mkdir build-binutils
    cd build-binutils
    ../binutils/configure --target=$TARGET \
                          --prefix="$PREFIX" \
                          --with-sysroot \
                          --disable-nls \
                          --disable-docs \
                          --disable-werror \
                          --disable-gdb \
                          --enable-gold \
                          --with-pkgversion="Custom BinUtils"
    make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" -j$(nproc --all)
    make install -j$(nproc --all)
    cd ../
}

build_gcc () {
    cd ${WORK_DIR}
    echo "Building GCC"
    cd gcc
    ./contrib/download_prerequisites
    cd ../
    mkdir build-gcc
    cd build-gcc
    ../gcc/configure --target=$TARGET \
                     --prefix="$PREFIX" \
                     --enable-decimal-float \
                     --disable-libffi \
                     --disable-libgomp \
                     --disable-libmudflap \
                     --disable-libquadmath \
                     --disable-libstdcxx-pch \
                     --disable-nls \
                     --disable-shared \
                     --disable-docs \
                     --enable-default-ssp \
                     --enable-languages=c,c++ \
                     --with-pkgversion="Eva GCC (69 Member SE)" \
                     --with-newlib \
                     --with-gnu-as \
                     --with-gnu-ld \
                     --with-sysroot
    make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" all-gcc -j$(nproc --all)
    make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" all-target-libgcc -j$(nproc --all)
    make install-gcc -j$(nproc --all)
    make install-target-libgcc -j$(nproc --all)
}

download_resources
build_binutils
build_gcc
