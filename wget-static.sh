#!/bin/bash
set -euo pipefail

ORANGE="\033[38;2;255;165;0m"
LEMON="\033[38;2;255;244;79m"
TAWNY="\033[38;2;204;78;0m"
HELIOTROPE="\033[38;2;223;115;255m"
VIOLET="\033[38;2;143;0;255m"
MINT="\033[38;2;152;255;152m"
AQUA="\033[38;2;18;254;202m"
TOMATO="\033[38;2;255;99;71m"
NC="\033[0m"

ARCH=${ARCH:-x86_64}

##map arch to Alpine minirootfs URL and QEMU binary name
case "${ARCH}" in
  x86_64)
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-minirootfs-3.23.3-x86_64.tar.gz"
    QEMU_ARCH=""
    ;;
  x86)
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86/alpine-minirootfs-3.23.3-x86.tar.gz"
    QEMU_ARCH="i386"
    ;;
  aarch64)
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/aarch64/alpine-minirootfs-3.23.3-aarch64.tar.gz"
    QEMU_ARCH="aarch64"
    ;;
  armhf)
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/armhf/alpine-minirootfs-3.23.3-armhf.tar.gz"
    QEMU_ARCH="arm"
    ;;
  armv7)
    ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/armv7/alpine-minirootfs-3.23.3-armv7.tar.gz"
    QEMU_ARCH="arm"
    ;;
  *)
    echo "Unknown architecture: ${ARCH}"
    exit 1
    ;;
esac

TARBALL="${ALPINE_URL##*/}"

echo -e "${AQUA}= install some dependencies${NC}"
sudo apt update -qy && sudo apt -y install wget curl binutils

echo -e "${HELIOTROPE}= download alpine rootfs${NC}"
wget -c "${ALPINE_URL}"

echo -e "${MINT}= extract rootfs${NC}"
mkdir pasta
tar xf "${TARBALL}" -C pasta/

echo -e "${TOMATO}= copy resolv.conf into the folder${NC}"
cp /etc/resolv.conf ./pasta/etc/

echo -e "${TAWNY}= setup QEMU for cross-arch builds${NC}"
if [ -n "${QEMU_ARCH}" ]; then
  sudo apt update -qy && sudo apt -y install qemu-user-static
  sudo mkdir -p ./pasta/usr/bin/
  sudo cp "/usr/bin/qemu-${QEMU_ARCH}-static" "./pasta/usr/bin/"
fi

echo -e "${ORANGE}= if fails in cat command add inside chroot line this command 'cat src/css_.c >> src/css.c'${NC}"

echo -e "${VIOLET}= mount, bind and chroot into dir${NC}"
sudo mount -t proc none ./pasta/proc/
sudo mount --rbind /dev ./pasta/dev/
sudo mount --rbind /sys ./pasta/sys/
sudo chroot ./pasta/ /bin/sh -c "apk update && apk add build-base \
musl-dev \
openssl-dev \
zlib-dev \
libidn2-dev \
libpsl-dev \
libuuid \
curl \
gawk \
libpsl-dev \
libidn2-static \
openssl-libs-static \
zlib-static \
libpsl-static \
flex \
bison \
libunistring-dev \
libunistring-static \
upx \
perl && curl -L -O 'https://mirrors.ibiblio.org/gnu/wget/wget-1.25.0.tar.gz' && \
tar xf wget-1.25.0.tar.gz && \
cd wget-1.25.0/ && \
./configure CC=gcc --with-ssl=openssl LDFLAGS='-static -lidn2 -lunistring' CFLAGS='-O3 -Wno-unterminated-string-initialization' PERL=/usr/bin/perl && \
make -j\$(nproc) && \
strip src/wget && \
upx --ultra-brute src/wget"
mkdir -p dist
cp "./pasta/wget-1.25.0/src/wget" "dist/wget-${ARCH}"
tar -C dist -cJf "dist/wget-${ARCH}.tar.xz" "wget-${ARCH}"
echo -e "${LEMON}= All done!${NC}"