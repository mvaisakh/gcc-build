#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali
set -e

echo "***************************"
echo "* Building Integrated LLD *"
echo "***************************"

while getopts a: flag; do
  if [[ $flag == "a" ]]; then
    arch="$OPTARG"
    case "${OPTARG}" in
      "arm") ARCH_CLANG="ARM" && TARGET_CLANG="arm-linux-gnueabi" && TARGET_GCC="arm-eabi" ;;
      "arm64") ARCH_CLANG="AArch64" && TARGET_CLANG="aarch64-linux-gnu" && TARGET_GCC="aarch64-elf" ;;
      "x86") ARCH_CLANG="X86" && TARGET_CLANG="x86_64-linux-gnu" && TARGET_GCC="x86_64-elf" ;;
      *) echo "Invalid architecture passed: $OPTARG" && exit 1 ;;
    esac
  else
    echo "Invalid argument passed" && exit 1
  fi
done

# Let's keep this as is
export WORK_DIR="$PWD"
export PREFIX="./../gcc-${arch}"
export PATH="$PREFIX/bin:$PATH"

echo "Cleaning up previously cloned repos..."
rm -rf $WORK_DIR/llvm-project

echo "Building Integrated lld for ${arch} with ${TARGET_CLANG} as target"

download_resources() {
  echo ">"
  echo "> Downloading LLVM for LLD"
  echo ">"
  git clone https://github.com/llvm/llvm-project -b main llvm --depth=1
  cd "${WORK_DIR}"
}

build_lld() {
  cd "${WORK_DIR}"
  echo ">"
  echo "> Building LLD"
  echo ">"
  mkdir -p llvm/build
  cd llvm/build
  export INSTALL_LLD_DIR="../../../gcc-${arch}"
  cmake -G "Ninja" \
    -DLLVM_ENABLE_PROJECTS=lld \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_LLD_DIR" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET_CLANG" \
    -DLLVM_TARGET_ARCH="X86" \
    -DLLVM_TARGETS_TO_BUILD=$ARCH_CLANG \
    -DCMAKE_CXX_COMPILER="$(which clang++)" \
    -DCMAKE_C_COMPILER="$(which clang)" \
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
    -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc --all)" \
    -DLLVM_PARALLEL_LINK_JOBS="$(nproc --all)" \
    -DBUILD_SHARED_LIBS=Off \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
    -DCMAKE_C_FLAGS="-O3" \
    -DCMAKE_CXX_FLAGS="-O3" \
    -DLLVM_ENABLE_PIC=False \
    ../llvm
  ninja -j$(nproc --all)
  ninja -j$(nproc --all) install
  # Create proper symlinks
  cd "${INSTALL_LLD_DIR}"/bin
  ln -s lld ${TARGET_GCC}-ld.lld
  cd "${WORK_DIR}"
}

download_resources
build_lld
