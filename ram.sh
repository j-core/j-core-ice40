#!/bin/sh

rm ram.img
make -C testrom
sh2-elf-size testrom/main.elf ram.img
sh2-elf-objcopy -v -S -O binary --srec-forceS3 testrom/main.elf ram.img

echo making image for Lattice

gcc conv.c -o conv
./conv < ram.img > ram_init.vhd
