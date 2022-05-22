# GCC Cross Compiler Toolchain Build Script

![ARM GCC Build](https://github.com/mvaisakh/gcc-build/workflows/ARM%20GCC%20Build/badge.svg) ![ARM64 GCC Build](https://github.com/mvaisakh/gcc-build/workflows/ARM64%20GCC%20Build/badge.svg) 

This repository contains the script needed to compile bare metal GCC for various architectures using Linux distributions. The GCC source is fetched from the master branch hence, contains all the bleeding edge changes.

## Before we start

**Below are the packages you'll need**

* **Ubuntu or other Debian based distros**
    >**Note: On Ubuntu 20.04, the default GCC version is gcc 9.3.x which (in my test cases) brought in a lot of unneeded regressions. This was however fixed by compiling the toolchain itself with GCC 10**

    To install and set GCC 10 as the default compiler, you need to:

    ```bash
    sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y && sudo apt-get update
    ```

    ```bash
    sudo apt-get install flex bison ncurses-dev texinfo gcc gperf patch libtool automake g++ libncurses5-dev gawk subversion expat libexpat1-dev python-all-dev binutils-dev bc libcap-dev autoconf libgmp-dev build-essential pkg-config libmpc-dev libmpfr-dev autopoint gettext txt2man liblzma-dev libssl-dev libz-dev mercurial wget tar gcc-10 g++-10 zstd --fix-broken --fix-missing
    ```

* **Arch Linux**

    ```bash
    sudo pacman -S base-devel clang cmake git libc++ lld lldb ninja
    ```

* **Fedora**

    ```bash
    sudo dnf groupinstall "Development tools"
    sudo dnf install mpfr-devel gmp-devel libmpc-devel zlib-devel glibc-devel.i686 glibc-devel binutils-devel g++ texinfo bison flex
    ```

## Usage

Running this script is quite simple. We start by cloning this repository:
```bash
git clone https://github.com/mvaisakh/gcc-build.git gcc-build
```
```bash
./build-gcc.sh -a <architechture>
```
> As of now, I only support **arm**, **arm64** and **x86 (compiles for x86_64 only)**. This list is subject to change as I receive requests.

> Keep in mind that this script contains just the bare minimum prerequisites.

## Credits

* [Vaisakh (me)](https://github.com/mvaisakh/) for writing this script.
* [OS Dev Wiki](https://wiki.osdev.org) for knowledge base.
* [USBHost's Amazing GCC Build script](https://github.com/USBhost/build-tools-gcc) for certain prerequisite dependencies.

## Looking for precompiled toolchains?

My GCC Cross Compiler builds are automated and pushed biweekly i.e. on Sundays & Thursdays at 00:00 GMT+5:30 (IST). They are pushed to:
* **[ARM64](https://github.com/mvaisakh/gcc-arm64)**
* **[ARM32](https://github.com/mvaisakh/gcc-arm)**
* **[X86_64](https://github.com/mvaisakh/gcc-x86)** (Not built on cron anymore)

## Contributing to this repo

You're more than welcome to improve the contents within this script with a pull request. Enjoy :)
