#!/bin/bash


src_dir=$(dirname $(readlink -f "$BASH_SOURCE"))
save_path="$PATH"

. ${src_dir}/env.sh --no-export
#. ${src_dir}/env.sh
#
# export STAGING_DIR STAGING_DIR_HOST STAGING_DIR_HOSTPKG STAGING_PREFIX \
#        TMP_DIR TMPDIR TOPDIR

set -x
PATH="$tcd/bin:/usr/bin:$hd/bin:${save_path}" \
ALL_VARIANTS= \
CDPATH= \
CFLAGS= \
BUILD_VARIANT= \
GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01' \
GCC_HONOUR_COPTS=s \
make -C ${ld} \
CROSS_COMPILE="${TARGET}-" \
    KCFLAGS="-fmacro-prefix-map=${btd}=target-aarch64_generic_musl -fno-caller-saves" \
    HOSTCFLAGS="-O2 -I$hd/include -Wall -Wmissing-prototypes -Wstrict-prototypes" \
    HOST_LOADLIBES="-L$hd/lib" \
    CROSS_COMPILE="${CROSS_COMPILE}" \
    ARCH=arm64 \
    KBUILD_HAVE_NLS=no \
    KBUILD_BUILD_USER= \
    KBUILD_BUILD_HOST= \
    KBUILD_BUILD_TIMESTAMP="Wed Feb 26 01:34:35 2025" \
    KBUILD_BUILD_VERSION=0 \
    KBUILD_HOSTLDFLAGS="-L${sd}/host/lib" \
    CONFIG_SHELL=bash \
    V=1 \
    cmd_syscalls= \
    CC=aarch64-openwrt-linux-musl-gcc \
    KERNELRELEASE=6.6.73 \
    "$@"

exit
    Image dtbs modules

make -C $ld \
    HOSTCFLAGS="-O2 -I$hd/include -Wall -Wmissing-prototypes -Wstrict-prototypes" \
    CROSS_COMPILE="${TARGET}-" \
    ARCH="arm64" \
    HOST_LOADLIBES="-L$hd/lib" \
    CC="$CC" "$@"
exit
    "$@"
    menuconfig


#BUILD_SUBDIR=target/linux

