# GCC Cross Compiler Toolchain Build Script

![ARM GCC Build](https://github.com/mvaisakh/gcc-build/workflows/ARM%20GCC%20Build/badge.svg) ![ARM64 GCC Build](https://github.com/mvaisakh/gcc-build/workflows/ARM64%20GCC%20Build/badge.svg) 

This is a build script intended for compiling GCC from source on Linux Distributions for aarch64 bare metal development, focusing primarily on Android Kernels.
Everything is compiled from straight from the master branch of GCC git repository.

## Prerequisite

**To use this toolchain, certain packages are needed.**

* **If you are on Ubuntu (or it's other flavours):**
    >**Note: On Ubuntu 20.04, the default GCC version is gcc 9.3.x, which on my test cases brought in a lot of unneeded regressions, this was fixed with compiling the toolchain with GCC 10**

    To install GCC-10 as default compiler, you can just do:

    ```bash
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && sudo apt-get update
    ```

    ```bash
    sudo apt-get install flex bison ncurses-dev texinfo gcc gperf patch libtool automake g++ libncurses5-dev gawk subversion expat libexpat1-dev python-all-dev binutils-dev bc libcap-dev autoconf libgmp-dev build-essential pkg-config libmpc-dev libmpfr-dev autopoint gettext txt2man liblzma-dev libssl-dev libz-dev mercurial wget tar gcc-10 g++-10 zstd --fix-broken --fix-missing
    ```

* **If you are on Arch Linux:**

    ```bash
    sudo pacman -S base-devel clang cmake git libc++ lld lldb ninja
    ```

* - [ ] **TODO:** Add other distro setup Wiki

## Usage

Running the script is very easy.
Clone this repo
```bash
git clone https://github.com/mvaisakh/gcc-build.git gcc-build
```
```bash
./build-gcc.sh -a <architechture>
```
> Only supported options are **arm**, **arm64** and **x86 (compiles for x86_64 only)** for now.

> NOTE: The script is very bare minimum and it isn't very dynamic like the other GCC build scripts out there. If you want to contribute, fork this repo and make a pull request.

## Credits

* [mvaisakh](https://github.com/mvaisakh/) for writing this noob script.
* [OS Dev Wiki](https://wiki.osdev.org) for knowledge base.
* [USBHost's Amazing GCC Build script](https://github.com/USBhost/build-tools-gcc) for certain prerequisite dependencies.

## Looking for Precompiled Toolchains?

GCC Cross Compiler Builds are automated, built biweekly on Sundays & Thursdays at 00:00 GMT+5:30 (IST) and pushed to:
* **[ARM64](https://github.com/mvaisakh/gcc-arm64)**
* **[ARM32](https://github.com/mvaisakh/gcc-arm)**
* **[X86_64](https://github.com/mvaisakh/gcc-x86)**

## Contributing to this repo

Feel free to fork and improve the script, add features and do a pull request. All contributions are welcome!
