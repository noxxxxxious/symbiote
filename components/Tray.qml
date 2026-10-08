pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "."

Item {
    id: root

    required property var targetScreen
    required property real screenWidth
    required property real screenHeight

    property string mode: Theme.trayMode
    property bool shortcutSubdermal: false
    readonly property string effectiveMode:
        shortcutSubdermal && mode === "parasitic" ? "subdermal" : mode
    property string cornerPosition: Theme.trayCornerPosition
    property string slideDirection: Theme.traySlideDirection

    property real margin: 10
    property real plateHeight: 44
    property real cornerRounding: 16

    property var vpnController: VpnController
    readonly property bool hasVpnIndicator: vpnController.connected

    readonly property int systemItemCount: SystemTray.items.values.length
    readonly property bool hasNotificationIndicator: NotificationController.count > 0
    readonly property int itemCount: systemItemCount + (hasNotificationIndicator ? 1 : 0) + (hasVpnIndicator ? 1 : 0)

    readonly property real itemStride:
        Theme.trayIconSize
        + Theme.trayIconPaddingX * 2
        + Theme.traySpacing

    readonly property real finalWidth:
        Math.max(76, itemCount * itemStride + 20)

    readonly property real finalHeight:
        plateHeight

    readonly property vector4d cornerRadii: Qt.vector4d(cornerRounding, cornerRounding, cornerRounding, cornerRounding)

    readonly property real panelCornerRounding:
        cornerRounding

    property bool isEvading: false
    property bool isEngaged: false
    property bool isPointerOverWakeRing: false
    property bool isPointerOverSurface: false
    property bool pointerInside: false
    property bool popupPointerInside: false
    property int disengageDelay: 3000

    onEffectiveModeChanged: {
        release()
        isEvading = false
    }

    property real engagedScale: root.isEngaged ? 1.1 : 1.0
    readonly property real visualScale: engagedScale
    readonly property real visualWidth: width * visualScale
    readonly property real visualHeight: height * visualScale
    readonly property real visualX: x - (visualWidth - width) * 0.5
    readonly property real visualY: y - (visualHeight - height) * 0.5
    readonly property vector4d visualCornerRadii: Qt.vector4d(cornerRadii.x * visualScale, cornerRadii.y * visualScale, cornerRadii.z * visualScale, cornerRadii.w * visualScale)

    Behavior on engagedScale {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    onIsEngagedChanged: console.log("[STATE][Tray] isEngaged=", isEngaged, "isRetracted=", isRetracted, "isEvading=", isEvading, "pointerInside=", pointerInside)
    onIsEvadingChanged: console.log("[STATE][Tray] isEvading=", isEvading, "isEngaged=", isEngaged, "isRetracted=", isRetracted)
    onIsRetractedChanged: console.log("[STATE][Tray] isRetracted=", isRetracted, "isEngaged=", isEngaged, "isEvading=", isEvading, "geom=", x, y, width, height)
    onPointerInsideChanged: console.log("[STATE][Tray] pointerInside=", pointerInside)

    Timer {
        id: disengageTimer

        interval: root.disengageDelay
        repeat: false

        onTriggered: {
            if (root.pointerInside || root.popupPointerInside)
                return

            popupDismissTimer.stop()
            root.isEngaged = false
            root.isEvading = false
            root.activeMenuIndex = -1
            root.activeMenuItem = null
            menuList.currentIndex = -1
        }
    }

    function summon() {
        root.isEngaged = true
        root.isEvading = false
        disengageTimer.restart()
    }

    function beginDisengageCountdown() {
        if (root.pointerInside || root.popupPointerInside)
            return

        disengageTimer.restart()
    }

    function cancelDisengageCountdown() {
        disengageTimer.stop()
    }

    function release() {
        disengageTimer.stop()
        popupDismissTimer.stop()
        root.isEngaged = false
        root.activeMenuIndex = -1
        root.activeMenuItem = null
        menuList.currentIndex = -1

        if (root.effectiveMode === "subdermal") {
            root.isEvading = false
        }
    }

    readonly property bool isRetracted: {
        if (root.isEngaged)
            return false

        if (root.effectiveMode === "subdermal")
            return true

        return root.isEvading
    }

    width: finalWidth
    height: finalHeight

    readonly property bool isRight:
        cornerPosition.indexOf("right") !== -1

    readonly property bool isBottom:
        cornerPosition.indexOf("bottom") !== -1

    readonly property real restingX:
        isRight
            ? screenWidth - Theme.borderThickness - margin - width
            : Theme.borderThickness + margin

    readonly property real restingY:
        isBottom
            ? screenHeight - Theme.borderThickness - margin - height
            : Theme.borderThickness + margin

    readonly property real travelX:
        width + margin + Theme.borderThickness + 40

    readonly property real travelY:
        height + margin + Theme.borderThickness + 40

    readonly property real hiddenX: {
        if (slideDirection === "vertical")
            return restingX

        return isRight
            ? restingX + travelX
            : restingX - travelX
    }

    readonly property real hiddenY: {
        if (slideDirection === "horizontal")
            return restingY

        return isBottom
            ? restingY + travelY
            : restingY - travelY
    }

    x: isRetracted ? hiddenX : restingX
    y: isRetracted ? hiddenY : restingY

    Behavior on x {
        NumberAnimation {
            duration: 280
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 280
            easing.type: Easing.InOutQuad
        }
    }

    // -------------------------------------------------------------------------
    // Normal tendrils
    // -------------------------------------------------------------------------

    property real tendrilsPer100px: 3
    property int tendrilMaxActive: 10
    // 10 normal + up to 24 configured cross-reach tendrils + headroom.
    property int tendrilSlotCapacityOverride: 40

    property vector2d tendrilMaxLengthRangeOverride:
        Qt.vector2d(60, 100)

    property vector2d tendrilRootThicknessRangeOverride:
        Qt.vector2d(2, 3)

    property vector2d tendrilWaistThicknessRangeOverride:
        Qt.vector2d(1, 1)

    property vector2d tendrilPanelThicknessRangeOverride:
        Qt.vector2d(1, 2)

    property bool tendrilUseScreenRelativeAttachDistance: false
    property real tendrilAttachOffset: 0

    property real tendrilBlendRadiusRootOverride: 6
    property real tendrilBlendRadiusPanelOverride: 4
    property real tendrilWaistSmoothingOverride: 20

    property real tendrilGrowSpeedOverride: 0.30
    property real tendrilShrinkSpeedOverride: 0.20

    property int tendrilMaxTop:
        isBottom ? 0 : 4

    property int tendrilMaxBottom:
        isBottom ? 4 : 0

    property int tendrilMaxLeft:
        isRight ? 0 : 4

    property int tendrilMaxRight:
        isRight ? 4 : 0

    property int tendrilMaxCorners: 2

    // -------------------------------------------------------------------------
    // Extra tendrils
    // -------------------------------------------------------------------------
    // Horizontal = roots on the top/bottom screen border. Vertical = roots on the left/right screen border.
    property bool tendrilExtraConnections: Config.sAdapter.tray.extraTendrils
    property real tendrilExtraVerticalReach: Config.sAdapter.tray.extraVerticalReach
    property real tendrilExtraHorizontalReach: Config.sAdapter.tray.extraHorizontalReach
    property int tendrilExtraVerticalCount: Config.sAdapter.tray.extraVerticalCount ?? 2
    property int tendrilExtraHorizontalCount: Config.sAdapter.tray.extraHorizontalCount ?? 2
    property real tendrilExtraVerticalReachSpread: Config.sAdapter.tray.extraVerticalReachSpread ?? 0.12
    property real tendrilExtraHorizontalReachSpread: Config.sAdapter.tray.extraHorizontalReachSpread ?? 0.12
    property real tendrilExtraVerticalTipSpread: Config.sAdapter.tray.extraVerticalTipSpread ?? 0.55
    property real tendrilExtraHorizontalTipSpread: Config.sAdapter.tray.extraHorizontalTipSpread ?? 0.55

    property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(900, 2200)
    property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(4, 9)
    property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(1, 2)
    property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(2, 4)
    property real tendrilExtraBlendRadiusRootOverride: 24
    property real tendrilExtraBlendRadiusPanelOverride: 16
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
                // Root is measured from moving tray edge, not static screen
                // geometry. It therefore follows tray retraction/expansion on
                // left/right borders and cannot drift behind tray surface.
                specs.push({ side: "extra-vertical", rootX: borderX, rootY: clampValue(fromBottom ? tipY - usableHeight * reach : tipY + usableHeight * reach, top, bottom), tipX: x + width * tip, tipY: tipY })
            }
        }

        addHorizontalFan(isBottom ? bottom : top, isRight, isRight ? x : x + width)
        addVerticalFan(isRight ? right : left, isBottom, isBottom ? y : y + height)
        return specs
    }

    // -------------------------------------------------------------------------
    // Menu state
    // -------------------------------------------------------------------------

    property int activeMenuIndex: -1
    property var activeMenuItem: null
    property real menuAnchorX: width * 0.5
    property real menuGap: 10
    property int popupDismissDelay: 350
    property int settingsMenuPreviewDuration: 2500
    property bool settingsMenuPreviewVisible: false
    readonly property var settingsMenuPreviewItems: {
        var labels = Config.sAdapter.tray.menuPreviewText.split(",")
            .map(function(label) { return label.trim() })
            .filter(function(label) { return label.length > 0 })
        if (labels.length === 0)
            labels = ["Spreading Infection", "Deeper Into Host", "Assimilation Stable"]
        return labels.map(function(label) {
            return { text: label, enabled: true, isSeparator: false }
        })
    }

    // Keep the popup farther inside the screen so side tendrils stay visible.
    property real menuScreenMargin: Theme.borderThickness + Config.sAdapter.tray.menuScreenInset

    // When the tray is right-aligned, keep the hovered icon near the popup's
    // right shoulder so most of the menu can extend inward. Mirror that for a
    // left-aligned tray. This also allows neighboring icons to visibly shift
    // the popup instead of every menu being pinned to the same clamp point.
    readonly property real menuIconAnchorBias: root.isRight ? 0.86 : 0.14

    property QtObject vpnMenuItem: QtObject {
        readonly property string id: "faishell-vpn"
        readonly property bool hasMenu: root.hasVpnIndicator
    }
    readonly property bool vpnPopupVisible: activeMenuItem === vpnMenuItem && hasVpnIndicator
    readonly property var vpnMenuItems: vpnController.active.filter(connection => connection.state === 2).map(connection => ({
        text: vpnController.active.length > 1 ? "Disconnect VPN: " + connection.name : "Disconnect VPN",
        enabled: !vpnController.busy,
        isSeparator: false,
        triggered: function() { root.vpnController.disconnectVpn(connection.uuid) }
    }))
    onHasVpnIndicatorChanged: {
        if (!hasVpnIndicator && activeMenuItem === vpnMenuItem) {
            activeMenuItem = null
            activeMenuIndex = -1
        }
    }

    readonly property var activeItem: activeMenuItem
    readonly property bool realPopupVisible: root.isEngaged && !!root.activeMenuItem && root.activeMenuItem.hasMenu
    readonly property bool popupVisible: realPopupVisible || settingsMenuPreviewVisible

    onActiveMenuIndexChanged: console.log("[STATE][Tray] activeMenuIndex=", activeMenuIndex)
    onActiveMenuItemChanged: console.log("[STATE][Tray] activeMenuItem=", activeMenuItem ? activeMenuItem.id : "<null>")
    onPopupVisibleChanged: console.log("[STATE][Tray] popupVisible=", popupVisible, "engaged=", isEngaged, "item=", activeMenuItem ? activeMenuItem.id : "<null>", "hasMenu=", activeMenuItem ? activeMenuItem.hasMenu : false)

    Timer {
        id: popupDismissTimer
        interval: root.popupDismissDelay
        repeat: false

        onTriggered: {
            if (root.popupPointerInside) return
            console.log("[STATE][Tray] popup dismiss timer -> close menu")
            root.activeMenuIndex = -1
            root.activeMenuItem = null
            menuList.currentIndex = -1
        }
    }

    Timer {
        id: settingsMenuPreviewTimer
        interval: root.settingsMenuPreviewDuration
        repeat: false
        onTriggered: root.settingsMenuPreviewVisible = false
    }

    Connections {
        target: SettingsController
        function onTrayMenuPreviewSerialChanged() {
            if (!SettingsController.isOpenOn(root.targetScreen)) return
            console.log("[STATE][Tray] settings preview request received", SettingsController.trayMenuPreviewSerial)
            root.showSettingsMenuPreview()
        }
    }

    function showSettingsMenuPreview() {
        popupDismissTimer.stop()
        root.activeMenuIndex = -1
        root.activeMenuItem = null
        menuList.currentIndex = -1
        root.menuAnchorX = root.width * 0.5
        root.settingsMenuPreviewVisible = true
        console.log("[STATE][Tray] settingsMenuPreviewVisible=true", "x=", root.popupTargetX, "y=", root.popupTargetY)
        settingsMenuPreviewTimer.restart()
    }

    function hideSettingsMenuPreview() {
        settingsMenuPreviewTimer.stop()
        root.settingsMenuPreviewVisible = false
    }

    function beginPopupDismissCountdown() {
        if (root.settingsMenuPreviewVisible || !root.popupVisible || root.popupPointerInside) return
        popupDismissTimer.restart()
    }

    function cancelPopupDismissCountdown() { popupDismissTimer.stop() }

    function selectMenuForItem(item, index, sourceItem) {
        root.hideSettingsMenuPreview()
        if (!root.isEngaged || !item || !item.hasMenu) {
            root.cancelPopupDismissCountdown()
            root.activeMenuIndex = -1
            root.activeMenuItem = null
            menuList.currentIndex = -1
            return
        }

        root.cancelDisengageCountdown()
        root.cancelPopupDismissCountdown()

        var point = sourceItem.mapToItem(root, sourceItem.width * 0.5, sourceItem.height * 0.5)

        root.menuAnchorX = point.x

        if (root.activeMenuIndex !== index)
            menuList.currentIndex = -1

        root.activeMenuIndex = index
        root.activeMenuItem = item
    }

    readonly property real popupPlateWidth: Theme.trayPopupWidth
    readonly property real popupPlateHeight: popupPlate.height
    readonly property real menuBaseScale: settingsMenuPreviewVisible ? 1.0 : visualScale
    readonly property real menuBaseX: settingsMenuPreviewVisible ? restingX : visualX
    readonly property real menuBaseY: settingsMenuPreviewVisible ? restingY : visualY
    readonly property real menuBaseHeight: settingsMenuPreviewVisible ? height : visualHeight
    readonly property real menuAnchorScreenX: menuBaseX + menuAnchorX * menuBaseScale

    // Target geometry. popupPlateX/Y below expose the *animated* geometry so
    // the shader, mask and tendril manager all move with the visible panel.
    readonly property real unclampedPopupTargetX:
        menuAnchorScreenX - popupPlateWidth * menuIconAnchorBias

    readonly property real popupTargetX: Math.max(menuScreenMargin, Math.min(screenWidth - menuScreenMargin - popupPlateWidth, unclampedPopupTargetX))

    // Keep one edge fixed while height animates. Bottom-aligned menus grow upward
    // from a stationary bottom edge; top-aligned menus grow downward from a
    // stationary top edge. popupTargetY is the final resting Y for diagnostics.
    readonly property real popupTopAnchorY: menuBaseY + menuBaseHeight + menuGap
    readonly property real popupBottomAnchorY: menuBaseY - menuGap
    // No height cap. Large menus intentionally grow beyond prior 260px limit.
    readonly property real popupTargetHeight:
        Math.max(32, menuList.contentHeight + 16)
    readonly property real popupTargetY: isBottom ? popupBottomAnchorY - popupTargetHeight : popupTopAnchorY

    readonly property real popupPlateX: root.x + popupPlate.x
    readonly property real popupPlateY: root.y + popupPlate.y
    readonly property vector4d popupCornerRadii: Qt.vector4d(12, 12, 12, 12)
    readonly property Item menuTendrilPanel: menuTendrilProxy

    // Screen-space geometry proxy for TendrilManager. The visible popupPlate is
    // tray-local, but TendrilManager expects panel.x/y in screen coordinates.
    Item {
        id: menuTendrilProxy
        x: root.popupPlateX
        y: root.popupPlateY
        width: root.popupPlateWidth
        height: root.popupPlateHeight
        visible: false

        property real cornerRounding: 12
        property real panelCornerRounding: 12
        property int tendrilUpdateIntervalOverride: 16

        // Ordinary local menu tendrils.
        property real tendrilsPer100px: 1.4
        property int tendrilMaxActive: 7
        // 7 normal + up to 16 configured menu cross-links + headroom.
        property int tendrilSlotCapacityOverride: 28
        property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(90, 180)
        property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(2, 4)
        property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(1, 2)
        property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(2, 3)
        property bool tendrilUseScreenRelativeAttachDistance: false
        property real tendrilAttachOffset: 0
        property real tendrilBlendRadiusRootOverride: 10
        property real tendrilBlendRadiusPanelOverride: 8
        property real tendrilWaistSmoothingOverride: 28
        property real tendrilGrowSpeedOverride: 0.28
        property real tendrilShrinkSpeedOverride: 0.18
        property int tendrilMaxTop: 4
        property int tendrilMaxRight: 3
        property int tendrilMaxBottom: 4
        property int tendrilMaxLeft: 3
        property int tendrilMaxCorners: 2

        // Menu cross-connections use screen-border orientation:
        // horizontal = top/bottom border, vertical = left/right border.
        property bool tendrilExtraConnections: true
        property int tendrilExtraVerticalCount: Config.sAdapter.tray.menuVerticalCount
        property int tendrilExtraHorizontalCount: Config.sAdapter.tray.menuHorizontalCount
        property real tendrilExtraVerticalReach: Config.sAdapter.tray.menuVerticalReach
        property real tendrilExtraHorizontalReach: Config.sAdapter.tray.menuHorizontalReach
        property real tendrilExtraVerticalReachSpread: Config.sAdapter.tray.menuVerticalReachSpread
        property real tendrilExtraHorizontalReachSpread: Config.sAdapter.tray.menuHorizontalReachSpread
        property real tendrilExtraVerticalTipSpread: Config.sAdapter.tray.menuVerticalTipSpread
        property real tendrilExtraHorizontalTipSpread: Config.sAdapter.tray.menuHorizontalTipSpread
        property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(Config.sAdapter.tray.menuMaxLength, Config.sAdapter.tray.menuMaxLength)
        property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(4, 7)
        property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(1.4, 2.4)
        property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(2.8, 4.6)
        property real tendrilExtraGrowSpeedOverride: 0.18
        property real tendrilExtraShrinkSpeedOverride: 0.12

        function extraTendrilSpecs() {
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
                var center = clampValue(base, 0.02, 0.48)
                if (count <= 1) return center
                var maxHalfSpan = Math.max(0, Math.min(center - 0.02, 0.48 - center))
                var halfSpan = Math.min(Math.max(0, spread) * 0.5, maxHalfSpan)
                return center + ((index / (count - 1)) * 2.0 - 1.0) * halfSpan
            }
            function distributedTip(index, count, spread, reverse) {
                var t = count <= 1 ? 0.5 : index / (count - 1)
                if (reverse) t = 1.0 - t
                return clampValue(0.5 + (t - 0.5) * 0.9 * spread, 0.08, 0.92)
            }
            function addHorizontalFan(borderY, fromRight, tipX) {
                for (var i = 0; i < horizontalCount; i++) {
                    var reach = distributedReach(tendrilExtraHorizontalReach, i, horizontalCount, tendrilExtraHorizontalReachSpread)
                    var tip = distributedTip(i, horizontalCount, tendrilExtraHorizontalTipSpread, root.isBottom)
                    specs.push({ side: "extra-horizontal", rootX: fromRight ? right - usableWidth * reach : left + usableWidth * reach, rootY: borderY, tipX: tipX, tipY: y + height * tip })
                }
            }
            function addVerticalFan(borderX, fromBottom, tipY) {
                for (var i = 0; i < verticalCount; i++) {
                    var reach = distributedReach(tendrilExtraVerticalReach, i, verticalCount, tendrilExtraVerticalReachSpread)
                    var tip = distributedTip(i, verticalCount, tendrilExtraVerticalTipSpread, root.isRight)
                    // Follow the growing edge pixel-for-pixel, bounded by the screen.
                    specs.push({ side: "extra-vertical", rootX: borderX, rootY: clampValue(fromBottom ? bottom - usableHeight * reach - height : top + usableHeight * reach + height, top, bottom), tipX: x + width * tip, tipY: tipY })
                }
            }

            addHorizontalFan(root.isBottom ? bottom : top, root.isRight, root.isRight ? x : x + width)
            addVerticalFan(root.isRight ? right : left, root.isBottom, root.isBottom ? y : y + height)
            return specs
        }
    }

    // -------------------------------------------------------------------------
    // Visible tray surface
    // -------------------------------------------------------------------------

    component NotificationIndicator: MouseArea {
        implicitWidth: Theme.trayIconSize + Theme.trayIconPaddingX * 2
        implicitHeight: Theme.trayIconSize + Theme.trayIconPaddingY * 2
        hoverEnabled: true
        onClicked: {
            root.summon()
            NotificationController.toggleOn(root.targetScreen)
        }

        Text {
            anchors.centerIn: parent
            text: "●"
            color: Theme.textColorAccent
            font.pixelSize: 15
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 1
            anchors.topMargin: -1
            width: 15
            height: 15
            radius: 8
            color: Theme.textColorAccent
            Text {
                anchors.centerIn: parent
                text: NotificationController.count > 99 ? "99+" : String(NotificationController.count)
                color: Theme.secondaryColor
                font.pixelSize: NotificationController.count > 99 ? 7 : 9
                font.bold: true
            }
        }
    }

    Item {
        id: traySurface
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        z: 2
        clip: true
        scale: root.engagedScale
        transformOrigin: Item.Center

        HoverHandler {
            id: trayHoverHandler
            blocking: false

            onHoveredChanged: {
                root.isPointerOverSurface = hovered
                root.pointerInside = hovered

                console.log("[HOVER][Tray] traySurface", hovered, "engaged=", root.isEngaged, "retracted=", root.isRetracted, "evading=", root.isEvading, "pointerInside=", root.pointerInside, "rootGeom=", root.x, root.y, root.width, root.height, "visualGeom=", root.visualX, root.visualY, root.visualWidth, root.visualHeight, "surfaceGeom=", traySurface.x, traySurface.y, traySurface.width, traySurface.height)

                if (hovered) {
                    root.cancelDisengageCountdown()

                    if (root.isEngaged) {
                        root.isEvading = false
                    } else if (root.effectiveMode === "parasitic") {
                        console.log("[STATE][Tray] parasitic surface hover -> evade")
                        root.isEvading = true
                    }
                } else if (root.isEngaged) {
                    root.beginDisengageCountdown()
                }
            }
        }

        Text {
            visible: root.itemCount === 0
            anchors.centerIn: parent
            text: "···"
            color: Theme.textColorSoft
            font.pixelSize: 14
        }

        Row {
            id: iconRow
            anchors.centerIn: parent
            spacing: Theme.traySpacing

            Loader {
                active: root.hasNotificationIndicator && !root.isRight
                // An inactive Loader still participates in Row spacing unless
                // hidden. Remove both its icon width and its spacer.
                visible: active
                sourceComponent: NotificationIndicator {}
            }

            Loader {
                active: root.hasVpnIndicator
                visible: active
                sourceComponent: MouseArea {
                    id: vpnIcon
                    objectName: "vpnTrayIcon"
                    implicitWidth: Theme.trayIconSize + Theme.trayIconPaddingX * 2
                    implicitHeight: Theme.trayIconSize + Theme.trayIconPaddingY * 2
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: {
                        root.summon()
                        root.selectMenuForItem(root.vpnMenuItem, -2, vpnIcon)
                    }
                    onEntered: if (root.vpnPopupVisible) root.cancelPopupDismissCountdown()
                    onExited: if (root.vpnPopupVisible) root.beginPopupDismissCountdown()
                    // Draw the lock directly so it remains visible without an icon theme.
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (parent.height - Theme.trayIconSize) / 2 + 1
                        width: 11; height: 12
                        radius: 5
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.textColorAccent
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: (parent.height - Theme.trayIconSize) / 2 + 9
                        width: 17; height: 13
                        radius: 3
                        color: Theme.textColorAccent
                        Rectangle {
                            anchors.centerIn: parent
                            width: 3; height: 6
                            radius: 1.5
                            color: Theme.borderColor
                        }
                    }
                }
            }

            Repeater {
                model: SystemTray.items

                delegate: MouseArea {
                    id: iconDelegate
                    required property SystemTrayItem modelData
                    required property int index

                    implicitWidth: Theme.trayIconSize + Theme.trayIconPaddingX * 2
                    implicitHeight: Theme.trayIconSize + Theme.trayIconPaddingY * 2
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true

                    onEntered: {
                        console.log("[HOVER][Tray] ICON ENTER", "index=", index, "id=", modelData.id, "hasMenu=", modelData.hasMenu, "onlyMenu=", modelData.onlyMenu, "engaged=", root.isEngaged, "delegateGeom=", iconDelegate.x, iconDelegate.y, iconDelegate.width, iconDelegate.height)
                        if (root.isEngaged)
                            root.selectMenuForItem(modelData, index, iconDelegate)
                    }

                    onExited: {
                        console.log("[HOVER][Tray] ICON EXIT", "index=", index, "id=", modelData.id, "engaged=", root.isEngaged)
                        if (root.isEngaged && root.activeMenuIndex === index) root.beginPopupDismissCountdown()
                    }

                    onClicked: function(mouse) {
                        root.summon()

                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                root.selectMenuForItem(modelData, index, iconDelegate)
                            } else {
                                modelData.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            root.selectMenuForItem(modelData, index, iconDelegate)
                        }
                    }

                    onWheel: function(wheel) { modelData.scroll(wheel.angleDelta.y, false) }

                    IconImage {
                        anchors.centerIn: parent
                        width: Theme.trayIconSize
                        height: Theme.trayIconSize
                        asynchronous: true
                        source: TrayIcons.resolve(modelData.id, modelData.icon)
                    }
                }
            }

            Loader {
                active: root.hasNotificationIndicator && root.isRight
                // See matching left-side indicator Loader above.
                visible: active
                sourceComponent: NotificationIndicator {}
            }
        }
    }

    // -------------------------------------------------------------------------
    // Shader-backed popup menu
    // -------------------------------------------------------------------------

    Item {
        id: popupPlate
        visible: root.popupVisible
        z: 5
        width: root.popupPlateWidth
        height: root.popupTargetHeight
        x: root.popupTargetX - root.x
        y: root.isBottom ? root.popupBottomAnchorY - root.y - height : root.popupTopAnchorY - root.y

        // Height is the single animation driver. For bottom-aligned trays, y is
        // derived from the *animated* height every frame, so the bottom edge stays
        // fixed and the menu expands upward without a second animation chasing it.
        Behavior on height {
            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
        }

        Behavior on x { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }

        HoverHandler {
            id: popupHoverHandler
            onHoveredChanged: {
                console.log("[HOVER][Tray] popupPlate", hovered, "visible=", popupPlate.visible, "geom(local)=", popupPlate.x, popupPlate.y, popupPlate.width, popupPlate.height, "geom(screen)=", root.popupPlateX, root.popupPlateY)
                root.popupPointerInside = hovered
                if (hovered) {
                    root.cancelDisengageCountdown()
                    root.cancelPopupDismissCountdown()
                } else {
                    root.beginPopupDismissCountdown()
                    root.beginDisengageCountdown()
                }
            }
        }

        QsMenuOpener {
            id: menuOpener
            menu: root.isEngaged && root.activeMenuItem && root.activeMenuItem !== root.vpnMenuItem ? root.activeMenuItem.menu : null
        }

        ListView {
            id: menuList
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2
            model: root.settingsMenuPreviewVisible ? root.settingsMenuPreviewItems : (root.vpnPopupVisible ? root.vpnMenuItems : root.realPopupVisible ? menuOpener.children : null)

            delegate: Rectangle {
                id: menuRow
                required property var modelData
                required property int index
                width: ListView.view ? ListView.view.width : 0
                height: modelData.isSeparator ? 8 : 28
                color: "transparent"
                radius: 6

                AccentHighlight {
                    anchors.fill: parent
                    visible: !menuRow.modelData.isSeparator
                    hovered: rowHover.hovered
                    radius: menuRow.radius
                }

                Rectangle {
                    visible: menuRow.modelData.isSeparator
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: Theme.textColorSoft
                    opacity: 0.3
                }

                Text {
                    visible: !menuRow.modelData.isSeparator
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: menuRow.modelData.text || ""
                    color: Theme.textColor
                    opacity: menuRow.modelData.enabled ? 1.0 : 0.4
                    elide: Text.ElideRight
                }

                HoverHandler {
                    id: rowHover
                    onHoveredChanged: {
                        console.log("[HOVER][Tray] menuRow", hovered, "index=", menuRow.index, "text=", menuRow.modelData.text, "separator=", menuRow.modelData.isSeparator)
                        if (hovered && !menuRow.modelData.isSeparator) {
                            root.cancelDisengageCountdown()
                            root.cancelPopupDismissCountdown()
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.settingsMenuPreviewVisible && !menuRow.modelData.isSeparator && menuRow.modelData.enabled
                    onClicked: {
                        root.cancelPopupDismissCountdown()
                        menuRow.modelData.triggered()
                        root.activeMenuIndex = -1
                        root.activeMenuItem = null
                        menuList.currentIndex = -1
                        root.beginDisengageCountdown()
                    }
                }
            }
        }
    }
}
