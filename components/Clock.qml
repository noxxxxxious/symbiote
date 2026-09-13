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
    readonly property bool isRetracted: isHovered

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

    property real tendrilBlendRadiusRootOverride: 5
    property real tendrilBlendRadiusPanelOverride: 3
    property real tendrilWaistSmoothingOverride: 30

    property real tendrilGrowSpeedOverride: 0.35
    property real tendrilShrinkSpeedOverride: 0.25

    property int tendrilMaxTop: isBottom ? 0 : 4
    property int tendrilMaxBottom: isBottom ? 4 : 0
    property int tendrilMaxLeft: isRight ? 0 : 4
    property int tendrilMaxRight: isRight ? 4 : 0
    property int tendrilMaxCorners: 2

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
