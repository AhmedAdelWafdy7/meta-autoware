#!/usr/bin/env python3
"""Phase 3 acceptance test: boot ros-image-core under qemuarm64 and confirm
demo_nodes_cpp talker / demo_nodes_py listener exchange messages.

Run from the repo root after `kas build kas/qemuarm64.yml`:
    tools/boot-test-qemuarm64.py

Exits 0 and prints PASS on success, non-zero and prints FAIL otherwise.
"""
import re
import sys
import time
from pathlib import Path

import pexpect

REPO_ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = REPO_ROOT / "build"
RUNQEMU = REPO_ROOT / "layers/openembedded-core/scripts/runqemu"
DEPLOY_DIR = BUILD_DIR / "tmp-glibc/deploy/images/qemuarm64"

BOOT_TIMEOUT = 240
LOGIN_TIMEOUT = 60
ROS_TIMEOUT = 30


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def find_qemuboot_conf():
    # Passing bare "qemuarm64" to runqemu hits a bug in this runqemu version
    # (self.bitbake_e ends up None -> TypeError in check_arg_machine). Passing
    # the built image's own qemuboot.conf sidesteps machine auto-detection
    # entirely and is more precise anyway (unambiguous about which image).
    matches = sorted(DEPLOY_DIR.glob("*.qemuboot.conf"))
    matches = [m for m in matches if not m.is_symlink()]
    if not matches:
        fail(f"no *.qemuboot.conf found under {DEPLOY_DIR} — did kas build kas/qemuarm64.yml run?")
    return matches[-1]


def main():
    if not RUNQEMU.exists():
        fail(f"runqemu not found at {RUNQEMU} — did kas build kas/qemuarm64.yml run?")

    qemuboot_conf = find_qemuboot_conf()
    child = pexpect.spawn(
        str(RUNQEMU),
        # default MACHINE RAM (256M) is tight for rclpy + DDS discovery with
        # two nodes at once; bump it for headroom.
        [str(qemuboot_conf), "nographic", "nonetwork", "qemuparams=-m 512"],
        cwd=str(BUILD_DIR),
        timeout=BOOT_TIMEOUT,
        encoding="utf-8",
        codec_errors="ignore",
    )
    child.logfile = sys.stdout

    try:
        child.expect(r"login:", timeout=BOOT_TIMEOUT)
        child.sendline("root")

        # debug-tweaks + allow-empty-password: either straight to a shell prompt,
        # or a Password: prompt that accepts an empty line.
        idx = child.expect([r"Password:", r"[#\$]\s*$"], timeout=LOGIN_TIMEOUT)
        if idx == 0:
            child.sendline("")
            child.expect(r"[#\$]\s*$", timeout=LOGIN_TIMEOUT)

        # Image has no bash (core-image-minimal base) -- busybox ash only. And
        # unlike a native colcon workspace, meta-ros's packaged /opt/ros/jazzy
        # has no generated setup.bash/setup.sh at all -- no environment hook is
        # installed on target, so the runtime env has to be set by hand.
        # (Worth carrying into Phase 4: Autoware images will need the same, via
        # a small profile.d recipe of our own -- a new recipe, not a hand-edit
        # of a generated one.)
        source_ros = (
            "export AMENT_PREFIX_PATH=/opt/ros/jazzy;"
            "export PATH=/opt/ros/jazzy/bin:$PATH;"
            "export PYTHONPATH=/opt/ros/jazzy/lib/python3.12/site-packages:$PYTHONPATH;"
            "export LD_LIBRARY_PATH=/opt/ros/jazzy/lib:$LD_LIBRARY_PATH;"
            # listener's stdout is block-buffered once redirected to a file, so
            # without this its "I heard: ..." prints never reach the log.
            "export PYTHONUNBUFFERED=1;"
        )
        # No `timeout` applet in this busybox build, so run both nodes as
        # background jobs and kill them by PID rather than relying on it.
        child.sendline(
            f"sh -c '{source_ros} ros2 run demo_nodes_py listener "
            "> /tmp/listener.log 2>&1 & echo LISTENER_PID:$!'"
        )
        child.expect(r"LISTENER_PID:(\d+)", timeout=ROS_TIMEOUT)
        listener_pid = child.match.group(1)
        child.expect(r"[#\$]\s*$", timeout=ROS_TIMEOUT)

        time.sleep(3)  # let the listener node finish coming up

        child.sendline(
            f"sh -c '{source_ros} ros2 run demo_nodes_cpp talker "
            "> /tmp/talker.log 2>&1 & echo TALKER_PID:$!'"
        )
        child.expect(r"TALKER_PID:(\d+)", timeout=ROS_TIMEOUT)
        talker_pid = child.match.group(1)
        child.expect(r"[#\$]\s*$", timeout=ROS_TIMEOUT)

        time.sleep(6)  # let a few publish/receive cycles happen

        child.sendline(f"kill {talker_pid} {listener_pid}; cat /tmp/listener.log")
        child.expect(r"[#\$]\s*$", timeout=ROS_TIMEOUT)
        listener_output = child.before

        child.sendline("poweroff -f")
        child.expect(pexpect.EOF, timeout=BOOT_TIMEOUT)

    except pexpect.TIMEOUT:
        fail(f"timed out waiting for expected output. Last buffer:\n{child.before}")
    finally:
        if child.isalive():
            child.terminate(force=True)

    if re.search(r"I heard: \[Hello World", listener_output):
        print("\nPASS: listener received talker messages")
        sys.exit(0)
    else:
        fail(f"listener log did not contain expected message:\n{listener_output}")


if __name__ == "__main__":
    main()
