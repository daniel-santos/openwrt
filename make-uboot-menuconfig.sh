#!/bin/bash

set -x
uboot_ver=2025.01

src_dir=$(dirname $(readlink -f "$BASH_SOURCE"))
save_path="$PATH"

. ${src_dir}/env.sh --no-export

export STAGING_DIR STAGING_DIR_HOST STAGING_DIR_HOSTPKG STAGING_PREFIX \
       TMP_DIR TMPDIR TOPDIR


cppflags="-I${tcd}/usr/include -I${tcd}include -I${tcd}/include/fortify"
cflags="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts \
        -fmacro-prefix-map=${btd}/u-boot-${uboot_ver}=u-boot-${uboot_ver} \
        -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 \
        -Wl,-z,now -Wl,-z,relro"

PATH="${tcd}/bin:/usr/bin:$hd/bin:${save_path}" \
CFLAGS="${cflags} ${cppflags}" \
CXXFLAGS="${cflags} ${cppflags}" \
LDFLAGS="-L${tcd}/usr/lib -L${tcd}/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro " \
make  -C ${btd}/u-boot-${uboot_ver}/. AR="aarch64-openwrt-linux-musl-gcc-ar" \
AS="aarch64-openwrt-linux-musl-gcc -c -Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=${btd}/u-boot-${uboot_ver}=u-boot-${uboot_ver} -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
LD="aarch64-openwrt-linux-musl-ld.bfd" \
NM="aarch64-openwrt-linux-musl-gcc-nm" \
CC="aarch64-openwrt-linux-musl-gcc" \
GCC="aarch64-openwrt-linux-musl-gcc" \
CXX="aarch64-openwrt-linux-musl-g++" \
RANLIB="aarch64-openwrt-linux-musl-gcc-ranlib" \
STRIP=aarch64-openwrt-linux-musl-strip OBJCOPY=aarch64-openwrt-linux-musl-objcopy OBJDUMP=aarch64-openwrt-linux-musl-objdump SIZE=aarch64-openwrt-linux-musl-size CROSS="aarch64-openwrt-linux-musl-" \
ARCH="aarch64" \
ARCH="sandbox" \
TARGET_CFLAGS="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=${btd}/u-boot-${uboot_ver}=u-boot-${uboot_ver} -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
TARGET_LDFLAGS="-L${tcd}/usr/lib -L${tcd}/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro" \
menuconfig

exit














exec make -C $ld \
    HOSTCFLAGS="-O2 -I$hd/include -Wall -Wmissing-prototypes -Wstrict-prototypes" \
    CROSS_COMPILE="mipsel-openwrt-linux-musl-" \
    ARCH="mips" \
    HOST_LOADLIBES="-L$hd/lib" \
    CC="mipsel-openwrt-linux-musl-gcc" \
    "$@" menuconfig



rm -f /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/.configured_*
rm -f /home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/target-aarch64_generic_musl/stamp/.uboot-envtools_installed
CFLAGS="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro  -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include/fortify " \
CXXFLAGS="-Os -pipe -mcpu=generic-g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro -flto=auto -fno-fat-lto-objects  -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include/fortify " \
LDFLAGS="-L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/lib -L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro " \
make  -C /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/. AR="aarch64-openwrt-linux-musl-gcc-ar" \
AS="aarch64-openwrt-linux-musl-gcc -c -Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
LD="aarch64-openwrt-linux-musl-ld.bfd" \
NM="aarch64-openwrt-linux-musl-gcc-nm" \
CC="aarch64-openwrt-linux-musl-gcc" \
GCC="aarch64-openwrt-linux-musl-gcc" \
CXX="aarch64-openwrt-linux-musl-g++" \
RANLIB="aarch64-openwrt-linux-musl-gcc-ranlib" \
STRIP=aarch64-openwrt-linux-musl-strip OBJCOPY=aarch64-openwrt-linux-musl-objcopy OBJDUMP=aarch64-openwrt-linux-musl-objdump SIZE=aarch64-openwrt-linux-musl-size CROSS="aarch64-openwrt-linux-musl-" \
ARCH="aarch64" \
ARCH="sandbox" \
TARGET_CFLAGS="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
TARGET_LDFLAGS="-L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/lib -L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro" \
tools-only_defconfig;

make[4]: Entering directory '/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07'
HOSTCC  scripts/basic/fixdep
HOSTCC  scripts/kconfig/conf.o
YACC    scripts/kconfig/zconf.tab.c
LEX     scripts/kconfig/zconf.lex.c
HOSTCC  scripts/kconfig/zconf.tab.o
HOSTLD  scripts/kconfig/conf
#
# configuration written to .config
#
make[4]: Leaving directory '/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07'
touch /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/.configured_68b329da9893e34099c7d8ad5cb9c940
rm -f /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/.built
touch /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/.built_check
CFLAGS="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro  -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include/fortify " \
CXXFLAGS="-Os -pipe -mcpu=generic-g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro -flto=auto -fno-fat-lto-objects  -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include -I/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/include/fortify " \
LDFLAGS="-L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/lib -L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro " \
make  -C /home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07/. AR="aarch64-openwrt-linux-musl-gcc-ar" \
AS="aarch64-openwrt-linux-musl-gcc -c -Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
LD="aarch64-openwrt-linux-musl-ld.bfd" \
NM="aarch64-openwrt-linux-musl-gcc-nm" \
CC="aarch64-openwrt-linux-musl-gcc" \
GCC="aarch64-openwrt-linux-musl-gcc" \
CXX="aarch64-openwrt-linux-musl-g++" \
RANLIB="aarch64-openwrt-linux-musl-gcc-ranlib" \
STRIP=aarch64-openwrt-linux-musl-strip OBJCOPY=aarch64-openwrt-linux-musl-objcopy OBJDUMP=aarch64-openwrt-linux-musl-objdump SIZE=aarch64-openwrt-linux-musl-size CROSS="aarch64-openwrt-linux-musl-" \
ARCH="aarch64" \
ARCH="sandbox" \
TARGET_CFLAGS="-Os -pipe -mcpu=generic -g3 -fno-caller-saves -fno-plt -fhonour-copts -fmacro-prefix-map=/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07=u-boot-2024.07 -flto=auto -fno-fat-lto-objects -Wformat -Werror=format-security -fstack-protector -D_FORTIFY_SOURCE=1 -Wl,-z,now -Wl,-z,relro" \
TARGET_LDFLAGS="-L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/usr/lib -L/home/daniel/proj/embedded/openwrt/v24.10.y/staging_dir/toolchain-aarch64_generic_gcc-13.3.0_musl/lib -fuse-ld=bfd -flto=auto -fuse-linker-plugin -znow -zrelro" \
envtools;
make[4]: Entering directory '/home/daniel/proj/embedded/openwrt/v24.10.y/build_dir/target-aarch64_generic_musl/u-boot-2024.07'
scripts/kconfig/conf  --syncconfig Kconfig
