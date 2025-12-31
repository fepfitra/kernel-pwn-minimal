#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

if [ -f linux-5.4/vmlinux ]; then
    echo "[+] Copying vmlinux symbols..."
    cp linux-5.4/vmlinux ./vmlinux
fi

if [ -d linux-5.4 ] && [ ! -f linux-5.4/.config ]; then
    echo "[*] Extracting config from bzImage..."
    ./linux-5.4/scripts/extract-ikconfig bzImage > linux-5.4/.config
fi

if [ -d linux-5.4 ] && [ ! -f linux-5.4/include/config/auto.conf ]; then
    echo "[*] Preparing kernel headers..."
    yes "" | make -C linux-5.4 modules_prepare > /dev/null 2>&1
    if [ ! -f linux-5.4/include/config/auto.conf ]; then
        echo "[-] Error: Failed to prepare kernel headers."
        yes "" | make -C linux-5.4 modules_prepare
        exit 1
    fi
fi

if [ -f src/Makefile ]; then
    echo "[+] Compiling kernel module..."
    if ! make -C src > /dev/null; then
        echo "[-] Error: Kernel module compilation failed."
        make -C src
        exit 1
    fi
    mkdir -p ./rootfs
    cp src/*.ko ./rootfs/
    
    if ls chall/*.ko 1> /dev/null 2>&1; then
        cp chall/*.ko ./rootfs/
    else
        echo "[-] Warning: No modules found in chall/"
    fi
    
    echo "[+] Kernel module compiled successfully."
fi

count=$(ls exploit/*.c 2>/dev/null | wc -l)
if [ "$count" -ne 0 ]; then
    echo "[+] Compiling exploits..."
    for f in exploit/*.c; do
        filename=$(basename "$f" .c)
        gcc -static "$f" -o "./rootfs/$filename"
        echo "    - $f -> ./rootfs/$filename"
    done
fi

if [ -f ./busybox ]; then
    echo "[+] Updating busybox and symlinks..."
    mkdir -p ./rootfs/bin
    cp ./busybox ./rootfs/bin/
    for cmd in sh ls cat mkdir mount poweroff id insmod chmod chown grep dmesg; do
        ln -sf busybox "./rootfs/bin/$cmd"
    done
		cp ./init ./rootfs/
fi

echo "[+] Packing initramfs.cpio.gz..."
(
    cd rootfs
    chmod +x init
    find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > ../initramfs.cpio.gz
)

echo "[*] Done! Archive created at ./initramfs.cpio.gz"
