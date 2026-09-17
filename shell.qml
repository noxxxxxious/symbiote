import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "components"

ShellRoot {
    GlobalShortcut {
        appid: "faishell"
        name: "toggleLauncher"
        onPressed: if (Hyprland.focusedMonitor)
            LauncherController.toggleOn(Hyprland.focusedMonitor)
    }

    GlobalShortcut {
        appid: "faishell"
        name: "toggleSettings"
        onPressed: if (Hyprland.focusedMonitor)
            SettingsController.toggleOn(Hyprland.focusedMonitor)
    }

    GlobalShortcut {
        appid: "faishell"
        name: "toggleNotifications"
        onPressed: if (Hyprland.focusedMonitor)
            NotificationController.toggleOn(Hyprland.focusedMonitor)
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: screenScope
            required property var modelData

            Wallpaper { modelData: screenScope.modelData }
            Exclusions { modelData: screenScope.modelData }

            PanelWindow {
                id: screenRoot
                screen: screenScope.modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: -1
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay

                readonly property bool isScreenFullscreen:
                    HyprState.isFullscreen(screenScope.modelData)

                readonly property bool launcherVisuallyOpen:
                    launcherPanel.width > 5 || launcherPanel.height > 5

                readonly property bool settingsHasActiveTendrils: {
                    const slots = settingsTendrilManager.slots
                    if (!slots) return false

                    for (let i = 0; i < slots.length; ++i)
                        if (slots[i] && slots[i].activation > 0.001)
                            return true

                    return false
                }

                readonly property bool isSettingsActive:
                    (settingsPanel.visuallyOpen || settingsHasActiveTendrils)
                    && !launcherPanel.isOpen

                readonly property var activeCenterPanel:
                    isSettingsActive ? settingsPanel : launcherPanel

                readonly property bool peripheralSuppressed:
                    launcherVisuallyOpen || settingsPanel.isOpen
                    || powerMenu.visuallyOpen || notificationCenter.isOpen

                visible:
                    launcherPanel.isOpen
                    || settingsPanel.visuallyOpen
                    || powerMenu.visuallyOpen
                    || notificationCenter.visuallyOpen
                    || notificationToast.visible
                    || !isScreenFullscreen

                focusable: launcherPanel.isOpen || settingsPanel.isOpen || powerMenu.isOpen || notificationCenter.isOpen

                HyprlandFocusGrab {
                    active: launcherPanel.isOpen || settingsPanel.isOpen || powerMenu.isOpen || notificationCenter.isOpen
                    windows: [screenRoot]

                    onCleared: {
                        // A late clear from another monitor must not close its replacement.
                        if (LauncherController.isOpenOn(screenScope.modelData)) LauncherController.close()
                        if (SettingsController.isOpenOn(screenScope.modelData)) SettingsController.close()
                        if (PowerMenuController.isOpenOn(screenScope.modelData)) PowerMenuController.close()
                        if (NotificationController.isOpenOn(screenScope.modelData)) NotificationController.close()
                    }
                }


                // -------------------------------------------------------------
                // Tendril managers
                // -------------------------------------------------------------

                TendrilManager {
                    id: tendrilManager
                    panel: launcherPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: launcherPanel.isOpen
                        && launcherPanel.width >= launcherPanel.finalWidth * launcherPanel.tendrilActivationFraction
                        && launcherPanel.height >= launcherPanel.finalHeight * launcherPanel.tendrilActivationFraction
                }

                TendrilManager {
                    id: clockTendrilManager
                    panel: clockPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: !clockPanel.isRetracted
                }

                TendrilManager {
                    id: trayTendrilManager
                    panel: trayPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: !trayPanel.isRetracted
                }

                TendrilManager {
                    id: trayMenuTendrilManager
                    panel: trayPanel.menuTendrilPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: trayPanel.popupVisible
                }

                TendrilManager {
                    id: settingsTendrilManager
                    panel: settingsPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: settingsPanel.isOpen
                        && settingsPanel.width >= settingsPanel.finalWidth * settingsPanel.tendrilActivationFraction
                        && settingsPanel.height >= settingsPanel.finalHeight * settingsPanel.tendrilActivationFraction
                }

                TendrilManager {
                    id: notificationCenterTendrilManager
                    panel: notificationCenter
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: notificationCenter.isOpen
                }

                TendrilManager {
                    id: notificationToastTendrilManager
                    panel: notificationToast
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: notificationToast.shown
                }

                // -------------------------------------------------------------
                // Clock geometry
                // -------------------------------------------------------------

                // -------------------------------------------------------------
                // Tray geometry
                // -------------------------------------------------------------

                // Resting bounds used to detect when the compositor cursor leaves
                // an evading tray's former footprint without capturing input.
                readonly property real trayReturnX: trayPanel.restingX
                readonly property real trayReturnY: trayPanel.restingY
                readonly property real trayReturnWidth: trayPanel.finalWidth
                readonly property real trayReturnHeight: trayPanel.finalHeight

                readonly property real trayEdgeTriggerLength: 200
                readonly property real trayEdgeTriggerThickness: Theme.borderThickness / 2
                readonly property real trayEdgeCornerX:
                    trayPanel.isRight
                        ? screenRoot.width - trayEdgeTriggerLength
                        : 0
                readonly property real trayEdgeCornerY:
                    trayPanel.isBottom
                        ? screenRoot.height - trayEdgeTriggerThickness + 2
                        : 0

                // -------------------------------------------------------------
                // Input mask
                // -------------------------------------------------------------

                mask: Region {
                    id: rootMask

                    // Launcher/settings
                    Region {
                        x: 0
                        y: 0
                        width: screenRoot.peripheralSuppressed ? screenRoot.width : 0
                        height: screenRoot.peripheralSuppressed ? screenRoot.height : 0
                    }

                    // Keep the hot zone in the mask even while unavailable so
                    // reopening on the same screen does not depend on pointer
                    // re-entry refreshing the compositor region.
                    Region { item: powerTrigger }

                    Region {
                        item: workspaceIndicator.enabled ? workspaceIndicator.hotZone : null
                    }
                    Region {
                        item: workspaceIndicator.enabled && workspaceIndicator.shown ? workspaceIndicator.hitSurface : null
                    }

                    Region {
                        item: notificationCenter.isOpen ? notificationCenter : null
                    }
                    Region {
                        item: notificationToast.shown ? notificationToast : null
                    }
                    Region {
                        item: notificationHotZone
                    }

                    // Clock
                    Region {
                        item: (!screenRoot.peripheralSuppressed && !clockPanel.isRetracted)
                            ? clockHitbox : null
                    }

                    Region {
                        item: clockEdgeTrigger.enabled ? clockEdgeTrigger : null
                    }

                    // Tray surface: input-mask geometry only. There is deliberately
                    // no shell-level Item/HoverHandler covering the visible tray.
                    Region {
                        x: trayPanel.visualX
                        y: trayPanel.visualY
                        width: (!screenRoot.peripheralSuppressed
                                && !trayPanel.isRetracted)
                            ? trayPanel.visualWidth : 0
                        height: (!screenRoot.peripheralSuppressed
                                 && !trayPanel.isRetracted)
                            ? trayPanel.visualHeight : 0
                    }

                    // Tray edge summon zone (hot corner)
                    Region {
                        x: !screenRoot.peripheralSuppressed
                            ? screenRoot.trayEdgeCornerX : 0
                        y: !screenRoot.peripheralSuppressed
                            ? screenRoot.trayEdgeCornerY : 0
                        width: !screenRoot.peripheralSuppressed
                            ? screenRoot.trayEdgeTriggerLength : 0
                        height: !screenRoot.peripheralSuppressed
                            ? screenRoot.trayEdgeTriggerThickness : 0
                    }

                    // Tray popup: geometry only. The popup itself owns hover/clicks.
                    Region {
                        x: trayPanel.popupPlateX
                        y: trayPanel.popupPlateY
                        width: (!screenRoot.peripheralSuppressed
                                && trayPanel.popupVisible)
                            ? trayPanel.popupPlateWidth : 0
                        height: (!screenRoot.peripheralSuppressed
                                 && trayPanel.popupVisible)
                            ? trayPanel.popupPlateHeight : 0
                    }
                }

                // -------------------------------------------------------------
                // Shader
                // -------------------------------------------------------------
                Border {
                    id: borderEffect
                    anchors.fill: parent

                    powerRect0: powerMenu.panelRect(0)
                    powerRect1: powerMenu.panelRect(1)
                    powerRect2: powerMenu.panelRect(2)
                    powerRect3: powerMenu.panelRect(3)
                    powerRect4: powerMenu.panelRect(4)
                    powerSlots: powerMenu.slots

                    launcherX: (screenRoot.launcherVisuallyOpen || screenRoot.isSettingsActive)
                        ? screenRoot.activeCenterPanel.x : -100000
                    launcherY: (screenRoot.launcherVisuallyOpen || screenRoot.isSettingsActive)
                        ? screenRoot.activeCenterPanel.y : -100000
                    launcherWidth: screenRoot.launcherVisuallyOpen
                        ? launcherPanel.width
                        : screenRoot.isSettingsActive ? settingsPanel.width : 0
                    launcherHeight: screenRoot.launcherVisuallyOpen
                        ? launcherPanel.height
                        : screenRoot.isSettingsActive ? settingsPanel.height : 0
                    launcherSpikeSharpness: spikeSharpness(screenRoot.isSettingsActive ? Config.sAdapter.settingsPanel : Config.sAdapter.launcher)
                    launcherSpikes: spikeProfile(screenRoot.isSettingsActive ? Config.sAdapter.settingsPanel : Config.sAdapter.launcher)
                    launcherRounding: screenRoot.activeCenterPanel.cornerRounding
                    launcherSlots: screenRoot.isSettingsActive
                        ? settingsTendrilManager.slots
                        : tendrilManager.slots
                    launcherTendrilBlend: Qt.vector2d(
                        screenRoot.activeCenterPanel.tendrilBlendRadiusRootOverride,
                        screenRoot.activeCenterPanel.tendrilBlendRadiusPanelOverride
                    )
                    launcherWaistSmoothing:
                        screenRoot.activeCenterPanel.tendrilWaistSmoothingOverride

                    clockX: clockPanel.x
                    clockY: clockPanel.y
                    clockWidth: clockPanel.width
                    clockHeight: clockPanel.height
                    clockRounding: clockPanel.cornerRadii
                    clockSlots: clockTendrilManager.slots
                    clockTendrilBlend: Qt.vector2d(
                        clockPanel.tendrilBlendRadiusRootOverride,
                        clockPanel.tendrilBlendRadiusPanelOverride
                    )
                    clockWaistSmoothing: clockPanel.tendrilWaistSmoothingOverride

                    trayX: trayPanel.visualX
                    trayY: trayPanel.visualY
                    trayWidth: trayPanel.visualWidth
                    trayHeight: trayPanel.visualHeight
                    trayRounding: trayPanel.visualCornerRadii
                    traySlots: trayTendrilManager.slots
                    trayTendrilBlend: Qt.vector2d(
                        trayPanel.tendrilBlendRadiusRootOverride,
                        trayPanel.tendrilBlendRadiusPanelOverride
                    )
                    trayWaistSmoothing: trayPanel.tendrilWaistSmoothingOverride

                    trayMenuX: trayPanel.popupVisible ? trayPanel.popupPlateX : -100000
                    trayMenuY: trayPanel.popupVisible ? trayPanel.popupPlateY : -100000
                    trayMenuWidth: trayPanel.popupVisible ? trayPanel.popupPlateWidth : 0
                    trayMenuHeight: trayPanel.popupVisible ? trayPanel.popupPlateHeight : 0
                    trayMenuRounding: trayPanel.popupCornerRadii
                    trayMenuSlots: trayMenuTendrilManager.slots
                    trayMenuTendrilBlend: Qt.vector2d(
                        trayPanel.menuTendrilPanel.tendrilBlendRadiusRootOverride,
                        trayPanel.menuTendrilPanel.tendrilBlendRadiusPanelOverride
                    )
                    trayMenuWaistSmoothing: trayPanel.menuTendrilPanel.tendrilWaistSmoothingOverride

                    notificationCenterX: notificationCenter.x
                    notificationCenterY: notificationCenter.y
                    notificationCenterWidth: notificationCenter.visuallyOpen ? notificationCenter.width : 0
                    notificationCenterHeight: notificationCenter.visuallyOpen ? notificationCenter.height : 0
                    notificationCenterRounding: notificationCenter.cornerRadii
                    notificationCenterSlots: notificationCenterTendrilManager.slots

                    notificationToastX: notificationToast.x
                    notificationToastY: notificationToast.y
                    notificationToastWidth: notificationToast.visible ? notificationToast.width : 0
                    notificationToastHeight: notificationToast.visible ? notificationToast.height : 0
                    notificationToastRounding: Qt.vector4d(notificationToast.cornerRounding, notificationToast.cornerRounding, notificationToast.cornerRounding, notificationToast.cornerRounding)
                    notificationToastSlots: notificationToastTendrilManager.slots

                    // Workspace indicator is part of the same SDF scene as the
                    // border/panels. Its tendrils use the shared tendril pool.
                    workspaceEnabledF: workspaceIndicator.shaderEnabledF
                    workspaceOrigin: workspaceIndicator.firstNodeCenter
                    workspaceVerticalF: workspaceIndicator.vertical ? 1.0 : 0.0
                    workspaceNodeCount: workspaceIndicator.entries.length
                    workspaceNodeSpacing: workspaceIndicator.config.nodeSpacing
                    workspaceChamberRadius: workspaceIndicator.config.chamberRadius
                    workspaceTubeRadius: workspaceIndicator.config.tubeRadius
                    workspaceLiquidPosition: workspaceIndicator.liquidPosition
                    workspaceLiquidFollowerPosition: workspaceIndicator.liquidFollowerPosition
                    workspaceLiquidVelocity: workspaceIndicator.liquidVelocity
                    workspaceLiquidFollowerVelocity: workspaceIndicator.liquidFollowerVelocity
                    workspaceLiquidDurationMs: workspaceIndicator.config.duration
                    workspaceLiquidFollowerScale: workspaceIndicator.liquidFollowerScale
                    workspaceLiquidPulsePhase: workspaceIndicator.liquidPulsePhase
                    workspaceLiquidPulseEnabledF: workspaceIndicator.liquidIdlePulse ? 1.0 : 0.0
                    workspaceLiquidPulseStrength: workspaceIndicator.liquidPulseStrength
                    workspaceLiquidMotionStrength: workspaceIndicator.liquidMotionStrength
                    workspaceLiquidEnabledF: workspaceIndicator.liquidEnabledF
                    workspaceSlots: workspaceIndicator.tendrilSlots
                }

                // -------------------------------------------------------------
                // Click catchers
                // -------------------------------------------------------------

                MouseArea {
                    anchors.fill: parent
                    enabled: launcherPanel.isOpen
                    onClicked: LauncherController.close()
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: settingsPanel.isOpen && !launcherPanel.isOpen
                    onClicked: SettingsController.close()
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: notificationCenter.isOpen
                    onClicked: NotificationController.close()
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: notificationCenter.isOpen
                    onActivated: NotificationController.close()
                }

                // -------------------------------------------------------------
                // Foreground widgets
                // -------------------------------------------------------------

                Clock {
                    id: clockPanel
                    targetScreen: screenScope.modelData
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                }

                Tray {
                    id: trayPanel

                    // Keep the engaged tray and preview popup above sibling panels.
                    z: (trayPanel.isEngaged || trayPanel.settingsMenuPreviewVisible) ? 10 : 0

                    targetScreen: screenScope.modelData
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height

                    onZChanged: console.log("[STATE][shell] tray z=", z,
                                            "engaged=", isEngaged,
                                            "evading=", isEvading)
                }

                NotificationToast {
                    id: notificationToast
                    z: 18
                    targetScreen: screenScope.modelData
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                }

                NotificationCenter {
                    id: notificationCenter
                    z: 19
                    targetScreen: screenScope.modelData
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                }

                Launcher {
                    id: launcherPanel
                    targetScreen: screenScope.modelData
                }

                Settings {
                    id: settingsPanel
                    anchors.centerIn: parent
                    targetScreen: screenScope.modelData
                }

                WorkspaceIndicator {
                    id: workspaceIndicator
                    anchors.fill: parent
                    z: 22
                    targetScreen: screenScope.modelData
                    sharedHotZoneHovered: edge === "bottom" && powerTrigger.available && powerTrigger.containsMouse
                    suppressed: screenRoot.peripheralSuppressed
                }

                PowerMenu {
                    id: powerMenu
                    anchors.fill: parent
                    z: 30
                    targetScreen: screenScope.modelData
                }

                PowerTrigger {
                    id: powerTrigger
                    z: 31
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    availableWidth: screenRoot.width
                    debugName: screenScope.modelData.name
                    debugWorkspaceId: workspaceIndicator.currentId
                    hoverEnabled: true
                    available: !screenRoot.peripheralSuppressed
                    onTriggered: {
                        console.log("[shell] power trigger fired",
                                    "monitor=", screenScope.modelData.name,
                                    "workspace=", workspaceIndicator.currentId,
                                    "suppressed=", screenRoot.peripheralSuppressed,
                                    "menuOpen=", powerMenu.isOpen,
                                    "controllerScreen=", PowerMenuController.activeScreen)
                        PowerMenuController.openOn(screenScope.modelData)
                        console.log("[shell] power trigger open requested",
                                    "monitor=", screenScope.modelData.name,
                                    "controllerScreen=", PowerMenuController.activeScreen)
                    }
                }

                Item {
                    id: notificationHotZone
                    z: 21
                    readonly property bool dockRight: Config.sAdapter.notifications.position.indexOf("right") !== -1
                    readonly property bool dockBottom: Config.sAdapter.notifications.position.indexOf("bottom") !== -1
                    // Corner trigger runs along the docked horizontal border.
                    // This matches clock/tray behavior, avoids a tall edge strip,
                    // and keeps each corner's hit area predictable.
                    x: dockRight ? screenRoot.width - width : 0
                    y: dockBottom ? screenRoot.height - height : 0
                    width: Math.min(180, screenRoot.width * 0.25)
                    height: Math.max(4, Theme.borderThickness / 2)
                    enabled: !screenRoot.peripheralSuppressed || notificationCenter.isOpen
                    HoverHandler {
                        onHoveredChanged: if (hovered && !notificationCenter.isOpen)
                            NotificationController.openOn(screenScope.modelData)
                    }
                }

                // -------------------------------------------------------------
                // Clock zones
                // -------------------------------------------------------------

                Item {
                    id: clockEdgeTrigger
                    z: 21
                    x: clockPanel.isRight ? screenRoot.width - width : 0
                    y: clockPanel.isBottom ? screenRoot.height - height : 0
                    width: clockPanel.finalWidth + clockPanel.margin + Theme.borderThickness
                    height: Math.max(4, Theme.borderThickness / 2)
                    enabled: clockPanel.mode === "subdermal" && !screenRoot.peripheralSuppressed
                    HoverHandler {
                        onHoveredChanged: clockPanel.edgeHovered = hovered
                    }
                }

                Item {
                    id: clockHitbox
                    x: clockPanel.mode === "subdermal" ? clockPanel.x : clockPanel.restingX
                    y: clockPanel.mode === "subdermal" ? clockPanel.y : clockPanel.restingY
                    width: clockPanel.finalWidth
                    height: clockPanel.finalHeight
                    enabled: !clockPanel.isRetracted && !screenRoot.peripheralSuppressed

                    HoverHandler {
                        onHoveredChanged: {
                            console.log("[HOVER][shell] clockHitbox", hovered,
                                        "enabled=", clockHitbox.enabled,
                                        "geom=", clockHitbox.x, clockHitbox.y, clockHitbox.width, clockHitbox.height)
                            if (clockPanel.mode === "subdermal")
                                clockPanel.pointerInside = hovered
                            else if (hovered && !clockPanel.isHovered)
                                clockPanel.isHovered = true
                        }
                    }
                }

                // -------------------------------------------------------------
                // Observe the compositor cursor while evading, without reserving
                // either panel's old footprint in the input mask.
                readonly property bool clockReturnTracking:
                    clockPanel.mode === "parasitic"
                    && clockPanel.isRetracted
                    && !screenRoot.launcherVisuallyOpen
                    && !screenRoot.peripheralSuppressed
                readonly property bool trayReturnTracking:
                    trayPanel.mode === "parasitic"
                    && trayPanel.isEvading
                    && !trayPanel.isEngaged
                    && !screenRoot.launcherVisuallyOpen
                    && !screenRoot.peripheralSuppressed

                Timer {
                    interval: 150
                    repeat: true
                    running: screenRoot.trayReturnTracking || screenRoot.clockReturnTracking
                    triggeredOnStart: true
                    onTriggered: if (!trayCursorQuery.running) trayCursorQuery.running = true
                }

                Process {
                    id: trayCursorQuery
                    command: ["hyprctl", "-j", "cursorpos"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            if (!screenRoot.trayReturnTracking && !screenRoot.clockReturnTracking) return
                            try {
                                var cursor = JSON.parse(text)
                                if (!Number.isFinite(cursor.x) || !Number.isFinite(cursor.y)) return
                                var localX = cursor.x - screenRoot.screen.x
                                var localY = cursor.y - screenRoot.screen.y
                                if (screenRoot.clockReturnTracking
                                        && (localX < clockPanel.restingX
                                            || localX >= clockPanel.restingX + clockPanel.finalWidth
                                            || localY < clockPanel.restingY
                                            || localY >= clockPanel.restingY + clockPanel.finalHeight))
                                    clockPanel.isHovered = false
                                if (screenRoot.trayReturnTracking && (localX < screenRoot.trayReturnX
                                        || localX >= screenRoot.trayReturnX + screenRoot.trayReturnWidth
                                        || localY < screenRoot.trayReturnY
                                        || localY >= screenRoot.trayReturnY + screenRoot.trayReturnHeight))
                                    trayPanel.isEvading = false
                            } catch (error) {
                                console.warn("[Panels] Could not read cursor position:", error)
                            }
                        }
                    }
                }

                // The edge trigger remains the one always-available shell sensor
                // used to explicitly engage/summon the tray.
                Item {
                    id: trayEdgeTrigger

                    // Tiny explicit summon strip. Keep it above both the passive
                    // return sensor and the tray so the screen edge always wins.
                    z: 20

                    x: screenRoot.trayEdgeCornerX
                    y: screenRoot.trayEdgeCornerY
                    width: screenRoot.trayEdgeTriggerLength
                    height: screenRoot.trayEdgeTriggerThickness

                    enabled:
                        !screenRoot.peripheralSuppressed

                    HoverHandler {
                        enabled: trayEdgeTrigger.enabled
                        blocking: false

                        onHoveredChanged: {
                            console.log("[HOVER][shell] trayEdgeTrigger", hovered,
                                        "enabled=", trayEdgeTrigger.enabled,
                                        "retracted=", trayPanel.isRetracted,
                                        "engaged=", trayPanel.isEngaged,
                                        "z=", trayEdgeTrigger.z,
                                        "trayZ=", trayPanel.z,
                                        "geom=", trayEdgeTrigger.x, trayEdgeTrigger.y,
                                        trayEdgeTrigger.width, trayEdgeTrigger.height)
                            if (hovered)
                                trayPanel.summon()
                        }
                    }
                }

                Connections {
                    target: trayPanel
                    function onIsEngagedChanged() {
                        console.log("[STATE][shell] tray isEngaged=", trayPanel.isEngaged,
                                    "isRetracted=", trayPanel.isRetracted,
                                    "isEvading=", trayPanel.isEvading,
                                    "visualGeom=", trayPanel.visualX, trayPanel.visualY,
                                    trayPanel.visualWidth, trayPanel.visualHeight)
                    }
                    function onIsRetractedChanged() {
                        console.log("[STATE][shell] tray isRetracted=", trayPanel.isRetracted,
                                    "isEngaged=", trayPanel.isEngaged,
                                    "isEvading=", trayPanel.isEvading)
                    }
                    function onPopupVisibleChanged() {
                        console.log("[STATE][shell] tray popupVisible=", trayPanel.popupVisible,
                                    "popupGeom=", trayPanel.popupPlateX, trayPanel.popupPlateY,
                                    trayPanel.popupPlateWidth, trayPanel.popupPlateHeight)
                    }
                }
            }
        }
    }
}
