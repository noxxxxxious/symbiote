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

    // Direct writes avoid QSaveFile's random-suffix sibling files
    // (config.json.XXXXXX). Settings are already debounced, so this remains a
    // very small write and avoids littering the shell directory with stale
    // atomic-write temporaries.
    atomicWrites: false

    // FileView reports changes caused by our own writes too. Ignore those for a
    // short window so an internal save cannot turn into save -> reload -> save
    // feedback, while still preserving hot reload for real external edits.
    property bool internalWriteWindow: false

    watchChanges: true
    onFileChanged: {
        if (!root.internalWriteWindow)
            reload()
    }

    property Timer internalWriteGuard: Timer {
        interval: 500
        repeat: false
        onTriggered: root.internalWriteWindow = false
    }

    property Timer saveDebounce: Timer {
        interval: 300
        repeat: false
        onTriggered: {
            root.internalWriteWindow = true
            root.writeAdapter()
            internalWriteGuard.restart()
        }
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


        property JsonObject dashboard: JsonObject {
            // Panel geometry / interaction.
            property real width: 920
            property real height: 430
            property real topGap: 26
            property real cornerRounding: 24
            property int closeDelay: 650

            // Info-tab vocabulary. Presentation only: these names can be
            // changed freely without affecting the metrics they represent.
            property string infoSystemName: "Organism"
            property string infoProcessorName: "Nucleus"
            property string infoMemoryName: "Synapses"
            property string infoStorageName: "Genome"

            // Normal randomized tendrils. These attach only to the dashboard's top edge.
            property bool tendrils: true
            property real tendrilsPer100px: 0.70
            property int tendrilMaxActive: 6
            property int tendrilMaxTop: 6
            property real tendrilMinLength: 45
            property real tendrilMaxLength: 110
            property real tendrilRootMinWidth: 7
            property real tendrilRootMaxWidth: 14
            property real tendrilWaistMinWidth: 2
            property real tendrilWaistMaxWidth: 4
            property real tendrilTipMinWidth: 5
            property real tendrilTipMaxWidth: 9
            property real tendrilRootBlend: 34
            property real tendrilTipBlend: 24
            property real tendrilWaistSmoothing: 54
            property real tendrilGrowSpeed: 0.22
            property real tendrilShrinkSpeed: 0.14

            // Guaranteed long links. Side and bottom geometry/thickness are separate
            // so each fan can be tuned independently.
            property bool extraTendrils: false
            property real extraGrowSpeed: 0.16
            property real extraShrinkSpeed: 0.10

            property bool sideExtraTendrils: true
            property int sideExtraCount: 2
            property real sideExtraRootReach: 0.20
            property real sideExtraRootSpread: 0.14
            property real sideExtraTipSpread: 0.70
            property real sideExtraMinLength: 260
            property real sideExtraMaxLength: 1600
            property real sideExtraRootMinWidth: 5
            property real sideExtraRootMaxWidth: 10
            property real sideExtraWaistMinWidth: 1.5
            property real sideExtraWaistMaxWidth: 3
            property real sideExtraTipMinWidth: 3
            property real sideExtraTipMaxWidth: 6

            property bool bottomExtraTendrils: true
            property int bottomExtraCount: 3
            property real bottomExtraRootSpread: 0.42
            property real bottomExtraTipSpread: 0.68
            property real bottomExtraMinLength: 320
            property real bottomExtraMaxLength: 1800
            property real bottomExtraRootMinWidth: 5
            property real bottomExtraRootMaxWidth: 10
            property real bottomExtraWaistMinWidth: 1.5
            property real bottomExtraWaistMaxWidth: 3
            property real bottomExtraTipMinWidth: 3
            property real bottomExtraTipMaxWidth: 6
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

        property JsonObject notifications: JsonObject {
            property string toastName: "Synaptic Pulse"
            property string centerName: "Neuron Engagement"
            property string position: "bottom-right"
            property bool centerExtraTendrils: true
            property int centerExtraTendrilCount: 3
            property real centerExtraTendrilReach: 0.28
            property real centerExtraTendrilRootSpread: 0.58
            property real centerExtraTendrilTipSpread: 0.46
            property string toastPosition: "bottom-left"
            property int toastDuration: 6000
            property real toastHorizontalOffset: 0
            property real toastVerticalOffset: 0
            property string toastScreenMode: "current active screen"
            property string toastScreen: ""
            property bool toastTendrils: true
            property real toastTendrilsPer100px: 1.5
            property int toastTendrilMaxActive: 6
            property bool toastExtraTendrils: false
            property int toastExtraTendrilCount: 2
            property real toastExtraTendrilReach: 0.45
            property real toastExtraTendrilRootSpread: 0.30
            property real toastExtraTendrilPanelSpread: 0.90
            property real toastExtraTendrilRootWidth: 5
            property real toastExtraTendrilWaistWidth: 2
            property real toastExtraTendrilPanelWidth: 3
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
        }

        property JsonObject powerMenu: JsonObject {
            property int tendrilsPerSide: 1
            property real rootThickness: 16
            property real waistThickness: 3
            property real tipThickness: 7
            property bool spikeOverride: false
            property bool spikesEnabled: false
            property real spikeFrequency: 3
            property real spikeLength: 10
            property real spikeVariance: 0.3
            property real spikeSharpness: 0.75
        }

        property JsonObject workspaces: JsonObject {
            property bool enabled: true
            property string edge: "top"
            property bool autoHide: true
            property int count: 5
            property bool vdesk: false
            property bool showNumbers: true
            // Distance from the dock edge toward the middle of the screen.
            property real dockInset: 0
            property real tubeRadius: 5
            property real nodeSpacing: 46
            property real chamberRadius: 17
            property int duration: 480
            // The active-workspace liquid is a two-lobe spring system: the
            // secondary mass trails, passes through the leader, then recoils.
            property real liquidFollowerScale: 0.72
            property real liquidSlingshot: 1.0
            property real liquidRecoil: 1.0
            property bool liquidIdlePulse: true
            property real liquidPulseStrength: 1.75
            property real liquidPulseSpeed: 0.55
            property bool showOnChange: true
            property int revealDuration: 1500
            property bool tendrils: true
            // Workspace tendrils belong to the indicator as a whole, not to
            // individual chambers. Count is therefore the total rendered pool.
            property int tendrilCount: 6
            property real tendrilWidth: 3
            property real tendrilReach: 36
            property real tendrilRootWidth: 4
            property real tendrilTipWidth: 2
            property real tendrilJitter: 14
            property real tendrilSpread: 0.90
        }

        property JsonObject text: JsonObject {
            property color color: "red"
            property color soft: "white"
            property color accent: "blue"
            // Secondary UI surface: settings sidebar, inputs/readouts, menus, etc.
            property color secondary: "#24273a"
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
