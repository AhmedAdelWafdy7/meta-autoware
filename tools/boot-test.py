#!/usr/bin/env python3
"""Boot an image under qemu and check ROS 2 runs on it.

  ros-image-core       demo_nodes_cpp talker and demo_nodes_py listener exchange messages
  core-image-autoware  autoware_simple_pure_pursuit starts and publishes its control topic

Run from the repo root after the image is built:
    tools/boot-test.py qemuarm64
    tools/boot-test.py qemuarm64 --image core-image-autoware

Exits 0 and prints PASS on success, non-zero and prints FAIL otherwise.
"""
import argparse
import re
import sys
from pathlib import Path

import pexpect

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = REPO_ROOT / "build"
RUNQEMU = REPO_ROOT / "layers/openembedded-core/scripts/runqemu"

BOOT_TIMEOUT = 600
LOGIN_TIMEOUT = 60
ROS_TIMEOUT = 30
WAIT_TIMEOUT = 120  # no KVM for an x86-64 guest on an arm64 host, so nodes start slowly
PROMPT = r"[#\$]\s*$"

ROS_SHARE = "/opt/ros/jazzy/share"
PURE_PURSUIT_PARAMS = (
    f"--params-file {ROS_SHARE}/autoware_vehicle_info_utils/config/vehicle_info.param.yaml "
    f"--params-file {ROS_SHARE}/autoware_simple_pure_pursuit/config/simple_pure_pursuit.param.yaml"
)


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def find_qemuboot_conf(machine, image):
    # The image's qemuboot.conf carries the right qemu flags for any MACHINE.
    # One optional name segment (the ROS distro) so core-image-autoware-dev doesn't match.
    deploy_dir = BUILD_DIR / "tmp-glibc/deploy/images" / machine
    pattern = re.compile(rf"{re.escape(image)}(-[a-z0-9]+)?-{re.escape(machine)}\.rootfs\.qemuboot\.conf")
    matches = [p for p in deploy_dir.glob("*.qemuboot.conf") if pattern.fullmatch(p.name)]
    if not matches:
        fail(f"no {image} qemuboot.conf under {deploy_dir}; build the image first")
    return matches[0]


def wait_for(child, condition, timeout):
    """Poll a shell condition on the guest; returns once it holds or times out."""
    # the "" keeps the marker out of the echoed command
    child.sendline(
        f"i=0; while ! {condition} && [ $i -lt {timeout} ]; "
        'do sleep 1; i=$((i+1)); done; echo WAIT_""DONE'
    )
    child.expect(r"WAIT_DONE", timeout=timeout + ROS_TIMEOUT)
    child.expect(PROMPT, timeout=ROS_TIMEOUT)


def start_background(child, command, tag):
    child.sendline(f"sh -c '{command} > /tmp/{tag}.log 2>&1 & echo {tag}_PID:$!'")
    child.expect(rf"{tag}_PID:(\d+)", timeout=ROS_TIMEOUT)
    pid = child.match.group(1)
    child.expect(PROMPT, timeout=ROS_TIMEOUT)
    return pid


def run(child, command):
    child.sendline(command)
    child.expect(PROMPT, timeout=ROS_TIMEOUT)
    return child.before


def check_talker_listener(child):
    # ros-image-core has no setup.sh, so set the environment by hand
    env = (
        "export AMENT_PREFIX_PATH=/opt/ros/jazzy;"
        "export PATH=/opt/ros/jazzy/bin:$PATH;"
        "export PYTHONPATH=/opt/ros/jazzy/lib/python3.12/site-packages:$PYTHONPATH;"
        "export LD_LIBRARY_PATH=/opt/ros/jazzy/lib:$LD_LIBRARY_PATH;"
        # otherwise the listener's redirected stdout is block-buffered
        "export PYTHONUNBUFFERED=1;"
    )
    listener = start_background(child, f"{env} ros2 run demo_nodes_py listener", "LISTENER")
    talker = start_background(child, f"{env} ros2 run demo_nodes_cpp talker", "TALKER")
    wait_for(child, "grep -q 'I heard' /tmp/LISTENER.log", WAIT_TIMEOUT)
    output = run(child, f"kill {talker} {listener}; cat /tmp/LISTENER.log")
    if not re.search(r"I heard: \[Hello World", output):
        return f"listener log did not contain expected message:\n{output}"
    return None


def check_autoware_node(child):
    run(child, ". /opt/ros/jazzy/setup.sh")
    pid = start_background(
        child,
        f". /opt/ros/jazzy/setup.sh; ros2 run autoware_simple_pure_pursuit "
        f"autoware_simple_pure_pursuit_exe --ros-args {PURE_PURSUIT_PARAMS}",
        "PURSUIT",
    )
    wait_for(child, "ros2 node list 2>/dev/null | grep -q '^/simple_pure_pursuit$'", WAIT_TIMEOUT)
    nodes = run(child, "ros2 node list")
    topics = run(child, "ros2 topic list")
    log = run(child, f"kill {pid}; cat /tmp/PURSUIT.log")
    if "/simple_pure_pursuit" not in nodes:
        return f"node /simple_pure_pursuit not running. Node log:\n{log}"
    if "/simple_pure_pursuit/output/control_command" not in topics:
        return f"control_command topic missing. Topics:\n{topics}"
    return None


CHECKS = {
    "ros-image-core": (check_talker_listener, "512"),
    "core-image-autoware": (check_autoware_node, "4096"),
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("machine", help="e.g. qemuarm64, qemux86-64")
    parser.add_argument("--image", default="ros-image-core", choices=sorted(CHECKS))
    args = parser.parse_args()

    if not RUNQEMU.exists():
        fail(f"runqemu not found at {RUNQEMU}; run kas first")

    check, memory = CHECKS[args.image]
    child = pexpect.spawn(
        str(RUNQEMU),
        [str(find_qemuboot_conf(args.machine, args.image)), "nographic", "nonetwork", "snapshot",
         f"qemuparams=-m {memory}"],
        cwd=str(BUILD_DIR),
        timeout=BOOT_TIMEOUT,
        encoding="utf-8",
        codec_errors="ignore",
    )
    child.logfile = sys.stdout

    try:
        child.expect(r"login:", timeout=BOOT_TIMEOUT)
        child.sendline("root")
        # debug-tweaks: either a shell straight away or an empty password
        if child.expect([r"Password:", PROMPT], timeout=LOGIN_TIMEOUT) == 0:
            child.sendline("")
            child.expect(PROMPT, timeout=LOGIN_TIMEOUT)

        error = check(child)

        child.sendline("poweroff -f")
        child.expect(pexpect.EOF, timeout=BOOT_TIMEOUT)
    except pexpect.TIMEOUT:
        fail(f"timed out waiting for expected output. Last buffer:\n{child.before}")
    finally:
        if child.isalive():
            child.terminate(force=True)

    if error:
        fail(error)
    print(f"\nPASS ({args.machine}, {args.image})")


if __name__ == "__main__":
    main()
