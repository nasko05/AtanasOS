#!/bin/bash
rm -rf build
make
qemu-system-i386 -fda ./build/main_floppy.img