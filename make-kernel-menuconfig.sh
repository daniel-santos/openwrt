#!/bin/bash


src_dir=$(dirname $(readlink -f "$BASH_SOURCE"))
save_path="$PATH"

. ${src_dir}/env.sh --no-export

export STAGING_DIR STAGING_DIR_HOST STAGING_DIR_HOSTPKG STAGING_PREFIX \
       TMP_DIR TMPDIR TOPDIR

set -x
PATH="$tcd/bin:/usr/bin:$hd/bin:${save_path}" \
make -C $ld \
    HOSTCFLAGS="-O2 -I$hd/include -Wall -Wmissing-prototypes -Wstrict-prototypes" \
    HOST_LOADLIBES="-L$hd/lib" \
    CROSS_COMPILE="${TARGET}-" \
    ARCH="arm64" \
   "$@"
exit
    "$@"
    menuconfig
 CC="$CC"
