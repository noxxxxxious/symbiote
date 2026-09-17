// components/Dashboard.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."
import "dashboard" as DashboardPages

Item {
    id: root

    required property var targetScreen
    required property real screenWidth
    required property real screenHeight

    readonly property bool isOpen: DashboardController.isOpenOn(targetScreen)
    readonly property bool visuallyOpen: height > 5
    readonly property var dashboardConfig: Config.sAdapter.dashboard

    property bool presented: false
    property bool pointerInside: false
    property bool edgeHovered: false
    property int currentTab: 0

    // Keep the provider alive with the Dashboard instance so switching tabs
    // cannot destroy an in-flight /proc read. Polling itself only runs while
    // Dashboard -> Info is open.
    SystemInfo {
        id: systemInfo
        active: root.isOpen && root.currentTab === 0
    }

    property real finalWidth: Math.max(480, Math.min(dashboardConfig.width, screenWidth - 80))
    property real finalHeight: Math.max(300, Math.min(dashboardConfig.height, screenHeight - 120))
    property real cornerRounding: dashboardConfig.cornerRounding
    property real topGap: dashboardConfig.topGap

    // -------------------------------------------------------------------------
    // Normal randomized top tendrils
    // -------------------------------------------------------------------------
    // Setting tendrilsPer100px to zero is the TendrilManager's clean off switch.
    property real tendrilsPer100px: dashboardConfig.tendrils
        ? dashboardConfig.tendrilsPer100px : 0
    property int tendrilMaxActive: dashboardConfig.tendrilMaxActive

    // Capacity follows the configured normal + guaranteed extras while remaining
    // below the shared 64-tendril shader render pool.
    property int tendrilSlotCapacityOverride: Math.min(
        56,
        Math.max(
            12,
            dashboardConfig.tendrilMaxActive
                + (dashboardConfig.extraTendrils && dashboardConfig.sideExtraTendrils
                    ? dashboardConfig.sideExtraCount * 2 : 0)
                + (dashboardConfig.extraTendrils && dashboardConfig.bottomExtraTendrils
                    ? dashboardConfig.bottomExtraCount : 0)
                + 8
        )
    )

    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(
        dashboardConfig.tendrilMinLength,
        Math.max(dashboardConfig.tendrilMinLength, dashboardConfig.tendrilMaxLength)
    )
    property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(
        dashboardConfig.tendrilRootMinWidth,
        Math.max(dashboardConfig.tendrilRootMinWidth, dashboardConfig.tendrilRootMaxWidth)
    )
    property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(
        dashboardConfig.tendrilWaistMinWidth,
        Math.max(dashboardConfig.tendrilWaistMinWidth, dashboardConfig.tendrilWaistMaxWidth)
    )
    property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(
        dashboardConfig.tendrilTipMinWidth,
        Math.max(dashboardConfig.tendrilTipMinWidth, dashboardConfig.tendrilTipMaxWidth)
    )

    property bool tendrilUseScreenRelativeAttachDistance: false
    property real tendrilAttachOffset: 0
    property real tendrilBlendRadiusRootOverride: dashboardConfig.tendrilRootBlend
    property real tendrilBlendRadiusPanelOverride: dashboardConfig.tendrilTipBlend
    property real tendrilWaistSmoothingOverride: dashboardConfig.tendrilWaistSmoothing
    property real tendrilGrowSpeedOverride: dashboardConfig.tendrilGrowSpeed
    property real tendrilShrinkSpeedOverride: dashboardConfig.tendrilShrinkSpeed
    property real tendrilActivationFraction: 0.12

    // The normal randomized pool is top-only. Left/right/bottom use the explicit
    // extra connections below, so they can have completely separate profiles.
    property int tendrilMaxTop: dashboardConfig.tendrilMaxTop
    property int tendrilMaxRight: 0
    property int tendrilMaxBottom: 0
    property int tendrilMaxLeft: 0
    property int tendrilMaxCorners: 0

    // -------------------------------------------------------------------------
    // Extra side + bottom tendrils
    // -------------------------------------------------------------------------
    property bool tendrilExtraConnections: dashboardConfig.extraTendrils
    property real tendrilExtraGrowSpeedOverride: dashboardConfig.extraGrowSpeed
    property real tendrilExtraShrinkSpeedOverride: dashboardConfig.extraShrinkSpeed

    // Fallbacks only; every Dashboard extra spec supplies its own profile.
    readonly property real dashboardDiagonal: Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight)
    property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(dashboardDiagonal, dashboardDiagonal)
    property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(5, 10)
    property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(1.5, 3)
    property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(3, 6)

    // TendrilManager watches this optional key. Thickness/length ranges are chosen
    // randomly only when a strand is spawned, so changing one of these values
    // intentionally re-rolls the Dashboard's strands immediately while tuning.
    property string tendrilRerollKey: [
        dashboardConfig.tendrilMinLength,
        dashboardConfig.tendrilMaxLength,
        dashboardConfig.tendrilRootMinWidth,
        dashboardConfig.tendrilRootMaxWidth,
        dashboardConfig.tendrilWaistMinWidth,
        dashboardConfig.tendrilWaistMaxWidth,
        dashboardConfig.tendrilTipMinWidth,
        dashboardConfig.tendrilTipMaxWidth,
        dashboardConfig.sideExtraMinLength,
        dashboardConfig.sideExtraMaxLength,
        dashboardConfig.sideExtraRootMinWidth,
        dashboardConfig.sideExtraRootMaxWidth,
        dashboardConfig.sideExtraWaistMinWidth,
        dashboardConfig.sideExtraWaistMaxWidth,
        dashboardConfig.sideExtraTipMinWidth,
        dashboardConfig.sideExtraTipMaxWidth,
        dashboardConfig.bottomExtraMinLength,
        dashboardConfig.bottomExtraMaxLength,
        dashboardConfig.bottomExtraRootMinWidth,
        dashboardConfig.bottomExtraRootMaxWidth,
        dashboardConfig.bottomExtraWaistMinWidth,
        dashboardConfig.bottomExtraWaistMaxWidth,
        dashboardConfig.bottomExtraTipMinWidth,
        dashboardConfig.bottomExtraTipMaxWidth
    ].join("|")

    function clampValue(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function distributed(index, count, spread) {
        if (count <= 1) return 0.5
        return 0.5 + (index / (count - 1) - 0.5) * clampValue(spread, 0, 1)
    }

    function extraTendrilSpecs() {
        if (!dashboardConfig.extraTendrils)
            return []

        var specs = []
        var left = Theme.borderThickness
        var top = Theme.borderThickness
        var right = screenWidth - Theme.borderThickness
        var bottom = screenHeight - Theme.borderThickness
        var usableHeight = Math.max(1, bottom - top)
        var usableWidth = Math.max(1, right - left)

        if (dashboardConfig.sideExtraTendrils) {
            var sideCount = Math.max(0, Math.floor(dashboardConfig.sideExtraCount))
            var reach = clampValue(dashboardConfig.sideExtraRootReach, 0.02, 0.95)
            var rootSpread = clampValue(dashboardConfig.sideExtraRootSpread, 0, 0.90)
            var tipSpread = clampValue(dashboardConfig.sideExtraTipSpread, 0, 1)
            var sideLength = Qt.vector2d(
                dashboardConfig.sideExtraMinLength,
                Math.max(dashboardConfig.sideExtraMinLength, dashboardConfig.sideExtraMaxLength)
            )
            var sideRootWidth = Qt.vector2d(
                dashboardConfig.sideExtraRootMinWidth,
                Math.max(dashboardConfig.sideExtraRootMinWidth, dashboardConfig.sideExtraRootMaxWidth)
            )
            var sideWaistWidth = Qt.vector2d(
                dashboardConfig.sideExtraWaistMinWidth,
                Math.max(dashboardConfig.sideExtraWaistMinWidth, dashboardConfig.sideExtraWaistMaxWidth)
            )
            var sideTipWidth = Qt.vector2d(
                dashboardConfig.sideExtraTipMinWidth,
                Math.max(dashboardConfig.sideExtraTipMinWidth, dashboardConfig.sideExtraTipMaxWidth)
            )

            for (var i = 0; i < sideCount; ++i) {
                var centered = sideCount <= 1 ? 0 : (i / (sideCount - 1) - 0.5)
                var rootFraction = clampValue(reach + centered * rootSpread, 0.02, 0.95)
                var tipFraction = distributed(i, sideCount, tipSpread)
                var rootY = top + usableHeight * rootFraction
                var tipY = y + height * tipFraction

                specs.push({
                    side: "extra-left",
                    rootX: left,
                    rootY: rootY,
                    tipX: x + 3,
                    tipY: tipY,
                    maxLengthRange: sideLength,
                    rootThicknessRange: sideRootWidth,
                    waistThicknessRange: sideWaistWidth,
                    panelThicknessRange: sideTipWidth
                })
                specs.push({
                    side: "extra-right",
                    rootX: right,
                    rootY: rootY,
                    tipX: x + width - 3,
                    tipY: tipY,
                    maxLengthRange: sideLength,
                    rootThicknessRange: sideRootWidth,
                    waistThicknessRange: sideWaistWidth,
                    panelThicknessRange: sideTipWidth
                })
            }
        }

        if (dashboardConfig.bottomExtraTendrils) {
            var bottomCount = Math.max(0, Math.floor(dashboardConfig.bottomExtraCount))
            var bottomRootSpread = clampValue(dashboardConfig.bottomExtraRootSpread, 0, 1)
            var bottomTipSpread = clampValue(dashboardConfig.bottomExtraTipSpread, 0, 1)
            var bottomLength = Qt.vector2d(
                dashboardConfig.bottomExtraMinLength,
                Math.max(dashboardConfig.bottomExtraMinLength, dashboardConfig.bottomExtraMaxLength)
            )
            var bottomRootWidth = Qt.vector2d(
                dashboardConfig.bottomExtraRootMinWidth,
                Math.max(dashboardConfig.bottomExtraRootMinWidth, dashboardConfig.bottomExtraRootMaxWidth)
            )
            var bottomWaistWidth = Qt.vector2d(
                dashboardConfig.bottomExtraWaistMinWidth,
                Math.max(dashboardConfig.bottomExtraWaistMinWidth, dashboardConfig.bottomExtraWaistMaxWidth)
            )
            var bottomTipWidth = Qt.vector2d(
                dashboardConfig.bottomExtraTipMinWidth,
                Math.max(dashboardConfig.bottomExtraTipMinWidth, dashboardConfig.bottomExtraTipMaxWidth)
            )

            for (var b = 0; b < bottomCount; ++b) {
                var rootFractionX = distributed(b, bottomCount, bottomRootSpread)
                var tipFractionX = distributed(b, bottomCount, bottomTipSpread)
                specs.push({
                    side: "extra-bottom",
                    rootX: left + usableWidth * rootFractionX,
                    rootY: bottom,
                    tipX: x + width * tipFractionX,
                    tipY: y + height - 3,
                    maxLengthRange: bottomLength,
                    rootThicknessRange: bottomRootWidth,
                    waistThicknessRange: bottomWaistWidth,
                    panelThicknessRange: bottomTipWidth
                })
            }
        }

        return specs
    }

    x: Math.round((screenWidth - width) / 2)
    y: Theme.borderThickness + topGap
    width: finalWidth
    height: presented ? finalHeight : 1
    clip: true
    visible: visuallyOpen || isOpen
    z: 24

    Behavior on height {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    onIsOpenChanged: {
        if (isOpen) {
            closeTimer.stop()
            Qt.callLater(function() { root.presented = true })
        } else {
            closeTimer.stop()
            root.presented = false
        }
    }

    Component.onCompleted: presented = isOpen

    function summon() {
        closeTimer.stop()
        if (!isOpen)
            DashboardController.openOn(targetScreen)
    }

    function maybeScheduleClose() {
        if (!pointerInside && !edgeHovered && isOpen)
            closeTimer.restart()
    }

    onPointerInsideChanged: {
        if (pointerInside) closeTimer.stop()
        else maybeScheduleClose()
    }

    onEdgeHoveredChanged: {
        if (edgeHovered) {
            closeTimer.stop()
            summon()
        } else {
            maybeScheduleClose()
        }
    }

    Timer {
        id: closeTimer
        interval: dashboardConfig.closeDelay
        repeat: false
        onTriggered: if (!root.pointerInside && !root.edgeHovered) DashboardController.close()
    }

    HoverHandler {
        onHoveredChanged: root.pointerInside = hovered
    }

    // The body itself is rendered in border.frag; this is content only.
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        DashboardTabs {
            Layout.fillWidth: true
            currentIndex: root.currentTab
            onTabRequested: function(index) { root.currentTab = index }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Qt.rgba(Theme.textColorSoft.r, Theme.textColorSoft.g, Theme.textColorSoft.b, 0.22)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Loader {
                anchors.fill: parent
                sourceComponent: {
                    switch (root.currentTab) {
                    case 0: return infoPage
                    case 1: return soundPage
                    case 2: return wifiPage
                    case 3: return vpnPage
                    case 4: return bluetoothPage
                    case 5: return mediaPage
                    default: return infoPage
                    }
                }
            }
        }
    }

    Component {
        id: infoPage
        DashboardPages.InfoTab {
            systemInfo: systemInfo
        }
    }
    Component { id: soundPage; DashboardPages.SoundTab {} }
    Component { id: wifiPage; DashboardPages.WifiTab {} }
    Component { id: vpnPage; DashboardPages.VpnTab {} }
    Component { id: bluetoothPage; DashboardPages.BluetoothTab {} }
    Component { id: mediaPage; DashboardPages.MediaTab {} }
}
