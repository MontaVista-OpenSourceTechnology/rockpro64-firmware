# RockPro64 Firmware

This repository builds firmware for a RockPro 64.

## Building

To build it, you will need to install an aarch64 compiler, probably in
a package named "gcc-aarch64-linux-gnu". Then check out this repository
and "cd" do it.  Then do:

```
git submodule init
git submodule update
make -j `nproc`
```

The binary files will be in the "bin" directory.  There will be three
files:

* idbloader.img - The first-stage and second loader for an SD card or
  eMMC card.
* u-boot.itb - u-boot for the card for an SD card.
* u-boot-spi.img - A complete image for writing to SPI.

The makefile will spit out instruction on how to burn it at the end of
the run.

## Installing

The rk3399 boots from SPI first, so if you have valid firmware in the
SPI, it will not boot anything else.

To install on an SD card, do:

```
  sudo dd if=bin/idbloader.img of=/dev/mmcblkX seek=64
  sudo dd if=bin/u-boot.itb of=/dev/mmcblkX seek=16384
  sync
```

to an SD device, replacing X with your specific card.

For spi, you will need to boot u-boot on the card somehow then load
u-boot-spi.img into memory somehow and write it to SPI.  Something
like:

```
  dhcp
  tftp 0x2000000 u-boot-spi.img
  sf probe
  sf update 0x2000000 0 <size>
```

where <size> is the size (in hex) reported by the download.  You can
also "dd" it to /dev/mtd0 on Linux.

## Bypassing SPI boot

If your SPI gets messed up or the boot process fails for some reason,
do not despair!  Power off the board, then get a jumper and short pins
23 and 25 on the Pi compatible header.  This will disable the SPI.
Then power the board on.  Then it will boot from the next device in
the sequence.  Note that as soon as you see output from the board you
should remove the jumper or your SPI device may not be available.

If you want to remove the firmware from the SPI, you can erase the
first part of it by doing the following in u-boot:

```
sf erase 0 4000
```

or in Linux you can use "dd" to copy /dev/zero into /dev/mtd0.

## Useful Resources

I pulled information from all over the place, including:

https://stikonas.eu/wordpress/2019/09/15/blobless-boot-with-rockpro64/

https://gitlab.arm.com/systemready/firmware-build/rk3399-manifest

https://opensource.rock-chips.com/wiki_RK3399

https://opensource.rock-chips.com/images/e/ee/Rockchip_RK3399TRM_V1.4_Part1-20170408.pdf