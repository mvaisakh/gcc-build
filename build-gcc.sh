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
  "arm64") TARGET="aarch64-linux-gnu" ;;
  "x86") TARGET="x86_64-linux-gnu" ;;
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
    --prefix="$PREFIX" \
    --with-sysroot \
    --disable-nls \
    --disable-docs \
    --disable-werror \
    --disable-gdb \
    --enable-gold
  make CFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" CXXFLAGS="-flto -O3 -pipe -ffunction-sections -fdata-sections" -j$(($(nproc --all) + 2))
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
  
    # Do not run fixincludes
  sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
  
  cd ../
  mkdir build-gcc
  cd build-gcc
  
  # using -pipe causes spurious test-suite failures
  # http://gcc.gnu.org/bugzilla/show_bug.cgi?id=48565
  CFLAGS=${CFLAGS/-pipe/}
  CXXFLAGS=${CXXFLAGS/-pipe/}
  
  ../gcc/configure --target=$TARGET \
    --prefix="$PREFIX" \
    --program-prefix=$TARGET- \
    --with-local-prefix=/usr/$TARGET \
    --with-sysroot=/usr/$TARGET \
    --with-build-sysroot=/usr/$TARGET \
    --with-native-system-header-dir=/include \
    --disable-nls --enable-default-pie \
    --enable-languages=c,c++,fortran \
    --enable-shared --enable-threads=posix \
    --with-system-zlib --with-isl --enable-__cxa_atexit \
    --disable-libunwind-exceptions --enable-clocale=gnu \
    --disable-libstdcxx-pch --disable-libssp \
    --enable-gnu-unique-object --enable-linker-build-id \
    --enable-lto --enable-plugin --enable-install-libiberty \
    --with-linker-hash-style=gnu --enable-gnu-indirect-function \
    --disable-multilib --disable-werror \
    --enable-checking=release


  make all-gcc -j$(($(nproc --all) + 2))
  make all-target-libgcc -j$(($(nproc --all) + 2))
  make install-gcc -j$(($(nproc --all) + 2))
  make install-target-libgcc -j$(($(nproc --all) + 2))
  echo "Built GCC!"
}

download_resources
build_binutils
build_gcc
