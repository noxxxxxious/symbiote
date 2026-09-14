// shell.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "components"

ShellRoot {
    GlobalShortcut {
        appid: "faishell"
        name: "toggleLauncher"
        onPressed: {
            if (Hyprland.focusedMonitor)
                LauncherController.toggleOn(Hyprland.focusedMonitor)
        }
    }

    GlobalShortcut {
        appid: "faishell"
        name: "toggleSettings"
        onPressed: {
            if (Hyprland.focusedMonitor)
                SettingsController.toggleOn(Hyprland.focusedMonitor)
        }
    }

    Variants {
        model: Quickshell.screens

        // Scope serves as the SINGLE delegate per screen for Variants
        Scope {
            id: screenScope
            required property var modelData

            Wallpaper {
              modelData: screenScope.modelData
            }

            Exclusions {
                modelData: screenScope.modelData
            }

            PanelWindow {
                id: screenRoot
                screen: screenScope.modelData

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: -1
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Overlay

                readonly property bool isScreenFullscreen: HyprState.isFullscreen(screenScope.modelData)
                readonly property bool launcherVisuallyOpen:
                        launcherPanel.width > 5 || launcherPanel.height > 5
                readonly property bool settingsHasActiveTendrils: {
                    var slots = settingsTendrilManager.slots;
                    if (!slots) return false;
                    for (var i = 0; i < slots.length; i++) {
                        if (slots[i] && slots[i].activation > 0.001) return true;
                    }
                    return false;
                }

                readonly property bool isSettingsActive: (settingsPanel.visuallyOpen || settingsHasActiveTendrils) && !launcherPanel.isOpen
                readonly property var activeCenterPanel: isSettingsActive ? settingsPanel : launcherPanel

                // Visible normally, hidden on fullscreen UNLESS launcher or settings is open
                visible: launcherPanel.isOpen || settingsPanel.visuallyOpen || !isScreenFullscreen

                // Focusable if EITHER launcher or settings is open
                focusable: launcherPanel.isOpen || settingsPanel.isOpen

                // Ensure compositor focus grab is active while either popup is open
                HyprlandFocusGrab {
                    active: launcherPanel.isOpen || settingsPanel.isOpen
                    windows: [ screenRoot ]
                    onCleared: {
                        LauncherController.close();
                        SettingsController.close();
                    }
                }

                // -----------------------------------------------------------------
                // State Drivers & Managers
                // -----------------------------------------------------------------
                TendrilManager {
                    id: tendrilManager
                    panel: launcherPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: launcherPanel.isOpen
                }

                TendrilManager {
                    id: clockTendrilManager
                    panel: clockPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: !clockPanel.isRetracted
                }

                TendrilManager {
                    id: settingsTendrilManager
                    panel: settingsPanel
                    screenWidth: screenRoot.width
                    screenHeight: screenRoot.height
                    enabled: settingsPanel.isOpen
                }

                readonly property real clockWakePadding: 8
                readonly property real clockWakeThickness: 32

                readonly property real wakeInnerX: Math.max(0, clockPanel.restingX - clockWakePadding)
                readonly property real wakeInnerY: Math.max(0, clockPanel.restingY - clockWakePadding)
                readonly property real wakeInnerW: clockPanel.finalWidth + (clockWakePadding * 2)
                readonly property real wakeInnerH: clockPanel.finalHeight + (clockWakePadding * 2)

                readonly property real wakeOuterX: Math.max(0, wakeInnerX - clockWakeThickness)
                readonly property real wakeOuterY: Math.max(0, wakeInnerY - clockWakeThickness)
                readonly property real wakeOuterW: wakeInnerW + (clockWakeThickness * 2)
                readonly property real wakeOuterH: wakeInnerH + (clockWakeThickness * 2)

                // -----------------------------------------------------------------
                // Composable Clickthrough Mask (Single Declaration)
                // -----------------------------------------------------------------
                mask: Region {
                    id: rootMask

                    // 1. Full-screen mask when Launcher OR Settings is open
                    Region {
                        x: 0
                        y: 0
                        width: (screenRoot.launcherVisuallyOpen || settingsPanel.isOpen) ? screenRoot.width : 0
                        height: (screenRoot.launcherVisuallyOpen || settingsPanel.isOpen) ? screenRoot.height : 0
                    }

                    // 2. Clock resting hitbox (only when launcher & settings are closed)
                    Region {
                        item: (!screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen && !clockPanel.isRetracted) ? clockHitbox : null
                    }

                    // 3. Clock retracted wake ring
                    Region {
                        x: (!screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterX : 0
                        y: (!screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterY : 0
                        width: (!screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterW : 0
                        height: (!screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterH : 0

                        Region {
                            x: screenRoot.wakeInnerX - screenRoot.wakeOuterX
                            y: screenRoot.wakeInnerY - screenRoot.wakeOuterY
                            width: screenRoot.wakeInnerW
                            height: screenRoot.wakeInnerH
                            intersection: Intersection.Subtract
                        }
                    }
                }

                // -----------------------------------------------------------------
                // Shader Pass (Painted on bottom)
                // -----------------------------------------------------------------
                Border {
                    id: borderEffect
                    anchors.fill: parent

                    // Routes to Launcher if open, or Settings if open, else off-screen
                    launcherX: (screenRoot.launcherVisuallyOpen || screenRoot.isSettingsActive) ? screenRoot.activeCenterPanel.x : -100000
                    launcherY: (screenRoot.launcherVisuallyOpen || screenRoot.isSettingsActive) ? screenRoot.activeCenterPanel.y : -100000
                    launcherWidth: screenRoot.launcherVisuallyOpen ? launcherPanel.width : (screenRoot.isSettingsActive ? settingsPanel.width : 0)
                    launcherHeight: screenRoot.launcherVisuallyOpen ? launcherPanel.height : (screenRoot.isSettingsActive ? settingsPanel.height : 0)
                    launcherRounding: screenRoot.activeCenterPanel.cornerRounding
                    launcherSlots: screenRoot.isSettingsActive ? settingsTendrilManager.slots : tendrilManager.slots

                    launcherTendrilBlend: Qt.vector2d(
                        screenRoot.activeCenterPanel.tendrilBlendRadiusRootOverride,
                        screenRoot.activeCenterPanel.tendrilBlendRadiusPanelOverride
                    )
                    launcherWaistSmoothing: screenRoot.activeCenterPanel.tendrilWaistSmoothingOverride

                    // Clock plate & tendrils remain uninterrupted
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
                }

                // Click catcher to dismiss launcher when clicking outside
                MouseArea {
                    anchors.fill: parent
                    enabled: launcherPanel.isOpen
                    onClicked: LauncherController.close()
                }

                // Click catcher to dismiss settings when clicking outside
                MouseArea {
                    anchors.fill: parent
                    enabled: settingsPanel.isOpen && !launcherPanel.isOpen
                    onClicked: SettingsController.close()
                }

                // -----------------------------------------------------------------
                // Foreground Widgets (Rendered on top of shader)
                // -----------------------------------------------------------------
                Clock {
                    id: clockPanel
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

                // -----------------------------------------------------------------
                // Hover Hitboxes & Wake Rings
                // -----------------------------------------------------------------
                Item {
                    id: clockWakeZone
                    x: screenRoot.wakeOuterX
                    y: screenRoot.wakeOuterY
                    width: screenRoot.wakeOuterW
                    height: screenRoot.wakeOuterH
                    enabled: clockPanel.isRetracted && !screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen

                    HoverHandler {
                        id: wakeHandler
                        onHoveredChanged: {
                            if (hovered && clockPanel.isHovered) {
                                clockPanel.isHovered = false;
                            }
                        }
                    }
                }

                Item {
                    id: clockHitbox
                    x: clockPanel.restingX
                    y: clockPanel.restingY
                    width: clockPanel.finalWidth
                    height: clockPanel.finalHeight
                    enabled: !clockPanel.isRetracted && !screenRoot.launcherVisuallyOpen && !settingsPanel.isOpen

                    HoverHandler {
                        id: hitboxHandler
                        onHoveredChanged: {
                            if (hovered && !clockPanel.isHovered) {
                                clockPanel.isHovered = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
