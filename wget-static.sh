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
WGET_VERSION="1.25.0"
ALPINE_VERSION="3.23.3"
ALPINE_MAJOR_MINOR="${ALPINE_VERSION%.*}"

## map arch to QEMU binary name; Alpine minirootfs URL is derived from ARCH and version
case "${ARCH}" in
  x86_64)  QEMU_ARCH="" ;;
  x86)     QEMU_ARCH="i386" ;;
  aarch64) QEMU_ARCH="aarch64" ;;
  armhf)   QEMU_ARCH="arm" ;;
  armv7)   QEMU_ARCH="arm" ;;
  *)
    echo "Unknown architecture: ${ARCH}"
    exit 1
    ;;
esac

ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"
TARBALL="${ALPINE_URL##*/}"

cleanup() {
  sudo umount -lf "./pasta/proc" 2>/dev/null || true
  sudo umount -lf "./pasta/dev"  2>/dev/null || true
  sudo umount -lf "./pasta/sys"  2>/dev/null || true
}
trap cleanup EXIT

echo -e "${AQUA}= install dependencies${NC}"
APT_PACKAGES=(wget curl binutils)
[ -n "${QEMU_ARCH}" ] && APT_PACKAGES+=(qemu-user-static)
sudo apt-get update -qy && sudo apt-get install -y "${APT_PACKAGES[@]}"

echo -e "${HELIOTROPE}= download alpine rootfs${NC}"
wget -c "${ALPINE_URL}"

echo -e "${MINT}= extract rootfs${NC}"
mkdir -p pasta
tar -C pasta/ -xf "${TARBALL}"

echo -e "${TOMATO}= copy resolv.conf into the folder${NC}"
cp /etc/resolv.conf ./pasta/etc/

echo -e "${TAWNY}= setup QEMU for cross-arch builds${NC}"
if [ -n "${QEMU_ARCH}" ]; then
  sudo mkdir -p "./pasta/usr/bin/"
  sudo cp "/usr/bin/qemu-${QEMU_ARCH}-static" "./pasta/usr/bin/"
fi

echo -e "${VIOLET}= mount, bind and chroot into dir${NC}"
sudo mount -t proc none "./pasta/proc/"
sudo mount --rbind /dev "./pasta/dev/"
sudo mount --rbind /sys "./pasta/sys/"
sudo chroot ./pasta/ /bin/sh -c "set -e && apk update && apk add build-base \
musl-dev \
openssl-dev \
zlib-dev \
libidn2-dev \
libpsl-dev \
libuuid \
curl \
gawk \
libidn2-static \
openssl-libs-static \
zlib-static \
libpsl-static \
flex \
bison \
libunistring-dev \
libunistring-static \
upx \
perl && curl -L -O 'https://mirrors.ibiblio.org/gnu/wget/wget-${WGET_VERSION}.tar.gz' && \
tar xf wget-${WGET_VERSION}.tar.gz && \
cd wget-${WGET_VERSION}/ && \
./configure CC=gcc --with-ssl=openssl LDFLAGS='-static -lidn2 -lunistring' CFLAGS='-O3 -Wno-unterminated-string-initialization' PERL=/usr/bin/perl && \
make -j\$(nproc) && \
strip src/wget && \
upx --ultra-brute src/wget"
mkdir -p dist
cp "./pasta/wget-${WGET_VERSION}/src/wget" "dist/wget-${ARCH}"
tar -C dist -cJf "dist/wget-${ARCH}.tar.xz" "wget-${ARCH}"
echo -e "${LEMON}= All done!${NC}"