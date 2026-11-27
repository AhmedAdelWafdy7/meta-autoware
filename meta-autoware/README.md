# meta-autoware

An OpenEmbedded layer that builds the [Autoware](https://autoware.org) autonomous driving
stack on ROS 2 Jazzy as regular packages. It needs no GPU and has no machine configuration,
so it works on top of any BSP.

This is a community project. It is not affiliated with or endorsed by the Autoware
Foundation, and it is not safety-certified. Packages that need CUDA or TensorRT are not
built.

## Dependencies

Use the branch of each layer that matches this layer's `LAYERSERIES_COMPAT`:

- [openembedded-core](https://git.openembedded.org/openembedded-core): `meta`
- [meta-openembedded](https://git.openembedded.org/meta-openembedded): `meta-oe`,
  `meta-python`, `meta-networking`
- [meta-ros](https://github.com/ros/meta-ros): `meta-ros-common`, `meta-ros2`,
  `meta-ros2-jazzy`

Optional:

- [meta-tegra](https://github.com/OE4T/meta-tegra) for NVIDIA Jetson machines. See
  [NVIDIA Jetson](#nvidia-jetson).

## Usage

Add the layer and its dependencies to `bblayers.conf`, then build an image:

```sh
bitbake core-image-autoware
```

Nothing else needs configuring. The layer turns on its own `autoware-fixups` class.

| Image | Contents |
|---|---|
| `core-image-autoware-minimal` | system, vehicle and control |
| `core-image-autoware` | the minimal image plus sensing, localization, planning and map |
| `core-image-autoware-dev` | `core-image-autoware` plus simulation and developer tools; not for production |
| `core-image-autoware-perception` | `packagegroup-autoware-core` plus perception; perception is empty unless `DISTRO_FEATURES` has `cuda` |

The demo image, `core-image-autoware-demo`, is in the `meta-autoware-apps` layer.

To add your own vehicle and sensor packages, use `CORE_IMAGE_EXTRA_INSTALL`, or build your
image from the `packagegroup-autoware-*` groups.

`AUTOWARE_SYSTEM_MONITOR_PLATFORM` picks the CPU monitor in `autoware-system-monitor`. Set it
to `raspi` or `tegra`, or leave it empty for generic arm. It does nothing on x86-64.

## NVIDIA Jetson

With meta-tegra in `bblayers.conf`, the layer changes two things for tegra machines:

- `CONFIG_KPROBES=y` in meta-tegra's kernel, from `dynamic-layers/tegra/`. ROS
  `tracetools` pulls in `lttng-tools`, whose ptest needs `lttng-modules`, and
  `lttng-modules` does not build without kprobes.
- opencv is built without CUDA (`OPENCV_CUDA_SUPPORT ?= ""` in `layer.conf`). meta-tegra's
  CUDA opencv makes every package that uses opencv require the CUDA toolkit, and
  `cv_bridge` fails to configure. Set `OPENCV_CUDA_SUPPORT` in `local.conf` to override it.

Autoware's CUDA and TensorRT packages are not built yet.

## Notes

Recipes in `generated-recipes/` come from [ros-mash](https://github.com/robwoolley/ros-mash)
and are not edited by hand. Fixes go in `classes/autoware-fixups.bbclass` or in
`recipes-thirdparty-bbappends/`.

`meta-ros2-jazzy` has older `autoware_*_msgs` recipes with the same names as ours. This
layer has a higher priority, so its recipes win.

## Maintainer

Ahmed Adel Wafdy <fandes99@gmail.com>

## Patches

Open a pull request at <https://github.com/AhmedAdelWafdy7/meta-autoware> and sign off
every commit (`git commit -s`).

## License

The layer metadata is MIT. Packages keep their upstream licenses.
