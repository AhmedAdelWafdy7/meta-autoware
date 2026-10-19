#!/bin/sh
# Run on the target: boot time, idle memory, rootfs size, and the
# memory of one running Autoware node. Prints one "key: value" per line.
# Usage: ssh root@<target> sh -s < tools/measure-target.sh
set -u

ROS_SHARE=/opt/ros/jazzy/share
SETTLE=30

echo "machine: $(uname -m) $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')"
echo "kernel: $(uname -r)"

# systemd-analyze needs the boot to have finished
i=0
while ! systemctl is-system-running --quiet 2>/dev/null && [ $i -lt 300 ]; do
    [ "$(systemctl is-system-running 2>/dev/null)" = "degraded" ] && break
    sleep 1; i=$((i+1))
done
echo "boot: $(systemd-analyze 2>/dev/null | head -1)"

echo "rootfs_used_kb: $(df -k / | awk 'NR==2 {print $3}')"
echo "mem_total_kb: $(awk '/MemTotal/ {print $2}' /proc/meminfo)"
sleep "$SETTLE"
echo "mem_available_idle_kb: $(awk '/MemAvailable/ {print $2}' /proc/meminfo)"

. /opt/ros/jazzy/setup.sh
ros2 run autoware_simple_pure_pursuit autoware_simple_pure_pursuit_exe --ros-args \
    --params-file "$ROS_SHARE/autoware_vehicle_info_utils/config/vehicle_info.param.yaml" \
    --params-file "$ROS_SHARE/autoware_simple_pure_pursuit/config/simple_pure_pursuit.param.yaml" \
    > /tmp/pure_pursuit.log 2>&1 &
RUN_PID=$!

i=0
pid=""
while [ -z "$pid" ] && [ $i -lt 120 ]; do
    pid=$(pgrep -f 'lib/autoware_simple_pure_pursuit/autoware_simple_pure_pursuit_exe' | head -1)
    sleep 1; i=$((i+1))
done
if [ -z "$pid" ]; then
    echo "node: did not start"
    cat /tmp/pure_pursuit.log
    exit 1
fi
sleep "$SETTLE"
echo "node_pid: $pid"
echo "node_rss_kb: $(awk '/VmRSS/ {print $2}' /proc/$pid/status)"
echo "mem_available_node_kb: $(awk '/MemAvailable/ {print $2}' /proc/meminfo)"

kill "$RUN_PID" "$pid" 2>/dev/null
wait "$RUN_PID" 2>/dev/null
