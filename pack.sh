#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

if [ -f linux-5.4/vmlinux ]; then
    echo "[+] Copying vmlinux symbols..."
    cp linux-5.4/vmlinux ./vmlinux
fi

if [ -f src/Makefile ]; then
    echo "[+] Compiling kernel module..."
		cd src
    make > /dev/null 2>&1
		cd ..
		cp src/*.ko ./rootfs/
		cp chall/*.ko ./rootfs/
		echo "[+] Kernel module compiled successfully."
fi

if [ -f exploit.c ]; then
    echo "[+] Compiling exploit..."
    gcc -static ./exploit/exploit.c -o ./rootfs/exploit
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
