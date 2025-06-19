pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real cpuPerc
    property real cpuTemp
    property real gpuPerc
    property real gpuTemp
    property real gpuPstate
    property real gpuPowerDraw
    property real gpuFanSpeed
    property int memUsed
    property int memTotal
    readonly property real memPerc: memTotal > 0 ? memUsed / memTotal : 0
    property int storageUsed
    property int storageTotal
    property real storagePerc: storageTotal > 0 ? storageUsed / storageTotal : 0

    property int lastCpuIdle: 0
    property int lastCpuTotal: 0

    function formatKib(kib: int): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            storage.running = true;
            cpuTemp.running = true;
            gpuUsage.running = true;
            gpuTemp.running = true;
            gpuPowerDraw.running = true;
            gpuPstate.running = true;
            gpuFanSpeed.running = true;
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const data = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (data) {
                const stats = data.slice(1).map(n => parseInt(n, 10));
                const total = stats.reduce((a, b) => a + b, 0);
                const idle = stats[3] + stats[4] ?? 0;

                const totalDiff = total - root.lastCpuTotal;
                const idleDiff = idle - root.lastCpuIdle;
                root.cpuPerc = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0;

                root.lastCpuTotal = total;
                root.lastCpuIdle = idle;
            }
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const data = text();
            root.memTotal = parseInt(data.match(/MemTotal: *(\d+)/)[1], 10) || 1;
            root.memUsed = (root.memTotal - parseInt(data.match(/MemAvailable: *(\d+)/)[1], 10)) || 0;
        }
    }

    Process {
        id: storage

        running: true
        command: ["sh", "-c", "/bin/df / | grep '^/dev/' | awk '{print $1, $3, $4}'"]
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
              const deviceMap = new Map();

              for (const line of data.trim().split("\n")) {
                  if (line.trim() === "") continue;

                  const parts = line.trim().split(/\s+/);
                  if (parts.length >= 3) {
                      const device = parts[0];
                      const used = parseInt(parts[1], 10) || 0;
                      const avail = parseInt(parts[2], 10) || 0;
                      
                      // only keep the entry with the largest total space for each device
                      if (!deviceMap.has(device) || 
                          (used + avail) > (deviceMap.get(device).used + deviceMap.get(device).avail)) {
                          deviceMap.set(device, { used: used, avail: avail });
                      }
                  }
              }

              let totalUsed = 0;
              let totalAvail = 0;
  
              for (const [device, stats] of deviceMap) {
                  totalUsed += stats.used;
                  totalAvail += stats.avail;
              }

              root.storageUsed = totalUsed;
              root.storageTotal = totalUsed + totalAvail;
            }
        }
    }

    Process {
        id: cpuTemp

        running: true
        command: ["fish", "-c", "cat /sys/devices/pci0000:00/0000:00:18.3/hwmon/*/temp1_input"]
        stdout: SplitParser {
            onRead: data => {
                const temp = data.trim();
                root.cpuTemp = temp / 1000;
            }
        }
    }

    Process {
        id: gpuUsage

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuPerc = data / 100;
            }
        }
    }

    Process {
        id: gpuTemp

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuTemp = data;
            }
        }
    }

    Process {
        id: gpuPowerDraw

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuPowerDraw = data;
            }
        }
    }

    Process {
        id: gpuFanSpeed

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuFanSpeed = data;
            }
        }
    }

    Process {
        id: gpuPstate

        running: true
        command: ["sh", "-c", "nvidia-smi --query-gpu=pstate --format=csv,noheader,nounits"]
        stdout: SplitParser {
            onRead: data => {
                root.gpuPstate = data;
            }
        }
    }
}
