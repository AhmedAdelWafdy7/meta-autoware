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

Both demos start a Foxglove bridge on port 8765.
