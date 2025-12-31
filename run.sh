#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

KERNEL_IMAGE="./bzImage"
INITRD="./initramfs.cpio.gz"

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "[-] Error: Kernel image not found at $SCRIPT_DIR/bzImage"
    exit 1
fi

APPEND="console=ttyS0 quiet panic=1 nokaslr nopti"

if [ "$1" == "kaslr" ]; then
    APPEND="console=ttyS0 quiet panic=1 nopti"
    echo "[*] Launching with KASLR enabled."
elif [ "$1" == "pti" ]; then
    APPEND="console=ttyS0 quiet panic=1 nokaslr"
    echo "[*] Launching with PTI enabled."
elif [ "$1" == "full" ]; then
    APPEND="console=ttyS0 quiet panic=1"
    echo "[*] Launching with all mitigations enabled."
else
    echo "[*] Launching with mitigations disabled (debug mode)."
fi

/usr/bin/qemu-system-x86_64 \
    -kernel "$KERNEL_IMAGE" \
    -initrd "$INITRD" \
    -nographic \
    -no-reboot \
    -s \
    -append "$APPEND"
