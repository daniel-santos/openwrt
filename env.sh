#!/bin/bash

set -e
src_dir=/home/daniel/proj/embedded/openwrt/v24.10.y
pushd "$src_dir" > /dev/null

DEBUG=0

config_string() {
    local key="$1"
    grep "^CONFIG_${key}=" .config | awk '-F"' '{print $2}'
}

config_vars=$(cat << EOF
ARCH
CPU_TYPE
GCC_VERSION
TARGET_PROFILE
LIBC
TARGET_ARCH_PACKAGES
TARGET_BOARD
TARGET_SUBTARGET
TARGET_SUFFIX
VERSION_DIST
VERSION_NUMBER
VERSION_CODE
VERSION_REPO
VERSION_HOME_URL
VERSION_MANUFACTURER
VERSION_MANUFACTURER_URL
VERSION_BUG_URL
VERSION_SUPPORT_URL
VERSION_PRODUCT
VERSION_HWREV
EOF
)

for var in $config_vars; do
    eval $var=$(grep "^CONFIG_${var}=" .config | perl -pe 's|^.*?=||g;')
    ((DEBUG)) && echo "${var}=${!var}" >&2
done
TARGET_PROFILE="${TARGET_PROFILE/DEVICE_/}"

# openwrt-24.10 puts the kernel revision in a different file
kernel_rev() {
    local maj=$1
    local min=$2
    grep "^LINUX_VERSION-${maj}\.${min}\s*=" include/kernel-${maj}.${min} |
    perl -pe "
        s|^LINUX_VERSION-${maj}\.${min}\s*=\s*\.?(\d+)$|\$1|g;
    "
}

# Grep LINUX_KERNEL_HASH hash line out of include/kernel-version.mk
# outdated in openwrt 24.10
# kernel_hash() {
#     local pat="^LINUX_KERNEL_HASH-"
#
#     if [[ -n "$1" ]]; then
# 	pat+="${1}\."
# 	shift
#     fi
#     if [[ -n "$1" ]]; then
# 	pat+="${1}\."
# 	shift
#     fi
#     if [[ -n "$1" ]]; then
# 	pat+="${1} = "
# 	shift
#     fi
#     ((DEBUG)) && echo "pat=$pat" >&2
#     grep -E "$pat" include/kernel-version.mk
# }

# Determine kernel version from .config and include/kernel-version.mk files.
get_kernel_ver() {
    local maj
    local min
    local rev
    local maj_min

    maj_min=$(
	grep -E 'CONFIG_LINUX_[0-9]+_[0-9]+=y' .config |
	perl -pe '
	    s|^CONFIG_LINUX_(\d+)_(\d+)=y$|$1.$2|g;
	'
    )
    maj="${maj_min%%.*}"
    min="${maj_min##*.}"
    rev=$(kernel_rev ${maj} ${min})

    if [[ -n "${maj}" && -n "${min}" && -n "${rev}" ]]; then
	echo "${maj}.${min}.${rev}"
    else
        return 1
    fi
}

if ! kernel_ver=$(get_kernel_ver) ; then
    echo "Failed to discover kernel version." >&2
    exit 1
fi

((debug)) && echo "kernel_ver=${kernel_ver}"

# OpenWRT root directory
d="$src_dir"

# Staging directory
sd="$d/staging_dir"

# Build directory
bd="$d/build_dir"

# Host directory
hd="$sd/host"

# Toolchain slug
toolchain="toolchain-${TARGET_ARCH_PACKAGES}_gcc-${GCC_VERSION}_${TARGET_SUFFIX}"

# Target slug
target="target-${TARGET_ARCH_PACKAGES}_${TARGET_SUFFIX}"

# (staging) Toolchain directory
tcd="$sd/${toolchain}"

# Staging target directory
std="$sd/${target}"

# build Toolchain directory
btcd="$sd/${toolchain}"

# Build target directory
btd="$bd/${target}"

# Linux Arch directory
#lad="$btd/linux-${TARGET_ARCH_PACKAGES}"
lad="$btd/linux-${TARGET_BOARD}_${TARGET_SUBTARGET}"

# Linux kernel directory
ld="$lad/linux-${kernel_ver}"

# Backports directory
bpd=$(ls -d "$lad"/backports-* 2>/dev/null || true)

