#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali
set -e

echo "***************************"
echo "* Building Integrated LLD *"
echo "***************************"

# TODO: Add more dynamic option handling
while getopts a: flag; do
  case "${flag}" in
    a) arch=${OPTARG} ;;
  esac
done

# TODO: Better handling of arguments
case "${arch}" in
  "arm") ARCH_CLANG="ARM" ;;
  "arm64") ARCH_CLANG="AArch64" ;;
  "x86") ARCH_CLANG="x86-64" ;;
esac

case "${ARCH_CLANG}" in
  "ARM") TARGET_CLANG="arm-linux-gnueabi" ;;
  "AArch64") TARGET_CLANG="aarch64-linux-gnu" ;;
  "x86-64") TARGET_CLANG="x86_64-linux-gnu" ;;
esac

case "${ARCH_CLANG}" in
  "ARM") TARGET_GCC="arm-eabi" ;;
  "AArch64") TARGET_GCC="aarch64-elf" ;;
  "x86-64") TARGET_GCC="x86_64-elf" ;;
esac

# Let's keep this as is
export WORK_DIR="$PWD"
export PREFIX="./../gcc-${arch}"
export PATH="$PREFIX/bin:$PATH"

echo "Building Integrated lld for ${arch} with ${TARGET} as target"

download_resources() {
  echo ">"
  echo "> Downloading LLVM for LLD"
  echo ">"
  git clone https://github.com/llvm/llvm-project -b main llvm --depth=1
  cd ${WORK_DIR}
}

build_lld() {
  cd ${WORK_DIR}
  echo ">"
  echo "> Building LLD"
  echo ">"
  mkdir -p llvm/build
  cd llvm/build
  export INSTALL_LLD_DIR="../../../gcc-${arch}"
  cmake -G "Ninja" \
    -DLLVM_ENABLE_PROJECTS=lld \
    -DCMAKE_CROSSCOMPILING=True \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_LLD_DIR" \
    -DLLVM_DEFAULT_TARGET_TRIPLE=$TARGET_CLANG \
    -DLLVM_TARGET_ARCH=$ARCH_CLANG \
    -DLLVM_TARGETS_TO_BUILD=$ARCH_CLANG \
    -DCMAKE_CXX_COMPILER="$(which clang++)" \
    -DCMAKE_C_COMPILER=$(which clang) \
    -DLLVM_OPTIMIZED_TABLEGEN=True \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_ENABLE_LTO=Full \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_BUILD_RUNTIME=Off \
    -DLLVM_INCLUDE_TESTS=Off \
    -DLLVM_INCLUDE_EXAMPLES=Off \
    -DLLVM_INCLUDE_BENCHMARKS=Off \
    -DLLVM_ENABLE_MODULES=Off \
    -DLLVM_ENABLE_BACKTRACES=Off \
    -DLLVM_PARALLEL_COMPILE_JOBS=$(nproc) \
    -DLLVM_PARALLEL_LINK_JOBS=$(nproc) \
    -DBUILD_SHARED_LIBS=Off \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
    -DCMAKE_C_FLAGS="-O3" \
    -DCMAKE_CXX_FLAGS="-O3" \
    -DLLVM_ENABLE_PIC=False \
    ../llvm
  ninja
  ninja install
  # Create proper symlinks
  cd ${INSTALL_LLD_DIR}/bin
  ln -s lld ${TARGET_GCC}-ld.lld
  cd ${WORK_DIR}
}

download_resources
build_lld
