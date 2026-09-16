pragma Singleton
import QtQuick
import Quickshell
import "."

QtObject {
    // --- Text ---
    property color textColor: Config.sAdapter.text.color
    property color textColorSoft: Config.sAdapter.text.soft
    property color textColorAccent: Config.sAdapter.text.accent
    property color secondaryColor: Config.sAdapter.text.secondary

    // --- Border geometry ---
    property real borderThickness: Config.sAdapter.border.thickness
    property real borderRounding: Config.sAdapter.border.rounding
    property real borderSmoothing: Config.sAdapter.border.smoothing

    // --- Border appearance ---
    property color borderColor: Config.sAdapter.border.color
    property real borderOpacity: Config.sAdapter.border.opacity

    // --- Outer shadow ---
    property bool shadowEnabled: Config.sAdapter.shadow.enabled
    property color shadowColor: Config.sAdapter.shadow.color
    property real shadowOpacity: Config.sAdapter.shadow.opacity
    property real shadowFalloff: Config.sAdapter.shadow.falloff

    // --- Inner edge glow ---
    property bool innerEdgeEnabled: Config.sAdapter.innerEdge.enabled
    property color innerEdgeColor: Config.sAdapter.innerEdge.color
    property real innerEdgeIntensity: Config.sAdapter.innerEdge.intensity
    property real innerEdgeFalloff: Config.sAdapter.innerEdge.falloff

    // --- Tendrils ---

    property int tendrilMaxSlots: 200
    property int tendrilRenderCapacity: 64
    property int tendrilMaxPerimeterPoints: 50

    property real tendrilsPer100px: Config.sAdapter.tendrils.tendrilsPer100px

    property vector2d tendrilMaxLengthRange: Qt.vector2d(
        Config.sAdapter.tendrils.maxLengthRange[0],
        Config.sAdapter.tendrils.maxLengthRange[1]
    )
    property vector2d tendrilRootThicknessRange: Qt.vector2d(
        Config.sAdapter.tendrils.rootThicknessRange[0],
        Config.sAdapter.tendrils.rootThicknessRange[1]
    )
    property vector2d tendrilPanelThicknessRange: Qt.vector2d(
        Config.sAdapter.tendrils.panelThicknessRange[0],
        Config.sAdapter.tendrils.panelThicknessRange[1]
    )
    property vector2d tendrilWaistThicknessRange: Qt.vector2d(
        Config.sAdapter.tendrils.waistThicknessRange[0],
        Config.sAdapter.tendrils.waistThicknessRange[1]
    )

    property real tendrilAttachDistance: Config.sAdapter.tendrils.attachDistance
    property real tendrilGrowSpeed: Config.sAdapter.tendrils.growSpeed
    property real tendrilShrinkSpeed: Config.sAdapter.tendrils.shrinkSpeed
    property real tendrilBlendRadius: Config.sAdapter.tendrils.blendRadius

    // Blend radius (px) for smoothing the kink where a tendril's
    // root->waist taper meets its waist->tip taper. Distinct from
    // tendrilBlendRadius, which is about the ENDS melting into the
    // border/panel, not the middle joint.
    property real tendrilWaistSmoothing: Config.sAdapter.tendrils.waistSmoothing

    property real tendrilJitter: Config.sAdapter.tendrils.jitter

    property int tendrilMaxActivePerPanel: 6

    property int tendrilMaxTop: 6
    property int tendrilMaxRight: 4
    property int tendrilMaxBottom: 6
    property int tendrilMaxLeft: 4
    property int tendrilMaxCorners: 4

    // --- Panels ---
    readonly property color panelBackgroundColor: Config.sAdapter.panels.backgroundColor

    // --- Launcher ---
    readonly property color launcherBackgroundColor: {
        var overrideColor = Config.sAdapter.launcher.backgroundColor;
        return (overrideColor && overrideColor.length > 0)
            ? overrideColor
            : panelBackgroundColor;
    }
    readonly property bool launcherShowIcons: Config.sAdapter.launcher.showIcons

    // --- Clock ---
    property string clockCornerPosition: Config.sAdapter.clock.position
    property string clockSlideDirection: Config.sAdapter.clock.slideDirection

    // --- Tray ---
    property string trayMode: Config.sAdapter.tray.mode
    property string trayCornerPosition: Config.sAdapter.tray.position
    property string traySlideDirection: Config.sAdapter.tray.slideDirection

    readonly property real trayIconSize: 20
    readonly property real trayIconPaddingX: 6
    readonly property real trayIconPaddingY: 4
    readonly property real traySpacing: 2
    readonly property real trayPopupWidth: 220
    readonly property real trayPopupPadding: 6
    readonly property real trayPopupRowHeight: 28
    readonly property real trayPopupSeparatorHeight: 8

    // --- Wallpaper ---
    readonly property string wallpaperDirectory: {
        var dir = Config.sAdapter.wallpaper.directory || "~/Pictures/Wallpapers";
        return dir.replace(/^~/, Quickshell.env("HOME") || "");
    }
    readonly property string wallpaperPath: {
        var p = Config.sAdapter.wallpaper.path || "";
        return p.replace(/^~/, Quickshell.env("HOME") || "");
    }
}