# Sanity checking
# if [[ -d $btd ]]; then
# 	[[ -d $btd && -d $btd/linux-* && ! -d $lad ]] ||
# 	[[ ! -d $lad && -d $btd/linux-* ]] ||
# 	[[ ! -d $bpd && -d $lad/linux-* ]] ||
# 	[[ ! -d $ld && -d $lad/linux-* ]]; then
# 	echo "You better check $0 script for errors" >&2
# 	echo "btd=$btd"
# 	echo "lad=$lad"
# 	echo "ld=$ld"
# 	ls -alFd $btd $lad $ld
# 	exit 1
#     fi
# fi

popd > /dev/null

local_vars=$(cat << EOF | grep -v '^$' | grep -v '^#' | sort -u
kernel_ver
d
sd
bd
hd
toolchain
target
tcd
std
btd
lad
ld
bpd
EOF
)

export_vars=$(cat << EOF | grep -v '^$' | grep -v '^#' | sort -u
# Variables read or derived from OpenWRT .config and include/*.mk
ARCH
CPU_TYPE
GCC_VERSION
LIBC
TARGET_ARCH_PACKAGES
TARGET_BOARD
TARGET_SUBTARGET
TARGET_SUFFIX
TARGET

OPTIMIZATION_FLAGS
DEBUG_FLAGS
MACH_FLAGS
MIPS16_FLAGS
WARN_OPTS
CWARN_OPTS
CPPFLAGS
CFLAGS
CXXFLAGS
LDFLAGS

# These are mostly for building the Linux kernel
CROSS_COMPILE
HOSTCFLAGS
HOST_LOADLIBES

# Toolchain programs
AR
AS
CC
CXX
GCC
GCCGO
LD
NM
OBJCOPY
OBJDUMP
RANLIB
SIZE
STRIP

# Autotools, parsers, et. al.
ACLOCAL_INCLUDE
BISON_PKGDATADIR
CONFIG_SITE
M4
PKG_CONFIG
PKG_CONFIG_LIBDIR
PKG_CONFIG_PATH

# path variables
PATH
GOROOT
STAGING_DIR
STAGING_DIR_HOST
STAGING_DIR_HOSTPKG
STAGING_PREFIX
TMP_DIR
TMPDIR
TOPDIR

# Everything else, including junk
GCC_HONOUR_COPTS
#GIT_ASKPASS
#GIT_CONFIG_PARAMETERS
GNU_HOST_NAME
HOST_ARCH
HOSTCC_NOCACHE
HOSTCC_WRAPPER
HOST_OS
LANG
LC_ALL
NO_TRACE_MAKE
PATCHELF
TARGET_CC_NOCACHE
TARGET_CXX_NOCACHE
TZ
EOF
)


# Target "triplet"
TARGET="${ARCH}-openwrt-linux-${LIBC}"


# Disabling -fno-caller-saves is for reduction of .text size.  Use of
# -ffat-lto-objects has no affect without -flto.
OPTIMIZATION_FLAGS="-Os -ffat-lto-objects -fno-caller-saves -pipe"
OPTIMIZATION_FLAGS="-Os -fno-caller-saves -pipe"
OPTIMIZATION_FLAGS="-O2 -ffat-lto-objects -flto -pipe"
OPTIMIZATION_FLAGS="-Os -pipe"

DEBUG_FLAGS="-ggdb3"

# mt7620a a MIPS 24KEc processed without hardware float.  I *believe* that
# -mno-branch-likely is for .text reduction, but not certain.
#MACH_FLAGS="-mips32r2 -mtune=24kc -msoft-float -mno-branch-likely"
#MIPS16_FLAGS="-mips16 -minterlink-mips16"
WARN_OPTS="-Wall -Wextra -Wno-error=unused-but-set-variable -Wno-error=unused-result -Wformat -Werror=format-security"
CWARN_OPTS="-Werror=implicit"

 CPPFLAGS="-I${std}/usr/include"
   CFLAGS="$OPTIMIZATION_FLAGS $DEBUG_FLAGS $MACH_FLAGS $MIPS16_FLAGS $WARN_OPTS $CWARN_OPTS"
 CXXFLAGS="$OPTIMIZATION_FLAGS $DEBUG_FLAGS $MACH_FLAGS $MIPS16_FLAGS $WARN_OPTS"
  LDFLAGS="$OPTIMIZATION_FLAGS -L${tcd}/usr/lib -L${tcd}/lib "
  LDFLAGS="-Os -L${tcd}/usr/lib -L${tcd}/lib "

# Be careful with these opts.  Do not use with musl


