# RockPro64 Firmware

This repository builds firmware for a RockPro 64.

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
