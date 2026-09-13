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

    Variants {
        model: Quickshell.screens

        // Scope serves as the SINGLE delegate per screen for Variants
        Scope {
            id: screenScope
            required property var modelData

            // 1. Wayland Exclusion Zones
            Exclusions {
                modelData: screenScope.modelData
            }

            // 2. Desktop Shell Overlay
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

                readonly property bool isScreenFulscreen: HyprState.isFullscreen(screenScope.modelData)
                visible: launcherPanel.isOpen || !isScreenFulscreen

                HyprlandFocusGrab {
                    active: launcherPanel.isOpen
                    windows: [ screenRoot ]
                    onCleared: LauncherController.close()
                }

                readonly property bool launcherVisuallyOpen:
                        launcherPanel.width > 5 || launcherPanel.height > 5

                focusable: launcherPanel.isOpen


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
                // Composable Clickthrough Mask
                // -----------------------------------------------------------------
                mask: Region {
                    id: rootMask

                    // Launcher mask
                    Region {
                        x: 0
                        y: 0
                        width: screenRoot.launcherVisuallyOpen ? screenRoot.width : 0
                        height: screenRoot.launcherVisuallyOpen ? screenRoot.height : 0
                    }

                    // Clock hitbox mask
                    Region {
                        item: (!screenRoot.launcherVisuallyOpen && !clockPanel.isRetracted) ? clockHitbox : null
                    }

                    // Clock retracted doughnut ring
                    Region {
                        x: (!screenRoot.launcherVisuallyOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterX : 0
                        y: (!screenRoot.launcherVisuallyOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterY : 0
                        width: (!screenRoot.launcherVisuallyOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterW : 0
                        height: (!screenRoot.launcherVisuallyOpen && clockPanel.isRetracted) ? screenRoot.wakeOuterH : 0

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
                // Shader Pass
                // -----------------------------------------------------------------
                Border {
                    id: borderEffect
                    anchors.fill: parent

                    launcherX: screenRoot.launcherVisuallyOpen ? launcherPanel.x : -100000
                    launcherY: screenRoot.launcherVisuallyOpen ? launcherPanel.y : -100000
                    launcherWidth: screenRoot.launcherVisuallyOpen ? launcherPanel.width : 0
                    launcherHeight: screenRoot.launcherVisuallyOpen ? launcherPanel.height : 0
                    launcherRounding: launcherPanel.cornerRounding
                    launcherSlots: tendrilManager.slots

                    launcherTendrilBlend: Qt.vector2d(
                        launcherPanel.tendrilBlendRadiusRootOverride,
                        launcherPanel.tendrilBlendRadiusPanelOverride
                    )
                    launcherWaistSmoothing: launcherPanel.tendrilWaistSmoothingOverride

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

                MouseArea {
                    anchors.fill: parent
                    enabled: launcherPanel.isOpen
                    onClicked: LauncherController.close()
                }

                // -----------------------------------------------------------------
                // Foreground Widgets
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

                // -----------------------------------------------------------------
                // Hover Hitboxes & Wake Rings
                // -----------------------------------------------------------------
                Item {
                    id: clockWakeZone
                    x: screenRoot.wakeOuterX
                    y: screenRoot.wakeOuterY
                    width: screenRoot.wakeOuterW
                    height: screenRoot.wakeOuterH
                    enabled: clockPanel.isRetracted && !screenRoot.launcherVisuallyOpen

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
                    enabled: !clockPanel.isRetracted && !screenRoot.launcherVisuallyOpen

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
