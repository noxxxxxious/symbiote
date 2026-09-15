// components/Config.qml
//
// Hot-reloadable JSON config. FileView sets up its own OS-level file
// watcher (independent of Quickshell's built-in .qml hot-reload graph),
// so editing theme.json and hitting save updates the running shell
// immediately - no restart, and no dependency on QML file-change detection
// picking up plain .js module edits (which it doesn't).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root

    // Lives next to shell.qml - e.g. ~/.config/quickshell/faishell/theme.json
    path: Quickshell.shellDir + "/config.json"

    // If the file doesn't exist yet, create it from the adapter's defaults
    // below instead of erroring out.
    printErrors: false

    // Preserve FileView's safe atomic replacement behavior, but do not start a
    // new QSaveFile write for every intermediate slider value. Settings controls
    // can update dozens of times per second while dragging.
    atomicWrites: true

    watchChanges: true
    onFileChanged: reload()

    property Timer saveDebounce: Timer {
        interval: 300
        repeat: false
        onTriggered: root.writeAdapter()
    }

    onAdapterUpdated: saveDebounce.restart()

    // External access point: other files use `Config.adapter.border.color`
    // etc. instead of reaching into `root` directly.
    property alias sAdapter: configAdapter

    JsonAdapter {
        id: configAdapter

        property JsonObject panels: JsonObject {
            property string backgroundColor: "red"
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
        }

        property JsonObject launcher: JsonObject {
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
            property string backgroundColor: "" // panels.backgroundColor override
            property bool showIcons: true
        }

        property JsonObject clock: JsonObject {
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
            property string mode: "parasitic"
            property string position: "bottom-left"
            property string slideDirection: "diagonal"
            property bool extraTendrils: true

            property real extraVerticalReach: 0.70
            property real extraHorizontalReach: 0.35

            property int extraVerticalCount: 2
            property int extraHorizontalCount: 3

            property real extraVerticalReachSpread: 0.12
            property real extraHorizontalReachSpread: 0.12

            property real extraVerticalTipSpread: 0.55
            property real extraHorizontalTipSpread: 0.55
        }

        property JsonObject tray: JsonObject {
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
            property string mode: "parasitic" // "parasitic" or "subdermal"
            property string position: "top-right"
            property string slideDirection: "diagonal"
            property bool extraTendrils: true
            property real extraVerticalReach: 0.70
            property real extraHorizontalReach: 0.35
            property int extraVerticalCount: 2
            property int extraHorizontalCount: 2
            property real extraVerticalReachSpread: 0.12
            property real extraHorizontalReachSpread: 0.12
            property real extraVerticalTipSpread: 0.55
            property real extraHorizontalTipSpread: 0.55

            // Tray popup menu tendrils use screen-border orientation:
            // horizontal = top/bottom border, vertical = left/right border.
            property int menuVerticalCount: 2
            property int menuHorizontalCount: 2
            property real menuVerticalReach: 0.36
            property real menuHorizontalReach: 0.30
            property real menuVerticalReachSpread: 0.14
            property real menuHorizontalReachSpread: 0.12
            property real menuVerticalTipSpread: 0.44
            property real menuHorizontalTipSpread: 0.55
            property real menuMaxLength: 800
            property string menuPreviewText: "Spreading Infection, Deeper Into Host, Assimilation Stable"
            property real menuScreenInset: 14
        }

        property JsonObject trayMenu: JsonObject {
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
        }

        property JsonObject settingsPanel: JsonObject {
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
        }

        property JsonObject text: JsonObject {
            property color color: "red"
            property color soft: "white"
            property color accent: "blue"
        }

        property JsonObject border: JsonObject {
            property real thickness: 12
            property real rounding: 32
            property real smoothing: 1.5
            property string color: "#7ef9ff"
            property real opacity: 1.0
        }

        property JsonObject shadow: JsonObject {
            property bool enabled: true
            property string color: "#000000"
            property real opacity: 0.6
            property real falloff: 24
        }

        property JsonObject innerEdge: JsonObject {
            property bool enabled: true
            property string color: "#ffffff"
            property real intensity: 0.8
            property real falloff: 16
        }

        property JsonObject tendrils: JsonObject {
            property real growSpeed: 0.8
            property real shrinkSpeed: 0.2
            property real blendRadius: 8
            property real waistSmoothing: 20
            property real jitter: 14
            property real attachDistance: 60
            property real tendrilsPer100px: 2

            property list<real> maxLengthRange: [120, 220]
            property list<real> rootThicknessRange: [3, 5]
            property list<real> panelThicknessRange: [2, 3]
            property list<real> waistThicknessRange: [1, 1]
        }

        property JsonObject wallpaper: JsonObject {
            property string directory: "~/Pictures/Wallpapers"
            property string path: ""
        }

        property JsonObject organicBorder: JsonObject {
            property bool enabled: false
            property string style: "harmonic"

            property real amplitude: 6.0
            property real frequency: 0.018

            property real animationSpeed: 1.0
            property real seed: 17.0

            property bool animated: false
            property real morphSpeed: 0.20
            property real amplitudeRange: 2.0

            property real peakSharpness: 1.0
            property real valleySharpness: 1.0
        }
    }
}
