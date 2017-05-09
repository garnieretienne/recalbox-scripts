# Various stuff about Recalbox

This repository contain various scripts/file/notes related to my recalbox
console.

## Disable the rainbow splash at startup when using NOOBS

`mount /dev/mmcblk0p1 /mnt && echo "disable_splash=1" >> /mnt/config.txt`

## Overclock the 3D block

This can speed up the n64 emulator.

`mount -o remount, rw /boot && echo v3d_freq=525 >> /boot/config.txt`

## Update the kernel

```
cd /boot
mv bootcode.bin bootcode.bin.backup
mv start.elf start.elf.backup
mv fixup.dat fixup.dat.backup
wget https://github.com/raspberrypi/firmware/blob/stable/boot/bootcode.bin?raw=true -O bootcode.bin
wget https://github.com/raspberrypi/firmware/blob/stable/boot/start.elf?raw=true -O start.elf
wget https://github.com/raspberrypi/firmware/blob/stable/boot/fixup.dat?raw=true -O fixup.dat
```
