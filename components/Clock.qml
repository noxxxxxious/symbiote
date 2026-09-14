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
    // Optional long cross-reach tendrils
    // -------------------------------------------------------------------------
    property bool tendrilExtraConnections:
        Config.sAdapter.clock.extraTendrils

    // Normalized 0..1 root placement along the target screen edge.
    property real tendrilExtraShortReach:
        Config.sAdapter.clock.extraShortReach

    property real tendrilExtraLongReach:
        Config.sAdapter.clock.extraLongReach

    // One extra tendril from each relevant clock side, for now.
    property int tendrilExtraShortCount:
        Config.sAdapter.clock.extraShortCount !== undefined
        ? Config.sAdapter.clock.extraShortCount
        : 3

    property int tendrilExtraLongCount:
        Config.sAdapter.clock.extraLongCount !== undefined
        ? Config.sAdapter.clock.extraLongCount
        : 3

    // Independent visual profile for long extra tendrils.
    // These must be substantially larger than the normal clock range.
    property vector2d tendrilExtraMaxLengthRangeOverride:
        Qt.vector2d(900, 2200)

    property vector2d tendrilExtraRootThicknessRangeOverride:
        Qt.vector2d(4, 9)

    property vector2d tendrilExtraWaistThicknessRangeOverride:
        Qt.vector2d(1, 2)

    property vector2d tendrilExtraPanelThicknessRangeOverride:
        Qt.vector2d(2, 4)

    // Long strands need a broader blend at the screen-border root.
    property real tendrilExtraBlendRadiusRootOverride: 24
    property real tendrilExtraBlendRadiusPanelOverride: 16
    property real tendrilExtraWaistSmoothingOverride: 70

    // Slightly slower reads more intentional for long diagonal connections.
    property real tendrilExtraGrowSpeedOverride: 0.10
    property real tendrilExtraShrinkSpeedOverride: 0.08

    // Spread of roots along their target screen border.
    // This changes the width of the fan at the screen edge.
    property real tendrilExtraShortReachSpread:
        Config.sAdapter.clock.extraShortReachSpread !== undefined
        ? Config.sAdapter.clock.extraShortReachSpread
        : 0.12

    property real tendrilExtraLongReachSpread:
        Config.sAdapter.clock.extraLongReachSpread !== undefined
        ? Config.sAdapter.clock.extraLongReachSpread
        : 0.12

    // Spread of the clock-side tips along the relevant clock edge.
    // 0.0 means all tips meet at the edge center.
    // 1.0 means tips span almost the whole usable clock edge.
    property real tendrilExtraShortTipSpread:
        Config.sAdapter.clock.extraShortTipSpread !== undefined
        ? Config.sAdapter.clock.extraShortTipSpread
        : 0.55

    property real tendrilExtraLongTipSpread:
        Config.sAdapter.clock.extraLongTipSpread !== undefined
        ? Config.sAdapter.clock.extraLongTipSpread
        : 0.55

    function extraClockTendrilSpecs() {
        if (!tendrilExtraConnections)
            return [];

        var left = Theme.borderThickness;
        var top = Theme.borderThickness;
        var right = root.screenWidth - Theme.borderThickness;
        var bottom = root.screenHeight - Theme.borderThickness;

        var usableWidth = Math.max(1, right - left);
        var usableHeight = Math.max(1, bottom - top);

        var baseShort = Math.max(
            0.05,
            Math.min(0.95, tendrilExtraShortReach)
        );

        var baseLong = Math.max(
            0.05,
            Math.min(0.95, tendrilExtraLongReach)
        );

        var shortCount = Math.max(0, Math.floor(tendrilExtraShortCount));
        var longCount = Math.max(0, Math.floor(tendrilExtraLongCount));

        var shortReachSpread = Math.max(
            0.0,
            Math.min(0.90, tendrilExtraShortReachSpread)
        );

        var longReachSpread = Math.max(
            0.0,
            Math.min(0.90, tendrilExtraLongReachSpread)
        );

        var shortTipSpread = Math.max(
            0.0,
            Math.min(0.90, tendrilExtraShortTipSpread)
        );

        var longTipSpread = Math.max(
            0.0,
            Math.min(0.90, tendrilExtraLongTipSpread)
        );

        var isLeft = (x + width * 0.5) < root.screenWidth * 0.5;
        var isTop = (y + height * 0.5) < root.screenHeight * 0.5;

        var specs = [];

        function clamp(value, minimum, maximum) {
            return Math.max(minimum, Math.min(maximum, value));
        }

        // Generates values centered on base, separated by spread.
        // For three tendrils and spread=0.12:
        // base - 0.06, base, base + 0.06.
        function distributedReach(base, index, count, spread) {
            if (count <= 1)
                return clamp(base, 0.05, 0.95);

            var t = index / (count - 1);
            return clamp(
                base + (t - 0.5) * spread,
                0.05,
                0.95
            );
        }

        // Produces the attachment coordinate along a clock edge.
        //
        // spread=0.0: all tips attach at 50% (edge center).
        // spread=1.0: tips span 5% through 95% of the edge.
        // reverse swaps their attachment order for mirrored orientations.
        function distributedTip(index, count, spread, reverse) {
            var t = count <= 1 ? 0.5 : index / (count - 1);

            if (reverse)
                t = 1.0 - t;

            var halfSpan = 0.45 * spread;
            return clamp(
                0.5 + (t - 0.5) * 2.0 * halfSpan,
                0.05,
                0.95
            );
        }

        // A clock at either right corner needs the long-side attachments reversed.
        var reverseLongTips = isRight;

        // A clock at either bottom corner needs the short-side attachments reversed.
        var reverseShortTips = isBottom;

        if (isTop && isLeft) {
            // Top-left:
            // Short: clock right edge -> top border.
            for (var s = 0; s < shortCount; s++) {
                var sr = distributedReach(
                    baseShort,
                    s,
                    shortCount,
                    shortReachSpread
                );

                var st = distributedTip(
                    s,
                    shortCount,
                    shortTipSpread,
                    reverseShortTips
                );

                specs.push({
                    side: "extra-short",
                    rootX: left + usableWidth * sr,
                    rootY: top,
                    tipX: x + width,
                    tipY: y + height * st
                });
            }

            // Long: clock bottom edge -> left border.
            for (var l = 0; l < longCount; l++) {
                var lr = distributedReach(
                    baseLong,
                    l,
                    longCount,
                    longReachSpread
                );

                var lt = distributedTip(
                    l,
                    longCount,
                    longTipSpread,
                    reverseLongTips
                );

                specs.push({
                    side: "extra-long",
                    rootX: left,
                    rootY: top + usableHeight * lr,
                    tipX: x + width * lt,
                    tipY: y + height
                });
            }
        } else if (isTop && !isLeft) {
            // Top-right:
            // Short: clock left edge -> top border.
            for (var s2 = 0; s2 < shortCount; s2++) {
                var sr2 = distributedReach(
                    baseShort,
                    s2,
                    shortCount,
                    shortReachSpread
                );

                var st2 = distributedTip(
                    s2,
                    shortCount,
                    shortTipSpread,
                    reverseShortTips
                );

                specs.push({
                    side: "extra-short",
                    rootX: right - usableWidth * sr2,
                    rootY: top,
                    tipX: x,
                    tipY: y + height * st2
                });
            }

            // Long: clock bottom edge -> right border.
            for (var l2 = 0; l2 < longCount; l2++) {
                var lr2 = distributedReach(
                    baseLong,
                    l2,
                    longCount,
                    longReachSpread
                );

                var lt2 = distributedTip(
                    l2,
                    longCount,
                    longTipSpread,
                    reverseLongTips
                );

                specs.push({
                    side: "extra-long",
                    rootX: right,
                    rootY: top + usableHeight * lr2,
                    tipX: x + width * lt2,
                    tipY: y + height
                });
            }
        } else if (!isTop && !isLeft) {
            // Bottom-right:
            // Short: clock left edge -> bottom border.
            for (var s3 = 0; s3 < shortCount; s3++) {
                var sr3 = distributedReach(
                    baseShort,
                    s3,
                    shortCount,
                    shortReachSpread
                );

                var st3 = distributedTip(
                    s3,
                    shortCount,
                    shortTipSpread,
                    reverseShortTips
                );

                specs.push({
                    side: "extra-short",
                    rootX: right - usableWidth * sr3,
                    rootY: bottom,
                    tipX: x,
                    tipY: y + height * st3
                });
            }

            // Long: clock top edge -> right border.
            for (var l3 = 0; l3 < longCount; l3++) {
                var lr3 = distributedReach(
                    baseLong,
                    l3,
                    longCount,
                    longReachSpread
                );

                var lt3 = distributedTip(
                    l3,
                    longCount,
                    longTipSpread,
                    reverseLongTips
                );

                specs.push({
                    side: "extra-long",
                    rootX: right,
                    rootY: bottom - usableHeight * lr3,
                    tipX: x + width * lt3,
                    tipY: y
                });
            }
        } else {
            // Bottom-left:
            // Long: clock top edge -> left border.
            for (var l4 = 0; l4 < longCount; l4++) {
                var lr4 = distributedReach(
                    baseLong,
                    l4,
                    longCount,
                    longReachSpread
                );

                var lt4 = distributedTip(
                    l4,
                    longCount,
                    longTipSpread,
                    reverseLongTips
                );

                specs.push({
                    side: "extra-long",
                    rootX: left,
                    rootY: bottom - usableHeight * lr4,
                    tipX: x + width * lt4,
                    tipY: y
                });
            }

            // Short: clock right edge -> bottom border.
            for (var s4 = 0; s4 < shortCount; s4++) {
                var sr4 = distributedReach(
                    baseShort,
                    s4,
                    shortCount,
                    shortReachSpread
                );

                var st4 = distributedTip(
                    s4,
                    shortCount,
                    shortTipSpread,
                    reverseShortTips
                );

                specs.push({
                    side: "extra-short",
                    rootX: left + usableWidth * sr4,
                    rootY: bottom,
                    tipX: x + width,
                    tipY: y + height * st4
                });
            }
        }

        return specs;
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
