# meta-autoware

Investigation into building Autoware on Yocto/OpenEmbedded instead of Docker.

**Status:** base ROS 2 Jazzy stack, qemuarm64 is built and boot-tested.

## Prerequisites

- Linux x86-64 or aarch64 build host, ~5GB free disk for a cold build plus room to grow,
  the usual Poky build-essential packages (`gcc`, `g++`, `make`, `git`, `wget`, `cpio`,
  `diffstat`, `chrpath`, `rsync`, `file`).
- No Docker required. `kas` runs bitbake directly on the host.

```sh
pip install --user kas
```

## Build

```sh
kas build kas/qemuarm64.yml
```

First build fetches and builds the full layer set (poky, meta-openembedded, meta-ros) —
expect a couple of hours cold. `kas/cache.yml` points `DL_DIR`/`SSTATE_DIR` at
`~/yocto-cache/` (outside the build tree) and at the public Yocto sstate mirror, so
re-builds and future clones of this repo are much faster.

Output image: `build/tmp-glibc/deploy/images/qemuarm64/ros-image-core-jazzy-qemuarm64.rootfs.ext4`

## Boot-test

```sh
python3 tools/boot-test-qemuarm64.py
```

Boots the built image under `runqemu`, logs in, runs `demo_nodes_cpp talker` and
`demo_nodes_py listener`, and confirms they exchange messages. Requires `pexpect`
(`pip install --user pexpect` if not already present). This is also intended to become
the CI check for Phase 3's acceptance criterion.

## Layout

- `kas/` — pinned build configs (`base.yml` = poky + meta-openembedded,
  `ros2-jazzy.yml` = + meta-ros, `qemuarm64.yml` = machine + image target)
- `tools/` — scripts (currently just the boot test)
