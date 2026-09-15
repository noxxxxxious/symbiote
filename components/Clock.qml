// components/Clock.qml
pragma ComponentBehavior: Bound
import QtQuick
import "."

Item {
    id: root

    required property var targetScreen
    required property real screenWidth
    required property real screenHeight

    // -------------------------------------------------------------------------
    // Position & Retraction Configuration
    // -------------------------------------------------------------------------
    // Options: "top-left", "top-right", "bottom-left", "bottom-right"
    property string cornerPosition: Theme.clockCornerPosition

    // Options: "vertical", "horizontal", "diagonal"
    property string slideDirection: Theme.clockSlideDirection

    property real margin: 10
    property real finalWidth: 160
    property real finalHeight: 52

    // Default scalar rounding for inner widget corners
    property real cornerRounding: 16

    // The border-matching radius for whichever corner is docked to the screen border
    readonly property real dockedRounding: Math.min(Theme.borderRounding, Math.min(finalWidth, finalHeight) / 2)

    // Per-corner radii calculations (TL, TR, BR, BL)
    readonly property real radiusTL: (cornerPosition === "top-left") ? dockedRounding : cornerRounding
    readonly property real radiusTR: (cornerPosition === "top-right") ? dockedRounding : cornerRounding
    readonly property real radiusBR: (cornerPosition === "bottom-right") ? dockedRounding : cornerRounding
    readonly property real radiusBL: (cornerPosition === "bottom-left") ? dockedRounding : cornerRounding

    // Vector4D sent to Border.qml -> border.frag (vec4 clockRounding)
    readonly property vector4d cornerRadii: Qt.vector4d(radiusTL, radiusTR, radiusBR, radiusBL)

    // Dominant scalar rounding for TendrilManager perimeter calculations
    readonly property real panelCornerRounding: cornerRounding

    // Hover / Retraction state (driven from shell.qml)
    property bool isHovered: false
    property string mode: Config.sAdapter.clock.mode
    property bool isEngaged: false
    property bool pointerInside: false
    property bool edgeHovered: false
    readonly property bool isRetracted: mode === "subdermal" ? !isEngaged : isHovered

    function summon() {
        isEngaged = true
        hideTimer.restart()
    }
    onPointerInsideChanged: {
        if (pointerInside) hideTimer.stop()
        else if (isEngaged) hideTimer.restart()
    }
    onEdgeHoveredChanged: {
        if (edgeHovered) summon()
        else if (isEngaged && !pointerInside) hideTimer.restart()
    }
    onModeChanged: {
        hideTimer.stop()
        isEngaged = false
        isHovered = false
    }
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: {
            if (!root.pointerInside && !root.edgeHovered) root.isEngaged = false
        }
    }

    width: finalWidth
    height: finalHeight

    // -------------------------------------------------------------------------
    // Resting Coordinate Calculations
    // -------------------------------------------------------------------------
    readonly property bool isRight: cornerPosition.indexOf("right") !== -1
    readonly property bool isBottom: cornerPosition.indexOf("bottom") !== -1

    readonly property real restingX: isRight
        ? screenWidth - Theme.borderThickness - margin - width
        : Theme.borderThickness + margin

    readonly property real restingY: isBottom
        ? screenHeight - Theme.borderThickness - margin - height
        : Theme.borderThickness + margin

    // Travel distance to clear screen view
    readonly property real travelX: width + margin + Theme.borderThickness + 40
    readonly property real travelY: height + margin + Theme.borderThickness + 40

    readonly property real hiddenX: {
        if (slideDirection === "vertical") return restingX;
        return isRight ? (restingX + travelX) : (restingX - travelX);
    }

    readonly property real hiddenY: {
        if (slideDirection === "horizontal") return restingY;
        return isBottom ? (restingY + travelY) : (restingY - travelY);
    }

    x: isRetracted ? hiddenX : restingX
    y: isRetracted ? hiddenY : restingY

    Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.InOutQuad } }
    Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.InOutQuad } }

    // -------------------------------------------------------------------------
    // Tendril Overrides for TendrilManager
    // -------------------------------------------------------------------------
    property real tendrilsPer100px: 3
    property int tendrilMaxActive: 10
    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(20, 30)
    property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(1, 1)
    property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(1, 1)
    property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(1, 1)
    property bool tendrilUseScreenRelativeAttachDistance: false
    property real tendrilAttachOffset: 0

    property real tendrilBlendRadiusRootOverride: 10
    property real tendrilBlendRadiusPanelOverride: 6
    property real tendrilWaistSmoothingOverride: 30

    property real tendrilGrowSpeedOverride: 0.35
    property real tendrilShrinkSpeedOverride: 0.25

    property int tendrilMaxTop: isBottom ? 0 : 4
    property int tendrilMaxBottom: isBottom ? 4 : 0
    property int tendrilMaxLeft: isRight ? 0 : 4
    property int tendrilMaxRight: isRight ? 4 : 0
    property int tendrilMaxCorners: 2

    // -------------------------------------------------------------------------
    // Optional cross-reach tendrils
    // -------------------------------------------------------------------------
    // Horizontal = roots on the top/bottom screen border.
    // Vertical = roots on the left/right screen border.
    property bool tendrilExtraConnections: Config.sAdapter.clock.extraTendrils
    property real tendrilExtraVerticalReach: Config.sAdapter.clock.extraVerticalReach
    property real tendrilExtraHorizontalReach: Config.sAdapter.clock.extraHorizontalReach
    property int tendrilExtraVerticalCount: Config.sAdapter.clock.extraVerticalCount ?? 2
    property int tendrilExtraHorizontalCount: Config.sAdapter.clock.extraHorizontalCount ?? 2
    property real tendrilExtraVerticalReachSpread: Config.sAdapter.clock.extraVerticalReachSpread ?? 0.12
    property real tendrilExtraHorizontalReachSpread: Config.sAdapter.clock.extraHorizontalReachSpread ?? 0.12
    property real tendrilExtraVerticalTipSpread: Config.sAdapter.clock.extraVerticalTipSpread ?? 0.55
    property real tendrilExtraHorizontalTipSpread: Config.sAdapter.clock.extraHorizontalTipSpread ?? 0.55

    property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(900, 2200)
    property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(4, 9)
    property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(1, 2)
    property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(2, 4)
    property real tendrilExtraBlendRadiusRootOverride: 50
    property real tendrilExtraBlendRadiusPanelOverride: 30
    property real tendrilExtraWaistSmoothingOverride: 70
    property real tendrilExtraGrowSpeedOverride: 0.10
    property real tendrilExtraShrinkSpeedOverride: 0.08

    function extraTendrilSpecs() {
        if (!tendrilExtraConnections) return []
        var left = Theme.borderThickness
        var top = Theme.borderThickness
        var right = root.screenWidth - Theme.borderThickness
        var bottom = root.screenHeight - Theme.borderThickness
        var usableWidth = Math.max(1, right - left)
        var usableHeight = Math.max(1, bottom - top)
        var verticalCount = Math.max(0, Math.floor(tendrilExtraVerticalCount))
        var horizontalCount = Math.max(0, Math.floor(tendrilExtraHorizontalCount))
        var specs = []

        function clampValue(value, minimum, maximum) { return Math.max(minimum, Math.min(maximum, value)) }
        function distributedReach(base, index, count, spread) {
            var center = clampValue(base, 0.05, 0.95)
            if (count <= 1) return center
            var maxHalfSpan = Math.max(0, Math.min(center - 0.05, 0.95 - center))
            var halfSpan = Math.min(Math.max(0, spread) * 0.5, maxHalfSpan)
            return center + ((index / (count - 1)) * 2.0 - 1.0) * halfSpan
        }
        function distributedTip(index, count, spread, reverse) {
            var t = count <= 1 ? 0.5 : index / (count - 1)
            if (reverse) t = 1.0 - t
            return clampValue(0.5 + (t - 0.5) * 0.9 * spread, 0.05, 0.95)
        }
        function addHorizontalFan(borderY, fromRight, tipX) {
            for (var i = 0; i < horizontalCount; i++) {
                var reach = distributedReach(tendrilExtraHorizontalReach, i, horizontalCount, tendrilExtraHorizontalReachSpread)
                var tip = distributedTip(i, horizontalCount, tendrilExtraHorizontalTipSpread, isBottom)
                specs.push({ side: "extra-horizontal", rootX: fromRight ? right - usableWidth * reach : left + usableWidth * reach, rootY: borderY, tipX: tipX, tipY: y + height * tip })
            }
        }
        function addVerticalFan(borderX, fromBottom, tipY) {
            for (var i = 0; i < verticalCount; i++) {
                var reach = distributedReach(tendrilExtraVerticalReach, i, verticalCount, tendrilExtraVerticalReachSpread)
                var tip = distributedTip(i, verticalCount, tendrilExtraVerticalTipSpread, isRight)
                specs.push({ side: "extra-vertical", rootX: borderX, rootY: fromBottom ? bottom - usableHeight * reach : top + usableHeight * reach, tipX: x + width * tip, tipY: tipY })
            }
        }

        addHorizontalFan(isBottom ? bottom : top, isRight, isRight ? x : x + width)
        addVerticalFan(isRight ? right : left, isBottom, isBottom ? y : y + height)
        return specs
    }

    // -------------------------------------------------------------------------
    // Time & Date Formatter
    // -------------------------------------------------------------------------
    property string hourStr: "00"
    property string minuteStr: "00"
    property string secondStr: "00"
    property string weekdayStr: "---"
    property string monthStr: "---"
    property string dayStr: "0"

    readonly property real hourSize: root.height * 0.72
    readonly property real minuteSize: root.height * 0.44
    readonly property real labelSize: root.height * 0.20
    property real verticalSquish: 0.85

    function refresh() {
        const now = new Date();
        hourStr = Qt.formatDateTime(now, "hh");
        minuteStr = Qt.formatDateTime(now, "mm");
        secondStr = Qt.formatDateTime(now, "ss");
        weekdayStr = Qt.formatDateTime(now, "ddd").toUpperCase();
        monthStr = Qt.formatDateTime(now, "MMM").toUpperCase();
        dayStr = Qt.formatDateTime(now, "d");
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    component TightText: Item {
        id: wrap
        property alias text: label.text
        property alias font: label.font
        property color textColor: "white"
        property real tightHeight: font.pixelSize * root.verticalSquish

        implicitWidth: label.implicitWidth
        implicitHeight: tightHeight
        height: tightHeight

        Text {
            id: label
            anchors.centerIn: parent
            color: wrap.textColor
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        TightText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.hourStr
            textColor: Theme.textColorAccent
            font.pixelSize: root.hourSize
            font.bold: true
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            TightText {
                id: minuteLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.minuteStr
                textColor: Theme.textColor
                font.pixelSize: root.minuteSize
                font.bold: true
            }

            TightText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.weekdayStr
                textColor: Theme.textColorSoft
                font.pixelSize: root.labelSize
                font.bold: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            TightText {
                text: root.secondStr
                textColor: Theme.textColorSoft
                font.pixelSize: root.labelSize
                font.bold: true
            }
            TightText {
                text: root.monthStr
                textColor: Theme.textColorAccent
                font.pixelSize: root.labelSize
            }
            TightText {
                text: root.dayStr
                textColor: Theme.textColor
                font.pixelSize: root.labelSize
            }
        }
    }
}
