// components/SystemInfo.qml
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false
    width: 0
    height: 0

    property bool active: false

    property string cpuModel: "Detecting processor…"
    property int cpuThreads: 0
    property real cpuUsage: 0
    property real cpuTempC: -1

    property real memoryTotal: 0
    property real memoryUsed: 0
    property real memoryAvailable: 0
    property real memoryUsage: 0
    property real swapTotal: 0
    property real swapUsed: 0
    property real swapUsage: 0

    property string hostname: ""
    property string osName: ""
    property string kernelRelease: ""
    property real uptimeSeconds: 0
    property real load1: 0
    property real load5: 0
    property real load15: 0

    property var filesystems: []
    property var btrfsPools: []

    property real previousCpuTotal: -1
    property real previousCpuIdle: -1

    function cleanText(value) {
        return String(value || "").trim()
    }

    function unquote(value) {
        var s = cleanText(value)
        if (s.length >= 2 && s[0] === "\"" && s[s.length - 1] === "\"")
            return s.slice(1, -1)
        return s
    }

    function formatBytes(bytes) {
        var value = Number(bytes)
        if (!Number.isFinite(value) || value <= 0)
            return "0 B"

        var units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
        var unit = Math.min(
            units.length - 1,
            Math.max(0, Math.floor(Math.log(value) / Math.log(1024)))
        )
        var scaled = value / Math.pow(1024, unit)
        var digits = scaled >= 100 ? 0 : (scaled >= 10 ? 1 : 2)
        return scaled.toFixed(digits).replace(/\.?0+$/, "") + " " + units[unit]
    }

    function formatUptime(seconds) {
        var total = Math.max(0, Math.floor(Number(seconds) || 0))
        var days = Math.floor(total / 86400)
        var hours = Math.floor((total % 86400) / 3600)
        var minutes = Math.floor((total % 3600) / 60)

        if (days > 0)
            return days + "d " + hours + "h"
        if (hours > 0)
            return hours + "h " + minutes + "m"
        return minutes + "m"
    }

    function parseCpuInfo(raw) {
        var text = String(raw || "")
        if (!text.length)
            return

        var modelMatch = /^model name\s*:\s*(.+)$/m.exec(text)
        if (!modelMatch)
            modelMatch = /^hardware\s*:\s*(.+)$/mi.exec(text)
        if (!modelMatch)
            modelMatch = /^model\s*:\s*(.+)$/mi.exec(text)

        if (modelMatch)
            cpuModel = modelMatch[1].replace(/\s+/g, " ").trim()

        var threadMatches = text.match(/^processor\s*:/gm)
        cpuThreads = threadMatches ? threadMatches.length : 0
    }

    function parseCpuStat(raw) {
        var first = String(raw || "").split("\n")[0].trim()
        if (!first.startsWith("cpu "))
            return

        var fields = first.split(/\s+/).slice(1).map(Number)
        if (fields.length < 4)
            return

        var user = fields[0] || 0
        var nice = fields[1] || 0
        var system = fields[2] || 0
        var idle = fields[3] || 0
        var iowait = fields[4] || 0
        var irq = fields[5] || 0
        var softirq = fields[6] || 0
        var steal = fields[7] || 0

        var idleAll = idle + iowait
        var nonIdle = user + nice + system + irq + softirq + steal
        var total = idleAll + nonIdle

        if (previousCpuTotal >= 0) {
            var totalDelta = total - previousCpuTotal
            var idleDelta = idleAll - previousCpuIdle
            if (totalDelta > 0) {
                cpuUsage = Math.max(
                    0,
                    Math.min(100, (totalDelta - idleDelta) / totalDelta * 100)
                )
            }
        }

        previousCpuTotal = total
        previousCpuIdle = idleAll
    }

    function parseMemInfo(raw) {
        var lines = String(raw || "").split("\n")
        var values = {}

        for (var i = 0; i < lines.length; ++i) {
            var match = /^([^:]+):\s+(\d+)/.exec(lines[i])
            if (match)
                values[match[1]] = Number(match[2]) * 1024
        }

        var total = values.MemTotal || 0
        var available = values.MemAvailable
        if (available === undefined) {
            available = (values.MemFree || 0)
                + (values.Buffers || 0)
                + (values.Cached || 0)
        }

        memoryTotal = total
        memoryAvailable = available || 0
        memoryUsed = Math.max(0, total - memoryAvailable)
        memoryUsage = total > 0 ? memoryUsed / total : 0

        swapTotal = values.SwapTotal || 0
        var swapFree = values.SwapFree || 0
        swapUsed = Math.max(0, swapTotal - swapFree)
        swapUsage = swapTotal > 0 ? swapUsed / swapTotal : 0
    }

    function parseOsRelease(raw) {
        var text = String(raw || "")
        var match = /^PRETTY_NAME=(.+)$/m.exec(text)
        if (match) {
            osName = unquote(match[1])
            return
        }

        var name = /^NAME=(.+)$/m.exec(text)
        if (name)
            osName = unquote(name[1])
    }

    function parseUptime(raw) {
        var value = Number(cleanText(raw).split(/\s+/)[0])
        if (Number.isFinite(value))
            uptimeSeconds = value
    }

    function parseLoad(raw) {
        var fields = cleanText(raw).split(/\s+/)
        if (fields.length < 3)
            return

        load1 = Number(fields[0]) || 0
        load5 = Number(fields[1]) || 0
        load15 = Number(fields[2]) || 0
    }

    function parseStorageReport(raw) {
        var lines = String(raw || "").split("\n")
        var generic = []
        var genericSourceIndex = {}
        var poolsByKey = {}
        var poolOrder = []
        var snapshotsByKey = {}

        var ignoredTypes = {
            "tmpfs": true, "devtmpfs": true, "proc": true, "sysfs": true,
            "cgroup2": true, "squashfs": true, "overlay": true,
            "efivarfs": true, "pstore": true, "debugfs": true,
            "tracefs": true, "configfs": true, "securityfs": true,
            "fusectl": true, "mqueue": true, "hugetlbfs": true,
            "ramfs": true, "autofs": true
        }

        function numberOrZero(value) {
            var n = Number(value)
            return Number.isFinite(n) ? n : 0
        }

        for (var i = 0; i < lines.length; ++i) {
            var line = lines[i]
            if (!line.length)
                continue

            var fields = line.split("\t")
            var recordType = fields[0]

            if (recordType === "GENERIC" && fields.length >= 8) {
                var source = fields[1]
                var fsType = fields[2]
                var total = numberOrZero(fields[3])
                var used = numberOrZero(fields[4])
                var available = numberOrZero(fields[5])
                var percent = numberOrZero(fields[6])
                var target = fields.slice(7).join("\t")

                if (ignoredTypes[fsType] || total <= 0)
                    continue
                if (fsType === "fuse.portal" || target.indexOf("/run/user/") === 0)
                    continue

                var entry = {
                    source: source,
                    target: target,
                    fsType: fsType,
                    total: total,
                    used: Math.max(0, used),
                    available: Math.max(0, available),
                    usage: Math.max(0, Math.min(1, percent / 100))
                }

                if (genericSourceIndex[source] !== undefined) {
                    var existing = genericSourceIndex[source]
                    if (target === "/" && generic[existing].target !== "/")
                        generic[existing] = entry
                    continue
                }

                genericSourceIndex[source] = generic.length
                generic.push(entry)
                continue
            }

            if (recordType === "BTRFS_POOL" && fields.length >= 13) {
                var key = fields[1]
                var deviceSize = numberOrZero(fields[6])
                var usedBytes = numberOrZero(fields[9])

                poolsByKey[key] = {
                    key: key,
                    uuid: fields[2],
                    label: fields[3],
                    mountpoint: fields[4],
                    source: fields[5],
                    deviceSize: deviceSize,
                    allocated: numberOrZero(fields[7]),
                    unallocated: numberOrZero(fields[8]),
                    used: usedBytes,
                    freeEstimated: numberOrZero(fields[10]),
                    usage: deviceSize > 0
                        ? Math.max(0, Math.min(1, usedBytes / deviceSize))
                        : 0,
                    subvolumeCount: Math.max(0, Math.floor(numberOrZero(fields[11]))),
                    snapshotCount: Math.max(0, Math.floor(numberOrZero(fields[12]))),
                    snapshots: []
                }
                poolOrder.push(key)
                continue
            }

            if (recordType === "BTRFS_SNAPSHOT" && fields.length >= 3) {
                var snapshotKey = fields[1]
                if (!snapshotsByKey[snapshotKey])
                    snapshotsByKey[snapshotKey] = []

                snapshotsByKey[snapshotKey].push(fields.slice(2).join("\t"))
            }
        }

        generic.sort(function(a, b) {
            if (a.target === "/" && b.target !== "/") return -1
            if (b.target === "/" && a.target !== "/") return 1
            return a.target.localeCompare(b.target)
        })

        var pools = []
        for (var p = 0; p < poolOrder.length; ++p) {
            var poolKey = poolOrder[p]
            var pool = poolsByKey[poolKey]
            if (!pool)
                continue

            var snapshots = snapshotsByKey[poolKey] || []
            snapshots.sort(function(a, b) {
                return String(a).localeCompare(String(b), undefined, { numeric: true })
            })

            pool.snapshots = snapshots
            pool.snapshotCount = snapshots.length
            pools.push(pool)
        }

        pools.sort(function(a, b) {
            if (a.mountpoint === "/" && b.mountpoint !== "/") return -1
            if (b.mountpoint === "/" && a.mountpoint !== "/") return 1
            return a.source.localeCompare(b.source)
        })

        filesystems = generic
        btrfsPools = pools
    }

    FileView {
        id: cpuInfoFile
        path: root.active ? "/proc/cpuinfo" : ""
        printErrors: false
        onTextChanged: root.parseCpuInfo(text())
    }

    FileView {
        id: cpuStatFile
        path: root.active ? "/proc/stat" : ""
        printErrors: false
        onTextChanged: root.parseCpuStat(text())
    }

    FileView {
        id: memInfoFile
        path: root.active ? "/proc/meminfo" : ""
        printErrors: false
        onTextChanged: root.parseMemInfo(text())
    }

    FileView {
        id: osReleaseFile
        path: root.active ? "/etc/os-release" : ""
        printErrors: false
        onTextChanged: root.parseOsRelease(text())
    }

    FileView {
        id: hostnameFile
        path: root.active ? "/proc/sys/kernel/hostname" : ""
        printErrors: false
        onTextChanged: root.hostname = root.cleanText(text())
    }

    FileView {
        id: kernelFile
        path: root.active ? "/proc/sys/kernel/osrelease" : ""
        printErrors: false
        onTextChanged: root.kernelRelease = root.cleanText(text())
    }

    FileView {
        id: uptimeFile
        path: root.active ? "/proc/uptime" : ""
        printErrors: false
        onTextChanged: root.parseUptime(text())
    }

    FileView {
        id: loadFile
        path: root.active ? "/proc/loadavg" : ""
        printErrors: false
        onTextChanged: root.parseLoad(text())
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            cpuStatFile.reload()
            memInfoFile.reload()
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            uptimeFile.reload()
            loadFile.reload()
            if (!temperatureProcess.running)
                temperatureProcess.running = true
        }
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: {
            if (!storageProcess.running)
                storageProcess.running = true
        }
    }

    Process {
        id: temperatureProcess
        command: [
            "sh",
            "-c",
            "best=; for d in /sys/class/hwmon/hwmon*; do "
            + "[ -r \"$d/name\" ] || continue; "
            + "n=$(cat \"$d/name\" 2>/dev/null); "
            + "case \"$n\" in coretemp|k10temp|zenpower|cpu_thermal|soc_thermal) "
            + "for f in \"$d\"/temp*_input; do [ -r \"$f\" ] || continue; "
            + "v=$(cat \"$f\" 2>/dev/null); case \"$v\" in ''|*[!0-9-]*) continue;; esac; "
            + "if [ \"$v\" -gt 0 ] 2>/dev/null && [ \"$v\" -lt 150000 ] 2>/dev/null; then "
            + "if [ -z \"$best\" ] || [ \"$v\" -gt \"$best\" ]; then best=$v; fi; fi; "
            + "done;; esac; done; [ -n \"$best\" ] && printf '%s\\n' \"$best\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                var raw = Number(text.trim())
                root.cpuTempC = Number.isFinite(raw) && raw > 0
                    ? raw / 1000.0
                    : -1
            }
        }
    }

    Process {
        id: storageProcess
        command: [
            "bash",
            Quickshell.shellDir + "/components/system-info-storage.sh"
        ]

        stdout: StdioCollector {
            onStreamFinished: root.parseStorageReport(text)
        }
    }

    onActiveChanged: {
        if (active) {
            previousCpuTotal = -1
            previousCpuIdle = -1

            Qt.callLater(function() {
                cpuInfoFile.reload()
                osReleaseFile.reload()
                hostnameFile.reload()
                kernelFile.reload()
            })
        }
    }
}
