#!/bin/sh
# Copyright (C) 2006-2012 OpenWrt.org
set -e -x
if [ $# -ne 7 ] && [ $# -ne 8 ]; then
    echo "SYNTAX: $0 <file> <kernel size> <kernel directory> <rootfs min size> <rootfs image> <overlay type> <overlay size> [<align>]"
    exit 1
fi

set -x
OUTPUT="$1"
KERNELSIZE="$2"
KERNELDIR="$3"
KERNELPARTTYPE=${KERNELPARTTYPE:-83}
ROOTFSMINSIZE="$4"
ROOTFSIMAGE="$5"
ROOTFSPARTTYPE=${ROOTFSPARTTYPE:-83}
OVERLAYTYPE="$6"
OVERLAYSIZE="$7"
OVERLAYPARTTYPE=${OVERLAYPARTTYPE:-83}
ALIGN="$8"

OVERLAYINITSIZE=4194304

rootfs_size=$(stat -c %s $ROOTFSIMAGE)
rootfs_min_size_mib=$(((rootfs_size + 1048575) / 1048576))
if [ $ROOTFSMINSIZE -gt $rootfs_min_size_mib ]; then
  ROOTFSSIZE=$ROOTFSMINSIZE
else
  ROOTFSSIZE=$rootfs_min_size_mib
fi

rm -f "$OUTPUT" "$OUTPUT.mbr"

head=16
sect=63

# create partition table
set $(ptgen -o "$OUTPUT.mbr" -h $head -s $sect ${GUID:+-g} -t "${KERNELPARTTYPE}" -p "${KERNELSIZE}m${PARTOFFSET:+@$PARTOFFSET}" -t "${ROOTFSPARTTYPE}" -p "${ROOTFSSIZE}m" -p "${OVERLAYSIZE}m" ${ALIGN:+-l $ALIGN} ${SIGNATURE:+-S 0x$SIGNATURE} ${GUID:+-G $GUID})

KERNELOFFSET="$(($1 / 512))"
KERNELSIZE="$2"
ROOTFSOFFSET="$(($3 / 512))"
ROOTFSSIZE="$(($4 / 512))"
OVERLAYOFFSET="$(($5 / 512))"
IMGSIZE="$(($5 + OVERLAYINITSIZE))"
OVERLAYSIZE="$(($6 / 512))"


[ -n "$PADDING" ] && dd if=/dev/zero of="$OUTPUT" bs=65536 count=$((IMGSIZE / 65536))
dd if="$OUTPUT.mbr" of="$OUTPUT" conv=notrunc
rm -f "$OUTPUT.overlay"

# Using mcopy -s ... is using READDIR(3) to iterate through the directory
# entries, hence they end up in the FAT filesystem in traversal order which
# breaks reproducibility.
# Implement recursive copy with reproducible order.
dos_dircopy() {
  local entry
  local baseentry
  for entry in "$1"/* ; do
    if [ -f "$entry" ]; then
      mcopy -i "$OUTPUT.kernel" "$entry" ::"$2"
    elif [ -d "$entry" ]; then
      baseentry="$(basename "$entry")"
      mmd -i "$OUTPUT.kernel" ::"$2""$baseentry"
      dos_dircopy "$entry" "$2""$baseentry"/
    fi
  done
}

case "$OVERLAYTYPE" in
ext4)
  make_ext4fs -J -L rootfs_data -l "$OVERLAYINITSIZE" ${SOURCE_DATE_EPOCH:+-T ${SOURCE_DATE_EPOCH}} "$OUTPUT.overlay"
  dd if="$OUTPUT.overlay" of="$OUTPUT" bs=512 seek="$OVERLAYOFFSET" conv=notrunc
  rm -f "$OUTPUT.overlay";;
*)
  echo "Unsupported overlay type: $OVERLAYTYPE" >&2
  exit 1;;
esac

# [ -n "$PADDING" ] && dd if=/dev/zero of="$OUTPUT" bs=512 seek="$ROOTFSOFFSET" conv=notrunc count="$ROOTFSSIZE"
dd if="$ROOTFSIMAGE" of="$OUTPUT" bs=512 seek="$ROOTFSOFFSET" conv=notrunc

if [ -n "$GUID" ]; then
#     [ -n "$PADDING" ] && dd if=/dev/zero of="$OUTPUT" bs=512 seek="$((ROOTFSOFFSET + ROOTFSSIZE))" conv=notrunc count="$sect"
    mkfs.fat --invariant -n kernel -C "$OUTPUT.kernel" -S 512 "$((KERNELSIZE / 1024))"
    LC_ALL=C dos_dircopy "$KERNELDIR" /
else
    ls -alF --color=always "$OUTPUT.kernel" "$KERNELDIR" || true
    (env && ulimit -a) > /tmp/gen_image_generic.$$.debug
    make_ext4fs -J -L kernel -l "$KERNELSIZE" ${SOURCE_DATE_EPOCH:+-T ${SOURCE_DATE_EPOCH}} "$OUTPUT.kernel" "$KERNELDIR"
fi

dd if="$OUTPUT.kernel" of="$OUTPUT" bs=512 seek="$KERNELOFFSET" conv=notrunc
rm -f "$OUTPUT.kernel"
