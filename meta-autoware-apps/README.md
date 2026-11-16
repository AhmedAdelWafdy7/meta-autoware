# meta-autoware-apps

Demos built on [meta-autoware](../meta-autoware). They show the stack running on a target
and are not for production: their data is licensed for non-commercial or demo use only.

## Dependencies

- `meta-autoware`, and through it everything that layer depends on

## Usage

Add this layer after `meta-autoware` and build the demo image:

```sh
bitbake core-image-autoware-demo
```

With kas: `kas build kas/raspberrypi5.yml:kas/demo.yml`.

| Recipe | Contents |
|---|---|
| `core-image-autoware-demo` | `core-image-autoware` plus the developer tools and both demos |
| `autoware-planning-sim-demo` | `autoware-planning-sim`: the planning simulator on the AWSIM Shinjuku map |
| `awsim-shinjuku-map` | the AWSIM Shinjuku map, CC-BY-NC-4.0 |
| `autoware-rosbag-replay-demo` | `autoware-rosbag-replay`: the logging simulator localizing on the sample rosbag |
| `autoware-sample-rosbag` | the TIER IV sample map and rosbag; no license stated, so it needs `LICENSE_FLAGS_ACCEPTED += "tier4-sample-data"` |

Both demos start a Foxglove bridge on port 8765.

`autoware-rosbag-replay` waits for the localization API before it plays the bag, which takes
about two minutes on a Raspberry Pi 5. It plays at 0.2x, as Autoware's tutorial does; set
`AUTOWARE_BAG_RATE` to change it. Extra arguments go to the launch.