# Extras
CROSS_COMPILE="${TARGET}-"
HOSTCFLAGS="-O2 -I${hd}/include -Wall -Wmissing-prototypes -Wstrict-prototypes"
HOST_LOADLIBES="-L${hd}/lib -ltinfo"


#ARCH_FLAGS="-mno-branch-likely -mips32r2 -mtune=24kc -fno-caller-saves -fhonour-copts -Wno-error=unused-but-set-variable -Wno-error=unused-result -msoft-float -mips16 -minterlink-mips16"
#ARCH_FLAGS="-mno-branch-likely -mips32r2 -mtune=24kc -fno-caller-saves -fhonour-copts -Wno-error=unused-but-set-variable -Wno-error=unused-result -msoft-float"

     AR="${TARGET}-gcc-ar"
# Do not include mips16 flags in AS
     AS="${TARGET}-gcc -c $OPTIMIZATION_FLAGS $DEBUG_FLAGS $MACH_FLAGS"
     CC="${TARGET}-gcc"
    CXX="${TARGET}-g++"
    GCC="${TARGET}-gcc"
  GCCGO="${TARGET}-gccgo"
     LD="${TARGET}-ld"
     M4="$hd/bin/m4"
     NM="${TARGET}-gcc-nm"
OBJCOPY="${TARGET}-objcopy"
OBJDUMP="${TARGET}-objdump"
 RANLIB="${TARGET}-gcc-ranlib"
   SIZE="${TARGET}-size"
  STRIP="${TARGET}-strip"

ACLOCAL_INCLUDE="-I $std/usr/share/aclocal -I $sd/hostpkg/share/aclocal -I $std/host/share/aclocal"
BISON_PKGDATADIR=$hd/share/bison
CONFIG_SITE=$d/include/site/mipsel
GCC_HONOUR_COPTS=s
#GIT_ASKPASS=/bin/true
#GIT_CONFIG_PARAMETERS='core.autocrlf=false'
GOROOT=$std/root-ramips/usr/lib/go-1.13
GNU_HOST_NAME=x86_64-pc-linux-gnu
HOST_ARCH=x86_64
HOSTCC_NOCACHE=$std/host/bin/gcc
HOSTCXX_NOCACHE=$std/host/bin/g++
HOST_EXTRACFLAGS=$std/host/include
HOST_GNULIB_SRCDIR=$std/host/share/gnulib
HOST_OS=Linux
LANG=C
LC_ALL=C
NO_TRACE_MAKE="make V=ssc"
#PATCHELF=staging_dir/host/bin/patchelf
PATCHELF=patchelf
PATH=$std/host/bin:$sd/hostpkg/bin:$tcd/bin:$tcd/bin:$hd/bin:$hd/bin:$PATH
PKG_CONFIG=$hd/bin/pkg-config
PKG_CONFIG_LIBDIR=$std/usr/lib/pkgconfig:$std/usr/share/pkgconfig
PKG_CONFIG_PATH=$std/usr/lib/pkgconfig:$std/usr/share/pkgconfig
#SHELL="/usr/bin/env bash"
#SH_FUNC=". $d/include/shell.sh;"
STAGING_DIR=$std
STAGING_DIR_HOST=$hd
STAGING_DIR_HOSTPKG=$sd/hostpkg
STAGING_PREFIX=$std/usr
TARGET_CC_NOCACHE="${CC}"
TARGET_CXX_NOCACHE="${CXX}"
TMP_DIR=$d/tmp
TMPDIR=$d/tmp
TOPDIR=$d
TZ=UTC

set +e

# Clean up path (remove redundant entires, remove adb crap)
PATH=$(
    echo "$PATH" |
    tr ':' '\n' |
    awk '!seen[$0]++' |
    grep -v /android- |
    tr '\n' :
)
[[ "${PATH:${#PATH}-1}" = ":" ]] && PATH="${PATH::-1}"

if [[ "$1" == "--no-export" ]]; then
    shift
    export OPENWRT_VARS="${export_vars}"
else
    export ${export_vars}
fi

if [[ "$1" == "--print-vars" ]]; then
    for var in ${local_vars} ${export_vars}; do
	#printf "%-23s %s\n" "${var}" "${!var}"
	printf "%s=%s\n" "${var}" "${!var}"
    done
    shift
fi

if (($#)) && [[ -n "$1" ]]; then
    echo "running $@"
    exec ionice -c3 nice -n20 "$@"
fi
