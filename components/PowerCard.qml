import QtQuick
import "."

Item {
    id: card
    required property var menu
    required property int actionIndex
    property bool revealed: false
    readonly property var settings: Config.sAdapter.powerMenu
    readonly property real cardSize: Math.min(210, menu.width * 0.20, menu.height * 0.25)
    readonly property var centers: [[0.25, 0.30], [0.69, 0.28], [0.30, 0.70], [0.75, 0.68], [0.50, 0.49]]
    property real growth: revealed ? 1 : 0
    width: cardSize * growth
    height: cardSize * growth
    x: menu.width * centers[actionIndex][0] - width / 2
    y: menu.height * centers[actionIndex][1] - height / 2
    property real cornerRounding: Math.min(32, width / 2)
    visible: growth > 0.01
    Behavior on growth { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    Timer { id: revealTimer; onTriggered: card.revealed = true }
    function reveal(delay) { revealed = false; revealTimer.interval = Math.max(1, delay); revealTimer.restart() }
    function dismiss() { revealTimer.stop(); revealed = false }

    // Four explicit screen-edge fans, with one common profile for every card.
    property bool tendrilStaticGeometry: true
    property int tendrilExtraCount: settings.tendrilsPerSide
    property int tendrilSlotCapacityOverride: 8
    property real tendrilsPer100px: 0
    property int tendrilMaxTop: 0
    property int tendrilMaxBottom: 0
    property int tendrilMaxLeft: 0
    property int tendrilMaxRight: 0
    property int tendrilMaxCorners: 0
    property bool tendrilExtraConnections: true
    property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(menu.width + menu.height, menu.width + menu.height)
    property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(0.7, 1)
    property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(0.7, 1)
    property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(0.7, 1)
    property real tendrilExtraGrowSpeedOverride: 0.16
    property real tendrilExtraShrinkSpeedOverride: 0.18
    function extraTendrilSpecs() {
        var specs = []
        var n = Math.max(1, Math.min(2, tendrilExtraCount))
        var inset = Theme.borderThickness
        for (var side = 0; side < 4; ++side) {
            for (var i = 0; i < n; ++i) {
                var t = (i + 1) / (n + 1)
                // Different fixed root locations keep the four fans from lining up.
                var reach = 0.18 + 0.64 * ((actionIndex * 0.23 + side * 0.17 + t * 0.45) % 1)
                specs.push({
                    rootX: side === 1 ? menu.width - inset : side === 3 ? inset : menu.width * reach,
                    rootY: side === 0 ? inset : side === 2 ? menu.height - inset : menu.height * reach,
                    tipX: side === 1 ? x + width : side === 3 ? x : x + width * t,
                    tipY: side === 0 ? y : side === 2 ? y + height : y + height * t
                })
            }
        }
        return specs
    }

    Rectangle {
        anchors.fill: parent
        radius: card.cornerRounding
        color: hit.containsMouse && card.actionIndex !== 1 ? "#20ffffff" : "transparent"
    }
    Column {
        anchors.centerIn: parent
        spacing: 14 * card.growth
        opacity: card.growth * (card.actionIndex === 1 ? 0.45 : 1)
        Canvas {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            width: card.cardSize * 0.35 * card.growth; height: width
            onWidthChanged: requestPaint()
            property color ink: Theme.textColorAccent
            onInkChanged: requestPaint()
            onPaint: {
                var c = getContext("2d")
                c.reset(); c.scale(width / 100, height / 100)
                c.strokeStyle = ink; c.lineWidth = 6; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath()
                if (card.actionIndex === 0) {
                    c.arc(50, 53, 32, -Math.PI * 0.3, Math.PI * 1.3)
                    c.stroke(); c.beginPath(); c.moveTo(50, 12); c.lineTo(50, 48)
                } else if (card.actionIndex === 1) {
                    c.rect(23, 45, 54, 42); c.moveTo(32, 45); c.lineTo(32, 30)
                    c.arc(50, 30, 18, Math.PI, 0); c.lineTo(68, 45)
                } else if (card.actionIndex === 2) {
                    c.moveTo(65, 14); c.bezierCurveTo(5, 2, 0, 86, 60, 86)
                    c.bezierCurveTo(76, 86, 86, 78, 90, 67)
                    c.bezierCurveTo(43, 84, 30, 29, 65, 14)
                } else if (card.actionIndex === 3) {
                    c.arc(50, 52, 32, -Math.PI * 0.3, Math.PI * 1.5)
                    c.moveTo(50, 20); c.lineTo(65, 10); c.moveTo(50, 20); c.lineTo(63, 33)
                }
                if (card.actionIndex === 4) {
                    for (var i = 0; i < 24; ++i) {
                        var angle = i * Math.PI / 12
                        var radius = (i % 3 === 0 || i % 3 === 1) ? 38 : 29
                        var x = 50 + Math.cos(angle) * radius
                        var y = 50 + Math.sin(angle) * radius
                        if (i === 0) c.moveTo(x, y); else c.lineTo(x, y)
                    }
                    c.closePath(); c.stroke(); c.beginPath(); c.arc(50, 50, 13, 0, Math.PI * 2)
                }
                c.stroke()
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ["Shutdown", "Lock", "Sleep", "Restart", "Settings"][card.actionIndex]
            color: Theme.textColor
            font.pixelSize: Math.max(1, 22 * card.growth)
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.actionIndex === 1 ? "Coming later" : ""
            color: Theme.textColorSoft
            font.pixelSize: Math.max(1, 12 * card.growth)
        }
    }
    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.menu.isOpen && card.growth > 0.95 && !card.menu.busy
        cursorShape: card.actionIndex === 1 ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (card.actionIndex !== 1) card.menu.activate(card.actionIndex)
    }
}
