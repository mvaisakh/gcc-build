#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali

echo "*****************************************"
echo "* Building Bare-Metal Bleeding Edge GCC *"
echo "*****************************************"

# TODO: Add more dynamic option handling
while getopts a: flag; do
  case "${flag}" in
    a) arch=${OPTARG} ;;
  esac
done

# TODO: Better target handling
case "${arch}" in
  "arm") TARGET="arm-eabi" ;;
  "arm64") TARGET="aarch64-elf" ;;
  "arm64gnu") TARGET="aarch64-linux-gnu" ;;
  "x86") TARGET="x86_64-elf" ;;
esac

export WORK_DIR="$PWD"
export PREFIX="$WORK_DIR/../gcc-${arch}"
export PATH="$PREFIX/bin:/usr/bin/core_perl:$PATH"

echo "||                                                                    ||"
echo "|| Building Bare Metal Toolchain for ${arch} with ${TARGET} as target ||"
echo "||                                                                    ||"

download_resources() {
  echo "Downloading Pre-requisites"
  echo "Cloning binutils"
  git clone git://sourceware.org/git/binutils-gdb.git -b master binutils --depth=1
  echo "Cloned binutils!"
  echo "Cloning GCC"
  git clone git://gcc.gnu.org/git/gcc.git -b master gcc --depth=1
  cd ${WORK_DIR}
  echo "Downloaded prerequisites!"
}

build_binutils() {
  cd ${WORK_DIR}
  echo "Building Binutils"
  mkdir build-binutils
  cd build-binutils
  ../binutils/configure --target=$TARGET \
    CFLAGS="-flto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
    CXXFLAGS="-flto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
    --disable-docs \
    --disable-gdb \
    --disable-mutlilib \
    --disable-nls \
    --disable-werror \
    --enable-gold \
    --prefix="$PREFIX" \
    --with-pkgversion="Eva Binutils" \
    --with-sysroot
  make -j$(($(nproc --all) + 2))
  make install -j$(($(nproc --all) + 2))
  cd ../
  echo "Built Binutils, proceeding to next step...."
}

build_gcc() {
  cd ${WORK_DIR}
  echo "Building GCC"
  cd gcc
  ./contrib/download_prerequisites
  echo "Bleeding Edge" > gcc/DEV-PHASE
  cd ../
  mkdir build-gcc
  cd build-gcc
  ../gcc/configure --target=$TARGET \
    CFLAGS="-flto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
    CXXFLAGS="-flto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections" \
    --disable-decimal-float \
    --disable-docs \
    --disable-gcov \
    --disable-libffi \
    --disable-libgomp \
    --disable-libmudflap \
    --disable-libquadmath \
    --disable-libstdcxx-pch \
    --disable-mutlilib \
    --disable-nls \
    --disable-shared \
    --enable-default-ssp \
    --enable-languages=c,c++ \
    --enable-threads=posix \
    --prefix="$PREFIX" \
    --with-gnu-as \
    --with-gnu-ld \
    --with-headers="/usr/include" \
    --with-linker-hash-style=gnu \
    --with-newlib \
    --with-pkgversion="Eva GCC" \
    --with-sysroot

  make all-gcc -j$(($(nproc --all) + 2))
  make all-target-libgcc -j$(($(nproc --all) + 2))
  make install-gcc -j$(($(nproc --all) + 2))
  make install-target-libgcc -j$(($(nproc --all) + 2))
  echo "Built GCC!"
}

download_resources
build_binutils
build_gcc
