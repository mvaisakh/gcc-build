#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali
set -Eeuo pipefail

echo "***************************"
echo "* Building Integrated LLD *"
echo "***************************"

print_usage() {
  cat <<'EOF'
Usage: ./build-lld.sh -a <arch> [-h]

Supported architectures:
  arm       -> arm-linux-gnueabi
  arm64     -> aarch64-linux-gnu
  riscv64   -> riscv64-linux-gnu
  x86       -> x86_64-linux-gnu
EOF
}

error() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

check_dependencies() {
  local deps=(git cmake ninja clang clang++ make)
  for dep in "${deps[@]}"; do
    require_command "$dep"
  done
}

arch=""
while getopts "a:h" flag; do
  case "${flag}" in
    a) arch="${OPTARG}" ;;
    h) print_usage; exit 0 ;;
    *) print_usage >&2; exit 1 ;;
  esac
done

[ -n "${arch}" ] || error "An architecture must be provided with -a. Use -h for help."

case "${arch}" in
  "arm") ARCH_CLANG="ARM" && TARGET_CLANG="arm-linux-gnueabi" && TARGET_GCC="arm-eabi" ;;
  "arm64") ARCH_CLANG="AArch64" && TARGET_CLANG="aarch64-linux-gnu" && TARGET_GCC="aarch64-elf" ;;
  "riscv64") ARCH_CLANG="RISCV" && TARGET_CLANG="riscv64-linux-gnu" && TARGET_GCC="riscv64-elf" ;;
  "x86") ARCH_CLANG="X86" && TARGET_CLANG="x86_64-linux-gnu" && TARGET_GCC="x86_64-elf" ;;
  *) error "Unsupported architecture '${arch}'. Supported values: arm, arm64, riscv64, x86" ;;
esac

# Let's keep this as is
export WORK_DIR="$(pwd)"
export PREFIX="${WORK_DIR}/gcc-${arch}"
export PATH="$PREFIX/bin:$PATH"

check_dependencies

echo "Cleaning up previously cloned repos..."
rm -rf -- "${WORK_DIR}"/llvm-project

echo "Building Integrated lld for ${arch} with ${TARGET_CLANG} as target"

download_resources() {
  echo ">"
  echo "> Downloading LLVM for LLD"
  echo ">"
  cd "${WORK_DIR}"
  git clone --depth=1 --branch main https://github.com/llvm/llvm-project.git "${WORK_DIR}/llvm-project"
}

build_lld() {
  cd "${WORK_DIR}"
  echo ">"
  echo "> Building LLD"
  echo ">"
  mkdir -p "${WORK_DIR}/llvm-project/build"
  cd "${WORK_DIR}/llvm-project/build"
  export INSTALL_LLD_DIR="${WORK_DIR}/gcc-${arch}"
  cmake -G "Ninja" \
    -DLLVM_ENABLE_PROJECTS=lld \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_LLD_DIR" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET_CLANG" \
    -DLLVM_TARGET_ARCH="$ARCH_CLANG" \
    -DLLVM_TARGETS_TO_BUILD="$ARCH_CLANG" \
    -DCMAKE_CXX_COMPILER="$(command -v clang++)" \
    -DCMAKE_C_COMPILER="$(command -v clang)" \
    -DLLVM_OPTIMIZED_TABLEGEN=ON \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_ENABLE_LTO=Full \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_BUILD_RUNTIME=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_ENABLE_MODULES=OFF \
    -DLLVM_ENABLE_BACKTRACES=OFF \
    -DLLVM_PARALLEL_COMPILE_JOBS="$(nproc --all)" \
    -DLLVM_PARALLEL_LINK_JOBS="$(nproc --all)" \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
    -DCMAKE_C_FLAGS="-O3" \
    -DCMAKE_CXX_FLAGS="-O3" \
    -DLLVM_ENABLE_PIC=ON \
    "${WORK_DIR}"/llvm-project/llvm
  ninja -j"$(nproc --all)"
  ninja -j"$(nproc --all)" install
  cd "${INSTALL_LLD_DIR}"/bin
  ln -sf lld "${TARGET_GCC}-ld.lld"
  cd "${WORK_DIR}"
}

download_resources
build_lld
