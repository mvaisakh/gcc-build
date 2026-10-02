#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0
# Author: Vaisakh Murali
set -Eeuo pipefail

echo "*****************************************"
echo "* Building Bare-Metal Bleeding Edge GCC *"
echo "*****************************************"

print_usage() {
  cat <<'EOF'
Usage: ./build-gcc.sh -a <arch> [-p <phase>] [-j <jobs>] [-h]

Supported architectures:
  arm       -> arm-eabi
  arm64     -> aarch64-elf
  arm64gnu  -> aarch64-linux-gnu
  riscv64   -> riscv64-elf
  x86       -> x86_64-elf

Supported phases:
  normal     -> default build with no PGO profile reuse
  instrument -> profile generation phase
  optimize   -> PGO-optimized build using generated profiles

Examples:
  ./build-gcc.sh -a arm
  ./build-gcc.sh -a riscv64 -p instrument
  ./build-gcc.sh -a x86 -j 8
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
  local deps=(bash git make gcc g++ sed awk grep tar xz wget)
  for dep in "${deps[@]}"; do
    require_command "$dep"
  done

  if command -v apt-get >/dev/null 2>&1; then
    echo ">>> Detected Debian/Ubuntu toolchain dependencies. Install with:"
    echo "sudo apt-get install -y flex bison ncurses-dev texinfo gcc gperf patch libtool automake g++ libncurses5-dev gawk subversion expat libexpat1-dev python-all-dev binutils-dev bc libcap-dev autoconf libgmp-dev build-essential pkg-config libmpc-dev libmpfr-dev autopoint gettext txt2man liblzma-dev libssl-dev libz-dev mercurial wget tar zstd"
  elif command -v pacman >/dev/null 2>&1; then
    echo ">>> Detected Arch Linux. Install with:"
    echo "sudo pacman -S base-devel clang cmake git libc++ lld lldb ninja"
  elif command -v dnf >/dev/null 2>&1; then
    echo ">>> Detected Fedora. Install with:"
    echo "sudo dnf groupinstall \"Development tools\" && sudo dnf install mpfr-devel gmp-devel libmpc-devel zlib-devel glibc-devel.i686 glibc-devel binutils-devel g++ texinfo bison flex cmake which clang ninja-build lld bzip2"
  fi
}

# Declare the number of jobs to run simultaneously
JOBS="${JOBS:-$(nproc --all)}"
arch=""
PHASE="normal"

while getopts "a:p:j:h" flag; do
  case "${flag}" in
    a) arch="${OPTARG}" ;;
    p) PHASE="${OPTARG}" ;;
    j) JOBS="${OPTARG}" ;;
    h) print_usage; exit 0 ;;
    *) print_usage >&2; exit 1 ;;
  esac
done

[ -n "${arch}" ] || error "An architecture must be provided with -a. Use -h for help."

case "${arch}" in
  "arm") TARGET="arm-eabi" ;;
  "arm64") TARGET="aarch64-elf" ;;
  "arm64gnu") TARGET="aarch64-linux-gnu" ;;
  "riscv64") TARGET="riscv64-elf" ;;
  "x86") TARGET="x86_64-elf" ;;
  *) error "Unsupported architecture '${arch}'. Supported values: arm, arm64, arm64gnu, riscv64, x86" ;;
esac

case "${PHASE}" in
  "normal") ;;
  "instrument") ;;
  "optimize") ;;
  *) error "Unsupported phase '${PHASE}'. Supported values: normal, instrument, optimize" ;;
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

check_dependencies

echo "Cleaning up previously cloned repos..."
for stale_dir in binutils build-binutils build-gcc gcc; do
  if [ -d "${WORK_DIR}/${stale_dir}" ]; then
    rm -rf -- "${WORK_DIR}/${stale_dir}"
  fi
done

echo "||                                                                    ||"
echo "|| Building Bare Metal Toolchain for ${arch} with ${TARGET} as target ||"
echo "||                                                                    ||"

download_resources() {
  echo "Downloading Pre-requisites"
  echo "Cloning binutils"
  git clone --depth=1 --branch master https://sourceware.org/git/binutils-gdb.git "${WORK_DIR}/binutils"
  sed -i '/^development=/s/true/false/' "${WORK_DIR}/binutils/bfd/development.sh"
  echo "Cloned binutils!"
  echo "Cloning GCC"
  git clone --depth=1 --branch master https://gcc.gnu.org/git/gcc.git "${WORK_DIR}/gcc"
  echo "Downloaded prerequisites!"
}

build_binutils() {
  cd "${WORK_DIR}"
  echo "Building Binutils"
  mkdir -p "${WORK_DIR}/build-binutils"
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
  cd "${WORK_DIR}"
  echo "Built Binutils, proceeding to next step...."
}

build_gcc() {
  cd "${WORK_DIR}"
  echo "Building GCC"
  cd gcc
  ./contrib/download_prerequisites
  echo "Bleeding Edge" > gcc/DEV-PHASE
  cd "${WORK_DIR}"
  mkdir -p "${WORK_DIR}/build-gcc"
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
