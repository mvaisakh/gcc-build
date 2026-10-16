#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali
set -e

echo "*****************************************"
echo "* Building Bare-Metal Bleeding Edge GCC *"
echo "*****************************************"

# Declare the number of jobs to run simultaneously
JOBS=$(nproc --all)

# TODO: Add more dynamic option handling
while getopts a:p: flag; do
  case "${flag}" in
    a) arch=${OPTARG} ;;
    p) PHASE=${OPTARG} ;;
    *) echo "Invalid argument passed" && exit 1 ;;
  esac
done

# TODO: Better target handling
case "${arch}" in
  "arm") TARGET="arm-eabi" ;;
  "arm64") TARGET="aarch64-elf" ;;
  "arm64gnu") TARGET="aarch64-linux-gnu" ;;
  "x86") TARGET="x86_64-elf" ;;
esac

# PGO Setup
export PGO_DIR="${PWD}/pgo-profiles-${arch}"

if [ "$PHASE" == "instrument" ]; then
    mkdir -p "$PGO_DIR"
    export PGO_FLAGS="-fprofile-generate=${PGO_DIR}"
    echo ">>> Running in INSTRUMENT phase. PGO data will go to: $PGO_DIR"

elif [ "$PHASE" == "optimize" ]; then
    export PGO_FLAGS="-fprofile-use=${PGO_DIR} -fprofile-correction -Wno-error"
    echo ">>> Running in OPTIMIZE phase. Using PGO data from: $PGO_DIR"

else
    export PGO_FLAGS=""
    echo ">>> Running in NORMAL phase (No PGO)."
fi

export WORK_DIR="$PWD"
export PREFIX="$WORK_DIR/gcc-${arch}"
export PATH="$PREFIX/bin:/usr/bin/core_perl:$PATH"
export OPT_FLAGS="-flto -flto-compression-level=10 -O3 -pipe -ffunction-sections -fdata-sections $PGO_FLAGS"

echo "Cleaning up previously cloned repos..."
rm -rf "$WORK_DIR"/{binutils,build-binutils,build-gcc,gcc}

echo "||                                                                    ||"
echo "|| Building Bare Metal Toolchain for ${arch} with ${TARGET} as target ||"
echo "||                                                                    ||"

download_resources() {
  echo "Downloading Pre-requisites"
  echo "Cloning binutils"
  git clone git://sourceware.org/git/binutils-gdb.git -b master binutils --depth=1
  sed -i '/^development=/s/true/false/' binutils/bfd/development.sh
  echo "Cloned binutils!"
  echo "Cloning GCC"
  git clone git://gcc.gnu.org/git/gcc.git -b master gcc --depth=1
  cd "${WORK_DIR}"
  echo "Downloaded prerequisites!"
}

build_binutils() {
  cd "${WORK_DIR}"
  echo "Building Binutils"
  mkdir build-binutils
  cd build-binutils
  env CFLAGS="$OPT_FLAGS" CXXFLAGS="$OPT_FLAGS" \
    ../binutils/configure --target="$TARGET" \
    --disable-docs \
    --disable-gdb \
    --disable-nls \
    --disable-werror \
    --enable-gold \
    --prefix="$PREFIX" \
    --with-pkgversion="Eva Binutils" \
    --with-sysroot
  make -j"$JOBS"
  make install -j"$JOBS"
  cd ../
  echo "Built Binutils, proceeding to next step...."
}

build_gcc() {
  cd "${WORK_DIR}"
  echo "Building GCC"
  cd gcc
  ./contrib/download_prerequisites
  echo "Bleeding Edge" > gcc/DEV-PHASE
  cd ../
  mkdir build-gcc
  cd build-gcc
  env CFLAGS="$OPT_FLAGS" CXXFLAGS="$OPT_FLAGS" \
    ../gcc/configure --target="$TARGET" \
    --disable-decimal-float \
    --disable-docs \
    --disable-gcov \
    --disable-libffi \
    --disable-libgomp \
    --disable-libmudflap \
    --disable-libquadmath \
    --disable-libstdcxx-pch \
    --disable-nls \
    --disable-shared \
    --enable-default-ssp \
    --enable-languages=c,c++,fortran \
    --enable-threads=posix \
    --prefix="$PREFIX" \
    --with-gnu-as \
    --with-gnu-ld \
    --with-headers="/usr/include" \
    --with-linker-hash-style=gnu \
    --with-newlib \
    --with-pkgversion="Eva GCC" \
    --with-sysroot

if [ "$PHASE" == "instrument" ]; then
    echo "Building GCC (Instrumented phase - skipping target libs)"
    make all-gcc -j"$JOBS"
    make install-gcc -j"$JOBS"
    echo "Built GCC for profiling"
else
    # If we are in the optimize or normal phase, build EVERYTHING!
    echo "Building GCC (Final phase - including target libs)"
    make all-gcc -j"$JOBS"
    make all-target-libgcc -j"$JOBS"
    make install-gcc -j"$JOBS"
    make install-target-libgcc -j"$JOBS"
    echo "Built GCC!"
fi
}

download_resources
build_binutils
build_gcc
