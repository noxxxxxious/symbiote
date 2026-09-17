// components/dashboard/InfoTab.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "." as DashboardParts

Item {
    id: root

    required property var systemInfo

    readonly property var dashboardConfig: Config.sAdapter.dashboard

    function accent(alpha) {
        return Qt.rgba(
            Theme.textColorAccent.r,
            Theme.textColorAccent.g,
            Theme.textColorAccent.b,
            alpha
        )
    }

    function labelOr(value, fallback) {
        var text = String(value || "").trim()
        return text.length ? text : fallback
    }

    function storageName(target, label, fsType) {
        if (label && label.length)
            return label
        if (target === "/")
            return "ROOT"

        var cleaned = String(target || "").replace(/\/+$/, "")
        var parts = cleaned.split("/")
        var last = parts.length ? parts[parts.length - 1] : ""
        return last.length
            ? last.toUpperCase()
            : String(fsType || "STORAGE").toUpperCase()
    }

    function storageCount() {
        return systemInfo.filesystems.length + systemInfo.btrfsPools.length
    }

    function compactBytesPair(usedBytes, totalBytes) {
        var total = Math.max(0, Number(totalBytes) || 0)
        var used = Math.max(0, Number(usedBytes) || 0)

        if (total <= 0)
            return "0 / 0 B"

        var units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
        var unit = Math.min(
            units.length - 1,
            Math.max(0, Math.floor(Math.log(total) / Math.log(1024)))
        )
        var divisor = Math.pow(1024, unit)

        function shortNumber(value) {
            if (value >= 100)
                return value.toFixed(0)
            if (value >= 10)
                return value.toFixed(1).replace(/\.0$/, "")
            return value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "")
        }

        return shortNumber(used / divisor)
            + " / "
            + shortNumber(total / divisor)
            + " "
            + units[unit]
    }

    function snapshotDisplayName(path) {
        var value = String(path || "").replace(/^\/+/, "")
        if (!value.length)
            return "snapshot"

        var snapper = /(?:^|\/)\.snapshots\/(\d+)\/snapshot$/.exec(value)
        if (snapper)
            return "#" + snapper[1]

        return value
    }

    function snapshotList(pool) {
        var list = pool.snapshots || []
        if (!list.length)
            return "None"

        var names = []
        for (var i = 0; i < list.length; ++i)
            names.push(snapshotDisplayName(list[i]))

        return names.join(" · ")
    }

    component UsageGauge: Item {
        id: gauge

        required property real value
        property int segments: 18
        property string footer: "USED"

        implicitWidth: 68
        implicitHeight: 68

        onValueChanged: arc.requestPaint()
        onWidthChanged: arc.requestPaint()
        onHeightChanged: arc.requestPaint()

        Canvas {
            id: arc
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cx = width / 2
                var cy = height / 2
                var line = Math.max(4, Math.min(width, height) * 0.085)
                var radius = Math.max(1, Math.min(width, height) / 2 - line)
                var start = Math.PI * 0.72
                var sweep = Math.PI * 1.56
                var segmentSweep = sweep / gauge.segments
                var gap = segmentSweep * 0.26
                var active = Math.round(
                    Math.max(0, Math.min(1, gauge.value)) * gauge.segments
                )

                ctx.lineWidth = line
                ctx.lineCap = "round"

                for (var i = 0; i < gauge.segments; ++i) {
                    var a0 = start + i * segmentSweep + gap / 2
                    var a1 = start + (i + 1) * segmentSweep - gap / 2
                    ctx.beginPath()
                    ctx.strokeStyle = i < active
                        ? Theme.textColorAccent
                        : root.accent(0.14)
                    ctx.arc(cx, cy, radius, a0, a1, false)
                    ctx.stroke()
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: -2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(
                    Math.max(0, Math.min(1, gauge.value)) * 100
                ) + "%"
                color: Theme.textColor
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gauge.footer
                color: Theme.textColorSoft
                font.pixelSize: 7
                font.bold: true
                font.letterSpacing: 0.7
            }
        }
    }

    component IdentityStat: Column {
        id: stat

        required property string label
        required property string value

        spacing: 1

        Text {
            width: parent.width
            text: stat.label.toUpperCase()
            color: Theme.textColorAccent
            font.pixelSize: 8
            font.bold: true
            font.letterSpacing: 0.9
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: stat.value
            color: Theme.textColor
            font.pixelSize: 10
            font.bold: true
            elide: Text.ElideMiddle
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 208
            Layout.minimumWidth: 190
            Layout.fillHeight: true

            radius: 13
            color: Qt.rgba(
                Theme.secondaryColor.r,
                Theme.secondaryColor.g,
                Theme.secondaryColor.b,
                0.66
            )
            border.width: 1
            border.color: root.accent(0.16)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 5

                Text {
                    Layout.fillWidth: true
                    text: root.labelOr(
                        root.dashboardConfig.infoSystemName,
                        "Organism"
                    ).toUpperCase()
                    color: Theme.textColorAccent
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1.4
                    horizontalAlignment: Text.AlignLeft
                }

                DashboardParts.SymbioteMark {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    Layout.maximumHeight: 118
                }

                Text {
                    Layout.fillWidth: true
                    text: root.systemInfo.hostname.length
                        ? root.systemInfo.hostname
                        : "Detecting host…"
                    color: Theme.textColor
                    font.pixelSize: 23
                    font.bold: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    Layout.fillWidth: true
                    text: root.systemInfo.osName
                    color: Theme.textColorSoft
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignLeft
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 5
                    Layout.bottomMargin: 4
                    color: root.accent(0.14)
                }

                IdentityStat {
                    Layout.fillWidth: true
                    label: "Kernel"
                    value: root.systemInfo.kernelRelease.length
                        ? root.systemInfo.kernelRelease
                        : "—"
                }

                IdentityStat {
                    Layout.fillWidth: true
                    label: "Uptime"
                    value: root.systemInfo.formatUptime(
                        root.systemInfo.uptimeSeconds
                    )
                }

                IdentityStat {
                    Layout.fillWidth: true
                    label: "Load 1 / 5 / 15"
                    value: root.systemInfo.load1.toFixed(2)
                        + "  "
                        + root.systemInfo.load5.toFixed(2)
                        + "  "
                        + root.systemInfo.load15.toFixed(2)
                }

                Item { Layout.fillHeight: true }
            }
        }

        Flickable {
            id: resourceFlick

            Layout.fillWidth: true
            Layout.fillHeight: true

            contentWidth: width
            contentHeight: resourceColumn.implicitHeight
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {
                policy: resourceFlick.contentHeight > resourceFlick.height
                    ? ScrollBar.AsNeeded
                    : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: resourceColumn

                width: resourceFlick.width - (
                    resourceFlick.contentHeight > resourceFlick.height ? 8 : 0
                )
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    radius: 12
                    color: Qt.rgba(
                        Theme.secondaryColor.r,
                        Theme.secondaryColor.g,
                        Theme.secondaryColor.b,
                        0.72
                    )
                    border.width: 1
                    border.color: root.accent(0.18)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 11

                        UsageGauge {
                            Layout.preferredWidth: 66
                            Layout.preferredHeight: 66
                            Layout.alignment: Qt.AlignVCenter
                            value: root.systemInfo.cpuUsage / 100.0
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: root.labelOr(
                                        root.dashboardConfig.infoProcessorName,
                                        "Nucleus"
                                    ).toUpperCase()
                                    color: Theme.textColorAccent
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.2
                                }

                                Text {
                                    text: root.systemInfo.cpuTempC >= 0
                                        ? root.systemInfo.cpuTempC.toFixed(0) + "°C"
                                        : "—"
                                    color: Theme.textColorSoft
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.systemInfo.cpuModel
                                color: Theme.textColor
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: root.systemInfo.cpuThreads > 0
                                        ? root.systemInfo.cpuThreads + " logical threads"
                                        : "Detecting threads…"
                                    color: Theme.textColorSoft
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "load "
                                        + root.systemInfo.load1.toFixed(2)
                                        + " / "
                                        + root.systemInfo.load5.toFixed(2)
                                        + " / "
                                        + root.systemInfo.load15.toFixed(2)
                                    color: Theme.textColorSoft
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
                    radius: 12
                    color: Qt.rgba(
                        Theme.secondaryColor.r,
                        Theme.secondaryColor.g,
                        Theme.secondaryColor.b,
                        0.72
                    )
                    border.width: 1
                    border.color: root.accent(0.18)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 11

                        UsageGauge {
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 62
                            Layout.alignment: Qt.AlignVCenter
                            value: root.systemInfo.memoryUsage
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.labelOr(
                                    root.dashboardConfig.infoMemoryName,
                                    "Synapses"
                                ).toUpperCase()
                                color: Theme.textColorAccent
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.2
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.compactBytesPair(
                                    root.systemInfo.memoryUsed,
                                    root.systemInfo.memoryTotal
                                )
                                color: Theme.textColor
                                font.pixelSize: 17
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: root.systemInfo.formatBytes(
                                        root.systemInfo.memoryAvailable
                                    ) + " available"
                                    color: Theme.textColorSoft
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.systemInfo.swapTotal > 0
                                        ? "swap "
                                            + root.compactBytesPair(
                                                root.systemInfo.swapUsed,
                                                root.systemInfo.swapTotal
                                            )
                                        : "swap disabled"
                                    color: Theme.textColorSoft
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.labelOr(
                            root.dashboardConfig.infoStorageName,
                            "Genome"
                        ).toUpperCase()
                        color: Theme.textColorAccent
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: root.storageCount()
                            + (root.storageCount() === 1
                                ? " FILESYSTEM"
                                : " FILESYSTEMS")
                        color: Theme.textColorSoft
                        font.pixelSize: 8
                        font.letterSpacing: 0.7
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 7

                    Repeater {
                        model: root.systemInfo.btrfsPools

                        delegate: Rectangle {
                            id: btrfsCard

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 92
                            radius: 10
                            color: Qt.rgba(
                                Theme.secondaryColor.r,
                                Theme.secondaryColor.g,
                                Theme.secondaryColor.b,
                                0.64
                            )
                            border.width: 1
                            border.color: root.accent(0.15)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                UsageGauge {
                                    Layout.preferredWidth: 58
                                    Layout.preferredHeight: 58
                                    Layout.alignment: Qt.AlignVCenter
                                    value: btrfsCard.modelData.usage
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 5

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.storageName(
                                                btrfsCard.modelData.mountpoint,
                                                btrfsCard.modelData.label,
                                                "btrfs"
                                            )
                                            color: Theme.textColor
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: "BTRFS"
                                            color: Theme.textColorAccent
                                            font.pixelSize: 7
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.compactBytesPair(
                                            btrfsCard.modelData.used,
                                            btrfsCard.modelData.deviceSize
                                        )
                                        color: Theme.textColor
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.systemInfo.formatBytes(
                                            btrfsCard.modelData.freeEstimated
                                        ) + " free · " + btrfsCard.modelData.source
                                        color: Theme.textColorSoft
                                        font.pixelSize: 8
                                        elide: Text.ElideMiddle
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: "SNAPSHOTS"
                                            color: Theme.textColorAccent
                                            font.pixelSize: 7
                                            font.bold: true
                                            font.letterSpacing: 0.5
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.snapshotList(
                                                btrfsCard.modelData
                                            )
                                            color: Theme.textColorSoft
                                            font.pixelSize: 7
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: btrfsCard.modelData.snapshotCount > 0
                                            text: String(
                                                btrfsCard.modelData.snapshotCount
                                            )
                                            color: Theme.textColorAccent
                                            font.pixelSize: 7
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.systemInfo.filesystems

                        delegate: Rectangle {
                            id: diskCard

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            radius: 10
                            color: Qt.rgba(
                                Theme.secondaryColor.r,
                                Theme.secondaryColor.g,
                                Theme.secondaryColor.b,
                                0.60
                            )
                            border.width: 1
                            border.color: root.accent(0.12)

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                UsageGauge {
                                    Layout.preferredWidth: 56
                                    Layout.preferredHeight: 56
                                    Layout.alignment: Qt.AlignVCenter
                                    value: diskCard.modelData.usage
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 1

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            Layout.fillWidth: true
                                            text: root.storageName(
                                                diskCard.modelData.target,
                                                "",
                                                diskCard.modelData.fsType
                                            )
                                            color: Theme.textColor
                                            font.pixelSize: 11
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: String(
                                                diskCard.modelData.fsType
                                            ).toUpperCase()
                                            color: Theme.textColorAccent
                                            font.pixelSize: 7
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.compactBytesPair(
                                            diskCard.modelData.used,
                                            diskCard.modelData.total
                                        )
                                        color: Theme.textColor
                                        font.pixelSize: 14
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Item { Layout.fillHeight: true }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.systemInfo.formatBytes(
                                            diskCard.modelData.available
                                        ) + " free · " + diskCard.modelData.source
                                        color: Theme.textColorSoft
                                        font.pixelSize: 8
                                        elide: Text.ElideMiddle
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.storageCount() === 0
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Detecting mounted storage…"
                        color: Theme.textColorSoft
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
