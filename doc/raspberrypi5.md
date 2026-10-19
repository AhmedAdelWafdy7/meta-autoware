# Raspberry Pi 5

## Build

```sh
kas build kas/raspberrypi5.yml
```

Output in `build/tmp-glibc/deploy/images/raspberrypi5/`:
`core-image-autoware-jazzy-raspberrypi5.rootfs.wic.bz2` (about 310 MB) and its `.wic.bmap`.

The Pi 5 uses the cortexa76 tune, so almost nothing is shared with the qemuarm64
sstate; a cold build takes most of a day on a 4-core, 16 GB host.

## Flash

```sh
sudo bmaptool copy core-image-autoware-jazzy-raspberrypi5.rootfs.wic.bz2 /dev/sdX
```

An SD card works. Use a USB3 or NVMe SSD for boot-time measurements.

## Measure

The image has Dropbear and `systemd-analyze`. Root login has no password.

```sh
ssh root@<pi> sh -s < tools/measure-target.sh
```

It prints boot time, rootfs size, free memory, and the RSS of a running
`autoware_simple_pure_pursuit` node.

## Notes

- meta-raspberrypi is pinned to scarthgap `018d44467c4f09eb63f8ea5e86e85d755250cf89`.
- Proprietary components: `rpi-bootfiles` (license `Broadcom-RPi`, in every Raspberry Pi
  image) and the Wi-Fi/Bluetooth firmware, enabled through
  `LICENSE_FLAGS_ACCEPTED += "synaptics-killswitch"`.
- `SSTATE_MIRRORS` is cleared for this machine: the public mirror has no cortexa76 or ROS
  objects, and checking it with 2 threads took hours.
- Serial console is on the debug UART (`ttyAMA10`, 115200).
