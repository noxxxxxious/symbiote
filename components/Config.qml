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

    watchChanges: true
    onFileChanged: reload()

    // If you ever add QML-side writes back to config (e.g. a settings UI),
    // this persists them. Harmless to leave in even if you only ever hand-
    // edit the JSON.
    onAdapterUpdated: writeAdapter()

    // External access point: other files use `Config.adapter.border.color`
    // etc. instead of reaching into `root` directly.
    property alias sAdapter: configAdapter

    JsonAdapter {
        id: configAdapter

        property JsonObject panels: JsonObject {
            property string backgroundColor: "red"
        }

        property JsonObject launcher: JsonObject {
            property string backgroundColor: "" // panels.backgroundColor override
            property bool showIcons: true
        }

        property JsonObject clock: JsonObject {
            property string position: "bottom-left"
            property string slideDirection: "diagonal"
            property bool extraTendrils: true

            property real extraShortReach: 0.35
            property real extraLongReach: 0.70

            property int extraShortCount: 3
            property int extraLongCount: 2

            property real extraShortReachSpread: 0.12
            property real extraLongReachSpread: 0.12

            property real extraShortTipSpread: 0.55
            property real extraLongTipSpread: 0.55
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
