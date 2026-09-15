// components/Settings.qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."
import "fuzzy.js" as Fuzzy

Item {
    id: root

    required property var targetScreen
    readonly property bool isOpen: SettingsController.isOpenOn(targetScreen)

    property real finalWidth: 780
    property real finalHeight: 520
    property real cornerRounding: 20

    // Match Launcher's exact tendril shrink speed
    property real tendrilsPer100px: 0.6
    property int tendrilMaxActive: 16
    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(400, 800)
    property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(10, 24)
    property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(2, 4)
    property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(5, 8)
    property bool tendrilUseScreenRelativeAttachDistance: true
    property real tendrilAttachOffset: 150

    property real tendrilBlendRadiusRootOverride: 40
    property real tendrilBlendRadiusPanelOverride: 30
    property real tendrilWaistSmoothingOverride: 60

    property real tendrilGrowSpeedOverride: 0.25
    property real tendrilShrinkSpeedOverride: 0.12
    property real tendrilActivationFraction: 0.25

    property int tendrilMaxTop: 6
    property int tendrilMaxRight: 4
    property int tendrilMaxBottom: 6
    property int tendrilMaxLeft: 4
    property int tendrilMaxCorners: 4


    anchors.centerIn: parent
    clip: true

    width: isOpen ? finalWidth : 1
    height: isOpen ? finalHeight : 1

    readonly property bool visuallyOpen: width > 5 || height > 5
    visible: visuallyOpen

    Behavior on width {
        NumberAnimation { duration: 340; easing.type: Easing.OutBack }
    }
    Behavior on height {
        NumberAnimation { duration: 340; easing.type: Easing.OutBack }
    }

    property string currentTab: "All"
    property string searchQuery: ""

    function requestTrayMenuPreview() { if (root.isOpen) SettingsController.requestTrayMenuPreview() }

    Keys.onEscapePressed: SettingsController.close()

    function middleTruncate(str, maxLen) {
        if (!str || str.length <= maxLen) return str;
        var extIdx = str.lastIndexOf(".");
        var ext = extIdx !== -1 ? str.slice(extIdx) : "";
        var name = extIdx !== -1 ? str.slice(0, extIdx) : str;
        var keep = Math.max(1, maxLen - ext.length - 2); // 2 chars for '..'
        var front = Math.ceil(keep * 0.6);
        var back = Math.floor(keep * 0.4);
        return name.slice(0, front) + ".." + name.slice(name.length - back) + ext;
    }

    // -------------------------------------------------------------------------
    // Wallpaper Directory Scanner & Picker
    // -------------------------------------------------------------------------
    property var wallpaperFiles: []

        function scanWallpapers() {
        var rawDir = (Config.sAdapter.wallpaper && Config.sAdapter.wallpaper.directory) 
                     ? Config.sAdapter.wallpaper.directory 
                     : "~/Pictures/Wallpapers";

        // Replace leading ~ with $HOME so sh can expand it, or pass clean directory
        var script = 
            'DIR=$(eval echo "' + rawDir + '"); ' +
            'if [ -d "$DIR" ]; then ' +
            '    find -L "$DIR" -maxdepth 1 -type f \\( ' +
            '        -name "*.png" -o -name "*.PNG" -o ' +
            '        -name "*.jpg" -o -name "*.JPG" -o ' +
            '        -name "*.jpeg" -o -name "*.JPEG" -o ' +
            '        -name "*.webp" -o -name "*.WEBP" ' +
            '    \\) | sort; ' +
            'fi';

        scanProcess.exec(["sh", "-c", script]);
    }

    // Scanner process
    Process {
        id: scanProcess
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                var list = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length > 0) list.push(line);
                }
                root.wallpaperFiles = list;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0) {
                    console.log("Wallpaper scan error:", text.trim());
                }
            }
        }
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchBox.text = "";
            root.searchQuery = "";
            root.scanWallpapers();
            Qt.callLater(function() {
                searchBox.forceActiveFocus();
            });
        }
    }

    // Native Folder Picker Dialog
    Process {
        id: pickFolderProcess
        stdout: StdioCollector {
            onStreamFinished: {
                var picked = text.trim();
                if (picked.length > 0) {
                    Config.sAdapter.wallpaper.directory = picked;
                    root.scanWallpapers();
                }
            }
        }
    }

    function openFolderPicker() {
        pickFolderProcess.exec([
            "sh", "-c",
            "zenity --file-selection --directory --title='Select Wallpaper Folder' 2>/dev/null || " +
            "kdialog --getexistingdirectory \"$HOME\" 2>/dev/null"
        ]);
    }

    Rectangle {
        id: panelBackground
        anchors.fill: parent
        anchors.margins: Theme.innerEdgeFalloff + 10
        radius: Math.max(0, root.cornerRounding - Theme.innerEdgeFalloff)
        antialiasing: true
        color: Theme.launcherBackgroundColor !== "transparent" ? Theme.launcherBackgroundColor : "#1e2030"
        border.color: Theme.borderColor
        border.width: 1
        clip: true

        Item {
            id: content
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // -----------------------------------------------------------------
                // Left Sidebar: Categories / Tabs
                // -----------------------------------------------------------------
                Rectangle {
                    id: sidebar
                    Layout.fillHeight: true
                    Layout.preferredWidth: 180
                    color: Theme.borderColor

                    FeatheredRect {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: "#181926"
                        radius: Math.max(0, root.cornerRounding - Theme.innerEdgeFalloff - 8)
                        feather: 3
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: 8

                            Text {
                                text: "SETTINGS"
                                color: Theme.textColorAccent
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }
                        }

                        Repeater {
                            model: ["All", "Panels", "Launcher", "Clock", "Tray", "Settings", "Power", "Workspaces", "Text", "Border", "Shadows", "Wallpaper"]

                            delegate: Rectangle {
                                id: tabBtn
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8

                                readonly property bool isSelected: root.currentTab === modelData
                                color: isSelected ? "#33ffffff" : (tabMouse.containsMouse ? "#1affffff" : "transparent")

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    text: tabBtn.modelData
                                    color: tabBtn.isSelected ? Theme.textColorAccent : Theme.textColor
                                    font.pixelSize: 14
                                    font.bold: tabBtn.isSelected
                                }

                                MouseArea {
                                    id: tabMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.currentTab = tabBtn.modelData
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // -----------------------------------------------------------------
                // Right Pane: Search Bar & Config Controls
                // -----------------------------------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 16
                    spacing: 12

                    TextField {
                        id: searchBox
                        Layout.fillWidth: true
                        placeholderText: "Search settings..."
                        placeholderTextColor: Theme.textColorSoft
                        color: Theme.textColor
                        font.pixelSize: 15
                        background: Rectangle {
                            color: "#24273a"
                            radius: 8
                            border.color: searchBox.activeFocus ? Theme.textColorAccent : "transparent"
                            border.width: 1
                        }
                        onTextChanged: root.searchQuery = text.trim()
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: contentCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: contentCol
                            width: parent.width
                            spacing: 20

                            function matches(section, key) {
                                if (!root.searchQuery || root.searchQuery.length === 0) return true;
                                var q = root.searchQuery.toLowerCase();
                                var str = (section + " " + key).toLowerCase();
                                return Fuzzy.score(q, str) >= 0;
                            }

                            function isTab(sec) {
                                return root.currentTab === "All" || root.currentTab === sec;
                            }

                            // --- Panels ---
                            ColumnLayout {
                                visible: contentCol.isTab("Panels") && contentCol.matches("Panels", "Background")
                                Layout.fillWidth: true
                                Text { text: "PANELS"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Background Color"
                                    value: Config.sAdapter.panels.backgroundColor
                                    onCommit: function(val) { Config.sAdapter.panels.backgroundColor = val; }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Panels") && contentCol.matches("Panels", "Panel Spikes Enable Frequency Length Sharpness Variance")
                                Text { text: "DEFAULT PANEL SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    visible: true
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.panels.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.panels.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.panels.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.panels.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.panels.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.panels.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.panels.spikeLength
                                    onCommit: function(value) { Config.sAdapter.panels.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.panels.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.panels.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.panels.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.panels.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.panels.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.panels.spikeVariance = Number(value); }
                                }
                            }

                            // --- Launcher ---
                            ColumnLayout {
                                visible: contentCol.isTab("Launcher") && (contentCol.matches("Launcher", "Icons") || contentCol.matches("Launcher", "Background"))
                                Layout.fillWidth: true
                                Text { text: "LAUNCHER"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Show Icons"
                                    isBool: true
                                    boolVal: Config.sAdapter.launcher.showIcons
                                    onCommit: function(val) { Config.sAdapter.launcher.showIcons = !Config.sAdapter.launcher.showIcons; }
                                }
                                SettingRow {
                                    label: "Background Override"
                                    value: Config.sAdapter.launcher.backgroundColor
                                    onCommit: function(val) { Config.sAdapter.launcher.backgroundColor = val; }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Launcher") && contentCol.matches("Launcher", "Launcher Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "LAUNCHER SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.launcher.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.launcher.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.launcher.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.launcher.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.launcher.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.launcher.spikeOverride && Config.sAdapter.launcher.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.launcher.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.launcher.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.launcher.spikeOverride && Config.sAdapter.launcher.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.launcher.spikeLength
                                    onCommit: function(value) { Config.sAdapter.launcher.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.launcher.spikeOverride && Config.sAdapter.launcher.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.launcher.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.launcher.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.launcher.spikeOverride && Config.sAdapter.launcher.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.launcher.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.launcher.spikeVariance = Number(value); }
                                }
                            }

                            // --- Clock ---
                            ColumnLayout {
                                visible: contentCol.isTab("Clock")
                                      && (
                                          contentCol.matches("Clock", "Position")
                                          || contentCol.matches("Clock", "Slide Direction")
                                          || contentCol.matches("Clock", "Extra")
                                          || contentCol.matches("Clock", "Vertical")
                                          || contentCol.matches("Clock", "Horizontal")
                                          || contentCol.matches("Clock", "Reach")
                                          || contentCol.matches("Clock", "Count")
                                          || contentCol.matches("Clock", "Spread")
                                          || contentCol.matches("Clock", "Tip")
                                      )

                                Layout.fillWidth: true

                                Text {
                                    text: "CLOCK"
                                    color: Theme.textColorAccent
                                    font.bold: true
                                    font.pixelSize: 12
                                }

                                SettingRow {
                                    label: "Corner Position"
                                    isEnum: true
                                    enumOptions: [
                                        "bottom-left",
                                        "top-left",
                                        "bottom-right",
                                        "top-right"
                                    ]
                                    value: Config.sAdapter.clock.position
                                    onCommit: function(val) {
                                        Config.sAdapter.clock.position = val;
                                    }
                                }

                                SettingRow {
                                    label: "Slide Direction"
                                    isEnum: true
                                    enumOptions: [
                                        "diagonal",
                                        "vertical",
                                        "horizontal"
                                    ]
                                    value: Config.sAdapter.clock.slideDirection
                                    onCommit: function(val) {
                                        Config.sAdapter.clock.slideDirection = val;
                                    }
                                }

                                SettingRow {
                                    label: "Extra Tendrils"
                                    isBool: true
                                    boolVal: Config.sAdapter.clock.extraTendrils
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraTendrils = value;
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Vertical", "Reach")
                                    label: "Vertical Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraVerticalReach
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraVerticalReach = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Horizontal", "Reach")
                                    label: "Horizontal Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraHorizontalReach
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraHorizontalReach = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Vertical", "Count")
                                    label: "Vertical Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.clock.extraVerticalCount
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraVerticalCount = Math.round(Number(value));
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Horizontal", "Count")
                                    label: "Horizontal Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.clock.extraHorizontalCount
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraHorizontalCount = Math.round(Number(value));
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Vertical", "Reach", "Spread")
                                    label: "Vertical Root Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraVerticalReachSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraVerticalReachSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Horizontal", "Reach", "Spread")
                                    label: "Horizontal Root Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraHorizontalReachSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraHorizontalReachSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Vertical", "Tip", "Spread")
                                    label: "Vertical Tip Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraVerticalTipSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraVerticalTipSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Horizontal", "Tip", "Spread")
                                    label: "Horizontal Tip Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraHorizontalTipSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraHorizontalTipSpread = Number(value);
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Clock") && contentCol.matches("Clock", "Mode")
                                SettingRow {
                                    label: "Clock Mode"
                                    isEnum: true
                                    enumOptions: ["parasitic", "subdermal"]
                                    value: Config.sAdapter.clock.mode
                                    onCommit: function(value) { Config.sAdapter.clock.mode = value; }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Clock") && contentCol.matches("Clock", "Clock Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "CLOCK SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.clock.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.clock.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.clock.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.clock.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.clock.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.clock.spikeOverride && Config.sAdapter.clock.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.clock.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.clock.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.clock.spikeOverride && Config.sAdapter.clock.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.clock.spikeLength
                                    onCommit: function(value) { Config.sAdapter.clock.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.clock.spikeOverride && Config.sAdapter.clock.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.clock.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.clock.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.clock.spikeOverride && Config.sAdapter.clock.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.clock.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.clock.spikeVariance = Number(value); }
                                }
                            }

                            // -------------------------------------------------------------------------
                            // Tray
                            // -------------------------------------------------------------------------
                            ColumnLayout {
                                visible: contentCol.isTab("Tray")
                                      && (
                                          contentCol.matches("Tray", "Mode")
                                          || contentCol.matches("Tray", "Position")
                                          || contentCol.matches("Tray", "Slide")
                                          || contentCol.matches("Tray", "Extra")
                                          || contentCol.matches("Tray", "Vertical")
                                          || contentCol.matches("Tray", "Horizontal")
                                          || contentCol.matches("Tray", "Reach")
                                          || contentCol.matches("Tray", "Count")
                                          || contentCol.matches("Tray", "Spread")
                                          || contentCol.matches("Tray", "Tip")
                                          || contentCol.matches("Tray", "Menu")
                                          || contentCol.matches("Tray", "Inset")
                                          || contentCol.matches("Tray", "Length")
                                      )

                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "TRAY"
                                    color: Theme.textColorAccent
                                    font.bold: true
                                    font.pixelSize: 12
                                }

                                SettingRow {
                                    label: "View Mode"
                                    isEnum: true
                                    enumOptions: ["parasitic", "subdermal"]
                                    value: Config.sAdapter.tray.mode

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.mode = value
                                    }
                                }

                                SettingRow {
                                    label: "Corner Position"
                                    isEnum: true
                                    enumOptions: [
                                        "top-left",
                                        "top-right",
                                        "bottom-left",
                                        "bottom-right"
                                    ]
                                    value: Config.sAdapter.tray.position

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.position = value
                                        root.requestTrayMenuPreview()
                                    }
                                }

                                SettingRow {
                                    label: "Slide Direction"
                                    isEnum: true
                                    enumOptions: ["diagonal", "vertical", "horizontal"]
                                    value: Config.sAdapter.tray.slideDirection

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.slideDirection = value
                                    }
                                }

                                SettingRow {
                                    label: "Extra Tendrils"
                                    isBool: true
                                    boolVal: Config.sAdapter.tray.extraTendrils

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraTendrils = value
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Vertical Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraVerticalReach

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraVerticalReach = Number(value)
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Horizontal Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraHorizontalReach

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraHorizontalReach = Number(value)
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Vertical Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.tray.extraVerticalCount

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraVerticalCount = Math.round(Number(value))
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Horizontal Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.tray.extraHorizontalCount

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraHorizontalCount = Math.round(Number(value))
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Vertical Root Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraVerticalReachSpread

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraVerticalReachSpread = Number(value)
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Horizontal Root Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraHorizontalReachSpread

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraHorizontalReachSpread = Number(value)
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Vertical Tip Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraVerticalTipSpread

                                    onCommit: function(value) {
                                        Config.sAdapter.tray.extraVerticalTipSpread = Number(value)
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.tray.extraTendrils
                                    label: "Horizontal Tip Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.extraHorizontalTipSpread

                                    onCommit: function(value) { Config.sAdapter.tray.extraHorizontalTipSpread = Number(value) }
                                }

                                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#33ffffff"; Layout.topMargin: 8; Layout.bottomMargin: 4 }
                                Text { text: "TRAY MENU TENDRILS"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                Text { Layout.fillWidth: true; text: "Horizontal = top/bottom screen border. Vertical = left/right screen border."; color: Theme.textColorSoft; font.pixelSize: 11; wrapMode: Text.WordWrap }

                                Rectangle {
                                    Layout.preferredWidth: 150
                                    Layout.preferredHeight: 30
                                    radius: 6
                                    color: previewMouse.containsMouse ? "#33ffffff" : "#24273a"
                                    border.color: Theme.textColorAccent
                                    Text { anchors.centerIn: parent; text: "PREVIEW MENU"; color: Theme.textColorAccent; font.pixelSize: 12; font.bold: true }
                                    MouseArea { id: previewMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.requestTrayMenuPreview() }
                                }

                                Text { text: "Preview entries (separate with commas)"; color: Theme.textColorSoft; font.pixelSize: 12 }
                                TextField {
                                    Layout.fillWidth: true
                                    text: Config.sAdapter.tray.menuPreviewText
                                    placeholderText: "Spreading Infection, Deeper Into Host, Assimilation Stable"
                                    color: Theme.textColor
                                    background: Rectangle { color: "#24273a"; radius: 6; border.color: "#313244" }
                                    onTextEdited: {
                                        Config.sAdapter.tray.menuPreviewText = text
                                        root.requestTrayMenuPreview()
                                    }
                                }

                                SettingRow {
                                    label: "Menu Screen Inset"
                                    isNum: true
                                    numMin: 0
                                    numMax: 64
                                    numStep: 1
                                    value: Config.sAdapter.tray.menuScreenInset
                                    onCommit: function(value) { Config.sAdapter.tray.menuScreenInset = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Max Length"
                                    isNum: true
                                    numMin: 100
                                    numMax: 3000
                                    numStep: 25
                                    value: Config.sAdapter.tray.menuMaxLength
                                    onCommit: function(value) { Config.sAdapter.tray.menuMaxLength = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Vertical Reach"
                                    isNum: true
                                    numMin: 0.02
                                    numMax: 0.48
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuVerticalReach
                                    onCommit: function(value) { Config.sAdapter.tray.menuVerticalReach = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Horizontal Reach"
                                    isNum: true
                                    numMin: 0.02
                                    numMax: 0.48
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuHorizontalReach
                                    onCommit: function(value) { Config.sAdapter.tray.menuHorizontalReach = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Vertical Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 8
                                    numStep: 1
                                    value: Config.sAdapter.tray.menuVerticalCount
                                    onCommit: function(value) { Config.sAdapter.tray.menuVerticalCount = Math.round(Number(value)); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Horizontal Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 8
                                    numStep: 1
                                    value: Config.sAdapter.tray.menuHorizontalCount
                                    onCommit: function(value) { Config.sAdapter.tray.menuHorizontalCount = Math.round(Number(value)); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Vertical Root Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuVerticalReachSpread
                                    onCommit: function(value) { Config.sAdapter.tray.menuVerticalReachSpread = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Horizontal Root Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuHorizontalReachSpread
                                    onCommit: function(value) { Config.sAdapter.tray.menuHorizontalReachSpread = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Vertical Tip Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuVerticalTipSpread
                                    onCommit: function(value) { Config.sAdapter.tray.menuVerticalTipSpread = Number(value); root.requestTrayMenuPreview() }
                                }
                                SettingRow {
                                    label: "Menu Horizontal Tip Spread"
                                    isNum: true
                                    numMin: 0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.tray.menuHorizontalTipSpread
                                    onCommit: function(value) { Config.sAdapter.tray.menuHorizontalTipSpread = Number(value); root.requestTrayMenuPreview() }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Tray") && contentCol.matches("Tray", "Tray Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "TRAY SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.tray.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.tray.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.tray.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.tray.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.tray.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.tray.spikeOverride && Config.sAdapter.tray.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.tray.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.tray.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.tray.spikeOverride && Config.sAdapter.tray.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.tray.spikeLength
                                    onCommit: function(value) { Config.sAdapter.tray.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.tray.spikeOverride && Config.sAdapter.tray.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.tray.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.tray.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.tray.spikeOverride && Config.sAdapter.tray.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.tray.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.tray.spikeVariance = Number(value); }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Tray") && contentCol.matches("Tray", "Tray Menu Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "TRAY MENU SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.trayMenu.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.trayMenu.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.trayMenu.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.trayMenu.spikeOverride && Config.sAdapter.trayMenu.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.trayMenu.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.trayMenu.spikeOverride && Config.sAdapter.trayMenu.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.trayMenu.spikeLength
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.trayMenu.spikeOverride && Config.sAdapter.trayMenu.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.trayMenu.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.trayMenu.spikeOverride && Config.sAdapter.trayMenu.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.trayMenu.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.trayMenu.spikeVariance = Number(value); }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Settings") && contentCol.matches("Settings", "Settings Panel Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "SETTINGS PANEL SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.settingsPanel.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.settingsPanel.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.settingsPanel.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.settingsPanel.spikeOverride && Config.sAdapter.settingsPanel.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.settingsPanel.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.settingsPanel.spikeOverride && Config.sAdapter.settingsPanel.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.settingsPanel.spikeLength
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.settingsPanel.spikeOverride && Config.sAdapter.settingsPanel.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.settingsPanel.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.settingsPanel.spikeOverride && Config.sAdapter.settingsPanel.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.settingsPanel.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.settingsPanel.spikeVariance = Number(value); }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Power") && contentCol.matches("Power", "Tendrils Count Root Waist Tip Thickness")
                                Text { text: "POWER MENU TENDRILS"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Tendrils per Side"; isNum: true
                                    numMin: 1; numMax: 2; numStep: 1
                                    value: Config.sAdapter.powerMenu.tendrilsPerSide
                                    onCommit: function(value) { Config.sAdapter.powerMenu.tendrilsPerSide = Number(value); }
                                }
                                SettingRow {
                                    label: "Root Thickness"; isNum: true
                                    numMin: 2; numMax: 30; numStep: 1
                                    value: Config.sAdapter.powerMenu.rootThickness
                                    onCommit: function(value) { Config.sAdapter.powerMenu.rootThickness = Number(value); }
                                }
                                SettingRow {
                                    label: "Waist Thickness"; isNum: true
                                    numMin: 1; numMax: 8; numStep: 0.5
                                    value: Config.sAdapter.powerMenu.waistThickness
                                    onCommit: function(value) { Config.sAdapter.powerMenu.waistThickness = Number(value); }
                                }
                                SettingRow {
                                    label: "Panel Tip Thickness"; isNum: true
                                    numMin: 1; numMax: 16; numStep: 1
                                    value: Config.sAdapter.powerMenu.tipThickness
                                    onCommit: function(value) { Config.sAdapter.powerMenu.tipThickness = Number(value); }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Power") && contentCol.matches("Power", "Power Menu Spikes Frequency Length Sharpness Variance Override")
                                Text { text: "POWER MENU SPIKES"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Override Global Spikes"; isBool: true
                                    boolVal: Config.sAdapter.powerMenu.spikeOverride
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikeOverride = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.powerMenu.spikeOverride
                                    label: "Enable Spikes"; isBool: true
                                    boolVal: Config.sAdapter.powerMenu.spikesEnabled
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikesEnabled = value; }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.powerMenu.spikeOverride && Config.sAdapter.powerMenu.spikesEnabled
                                    label: "Frequency (per 100 px)"; isNum: true
                                    numMin: 0.5; numMax: 10; numStep: 0.5
                                    value: Config.sAdapter.powerMenu.spikeFrequency
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikeFrequency = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.powerMenu.spikeOverride && Config.sAdapter.powerMenu.spikesEnabled
                                    label: "Spike Length (px)"; isNum: true
                                    numMin: 0; numMax: 40; numStep: 1
                                    value: Config.sAdapter.powerMenu.spikeLength
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikeLength = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.powerMenu.spikeOverride && Config.sAdapter.powerMenu.spikesEnabled
                                    label: "Spike Sharpness"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.powerMenu.spikeSharpness
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikeSharpness = Number(value); }
                                }
                                SettingRow {
                                    visible: Config.sAdapter.powerMenu.spikeOverride && Config.sAdapter.powerMenu.spikesEnabled
                                    label: "Length Variance"; isNum: true
                                    numMin: 0; numMax: 1; numStep: 0.05
                                    value: Config.sAdapter.powerMenu.spikeVariance
                                    onCommit: function(value) { Config.sAdapter.powerMenu.spikeVariance = Number(value); }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: contentCol.isTab("Workspaces") && contentCol.matches("Workspaces", "Indicator Enabled Dock Edge Auto Hide Count Virtual Desktops Vdesk Numbers Tube Transition Reveal Change Duration Tendrils Spacing Radius")
                                Text { text: "WORKSPACE INDICATOR"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Enabled"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.enabled
                                    onCommit: function(value) { Config.sAdapter.workspaces.enabled = value; }
                                }
                                SettingRow {
                                    label: "Hide Until Hovered"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.autoHide
                                    onCommit: function(value) { Config.sAdapter.workspaces.autoHide = value; }
                                }
                                SettingRow {
                                    label: "Virtual Desktops (vdesk)"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.vdesk
                                    onCommit: function(value) { Config.sAdapter.workspaces.vdesk = value; }
                                }
                                SettingRow {
                                    label: "Show Numbers"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.showNumbers
                                    onCommit: function(value) { Config.sAdapter.workspaces.showNumbers = value; }
                                }
                                SettingRow {
                                    label: "Dock Edge"; isEnum: true
                                    enumOptions: ["top", "right", "bottom", "left"]
                                    value: Config.sAdapter.workspaces.edge
                                    onCommit: function(value) { Config.sAdapter.workspaces.edge = value; }
                                }
                                SettingRow {
                                    label: "Visible Workspaces / Desktops"; isNum: true
                                    numMin: 1; numMax: 12; numStep: 1
                                    value: Config.sAdapter.workspaces.count
                                    onCommit: function(value) { Config.sAdapter.workspaces.count = Number(value); }
                                }
                                SettingRow {
                                    label: "Tube Radius"; isNum: true
                                    numMin: 2; numMax: 9; numStep: 0.5
                                    value: Config.sAdapter.workspaces.tubeRadius
                                    onCommit: function(value) { Config.sAdapter.workspaces.tubeRadius = Number(value); }
                                }
                                SettingRow {
                                    label: "Node Spacing"; isNum: true
                                    numMin: 30; numMax: 90; numStep: 1
                                    value: Config.sAdapter.workspaces.nodeSpacing
                                    onCommit: function(value) { Config.sAdapter.workspaces.nodeSpacing = Number(value); }
                                }
                                SettingRow {
                                    label: "Chamber Radius"; isNum: true
                                    numMin: 8; numMax: 30; numStep: 1
                                    value: Config.sAdapter.workspaces.chamberRadius
                                    onCommit: function(value) { Config.sAdapter.workspaces.chamberRadius = Number(value); }
                                }
                                SettingRow {
                                    label: "Liquid Transition (ms)"; isNum: true
                                    numMin: 150; numMax: 1200; numStep: 50
                                    value: Config.sAdapter.workspaces.duration
                                    onCommit: function(value) { Config.sAdapter.workspaces.duration = Number(value); }
                                }
                                SettingRow {
                                    label: "Show on Workspace Change"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.showOnChange
                                    onCommit: function(value) { Config.sAdapter.workspaces.showOnChange = value; }
                                }
                                SettingRow {
                                    label: "Indicator Tendrils"; isBool: true
                                    boolVal: Config.sAdapter.workspaces.tendrils
                                    onCommit: function(value) { Config.sAdapter.workspaces.tendrils = value; }
                                }
                                SettingRow {
                                    label: "Fully Visible Time (ms)"; isNum: true
                                    numMin: 100; numMax: 5000; numStep: 100
                                    value: Config.sAdapter.workspaces.revealDuration
                                    onCommit: function(value) { Config.sAdapter.workspaces.revealDuration = Number(value); }
                                }
                                SettingRow {
                                    label: "Indicator Tendril Width"; isNum: true
                                    numMin: 1; numMax: 6; numStep: 0.5
                                    value: Config.sAdapter.workspaces.tendrilWidth
                                    onCommit: function(value) { Config.sAdapter.workspaces.tendrilWidth = Number(value); }
                                }
                                Text {
                                    visible: Config.sAdapter.workspaces.vdesk && WorkspaceController.vdeskError.length > 0
                                    text: WorkspaceController.vdeskError
                                    color: Theme.textColorSoft
                                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                                }
                            }

                            // --- Text ---
                            ColumnLayout {
                                visible: contentCol.isTab("Text") && (contentCol.matches("Text", "Color") || contentCol.matches("Text", "Soft") || contentCol.matches("Text", "Accent"))
                                Layout.fillWidth: true
                                Text { text: "TEXT"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Text Color"
                                    value: Config.sAdapter.text.color
                                    onCommit: function(val) { Config.sAdapter.text.color = val; }
                                }
                                SettingRow {
                                    label: "Soft Text Color"
                                    value: Config.sAdapter.text.soft
                                    onCommit: function(val) { Config.sAdapter.text.soft = val; }
                                }
                                SettingRow {
                                    label: "Accent Color"
                                    value: Config.sAdapter.text.accent
                                    onCommit: function(val) { Config.sAdapter.text.accent = val; }
                                }
                            }

                            // --- Border ---
                            ColumnLayout {
                                visible: contentCol.isTab("Border")
                                      && (
                                          contentCol.matches("Border", "Thickness")
                                          || contentCol.matches("Border", "Rounding")
                                          || contentCol.matches("Border", "Color")
                                          || contentCol.matches("Border", "Organic")
                                          || contentCol.matches("Border", "Ripple")
                                          || contentCol.matches("Border", "Frequency")
                                          || contentCol.matches("Border", "Peak")
                                          || contentCol.matches("Border", "Valley")
                                          || contentCol.matches("Border", "Motion")
                                          || contentCol.matches("Border", "Animated")
                                          || contentCol.matches("Border", "Morph")
                                          || contentCol.matches("Border", "Drift")
                                      )
                                Layout.fillWidth: true
                                Text { text: "BORDER"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }
                                SettingRow {
                                    label: "Thickness"
                                    isNum: true
                                    numMin: 2; numMax: 32
                                    value: Config.sAdapter.border.thickness
                                    onCommit: function(val) { Config.sAdapter.border.thickness = Number(val); }
                                }
                                SettingRow {
                                    label: "Rounding"
                                    isNum: true
                                    numMin: 0; numMax: 64
                                    value: Config.sAdapter.border.rounding
                                    onCommit: function(val) { Config.sAdapter.border.rounding = Number(val); }
                                }
                                SettingRow {
                                    label: "Color"
                                    value: Config.sAdapter.border.color
                                    onCommit: function(val) { Config.sAdapter.border.color = val; }
                                }
                                SettingRow {
                                    label: "Organic Edge (Experimental)"
                                    isBool: true
                                    boolVal: Config.sAdapter.organicBorder.enabled
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.enabled = value;
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Ripple", "Amount")
                                    label: "Ripple Amount"
                                    isNum: true
                                    numMin: 0
                                    numMax: 16
                                    numStep: 0.5
                                    value: Config.sAdapter.organicBorder.amplitude
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.amplitude = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Ripple", "Frequency")
                                    label: "Ripple Frequency"
                                    isNum: true
                                    numMin: 0.002
                                    numMax: 0.08
                                    numStep: 0.001
                                    value: Config.sAdapter.organicBorder.frequency
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.frequency = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Peak", "Pointiness")
                                    label: "Peak Pointiness"
                                    isNum: true
                                    numMin: 0.3
                                    numMax: 4.0
                                    numStep: 0.1
                                    value: Config.sAdapter.organicBorder.peakSharpness
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.peakSharpness = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Valley", "Pointiness")
                                    label: "Valley Pointiness"
                                    isNum: true
                                    numMin: 0.3
                                    numMax: 4.0
                                    numStep: 0.1
                                    value: Config.sAdapter.organicBorder.valleySharpness
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.valleySharpness = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Motion", "Speed")
                                    label: "Motion Speed"
                                    isNum: true
                                    numMin: 0
                                    numMax: 50
                                    numStep: 1
                                    value: Config.sAdapter.organicBorder.animationSpeed
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.animationSpeed = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && contentCol.matches("Border", "Animated", "Shape")
                                    label: "Animated Shape"
                                    isBool: true
                                    boolVal: Config.sAdapter.organicBorder.animated
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.animated = value;
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && Config.sAdapter.organicBorder.animated && contentCol.matches("Border", "Morph", "Speed")
                                    label: "Morph Speed"
                                    isNum: true
                                    numMin: 0.001
                                    numMax: 0.05
                                    numStep: 0.001
                                    value: Config.sAdapter.organicBorder.morphSpeed
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.morphSpeed = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.organicBorder.enabled && Config.sAdapter.organicBorder.animated && contentCol.matches("Border", "Amplitude", "Drift")
                                    label: "Amplitude Drift"
                                    isNum: true
                                    numMin: 0
                                    numMax: 8
                                    numStep: 0.25
                                    value: Config.sAdapter.organicBorder.amplitudeRange
                                    onCommit: function(value) {
                                        Config.sAdapter.organicBorder.amplitudeRange = Number(value);
                                    }
                                }
                            }

                            // --- Shadows & Glow ---
                            ColumnLayout {
                                visible: contentCol.isTab("Shadows") && (contentCol.matches("Shadows", "Outer") || contentCol.matches("Shadows", "Inner"))
                                Layout.fillWidth: true
                                Text { text: "SHADOWS & INNER GLOW"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }

                                SettingRow {
                                    label: "Outer Shadow Enabled"
                                    isBool: true
                                    boolVal: Config.sAdapter.shadow.enabled
                                    onCommit: function(val) { Config.sAdapter.shadow.enabled = !Config.sAdapter.shadow.enabled; }
                                }
                                SettingRow {
                                    label: "Outer Shadow Color"
                                    value: Config.sAdapter.shadow.color
                                    onCommit: function(val) { Config.sAdapter.shadow.color = val; }
                                }
                                SettingRow {
                                    label: "Outer Shadow Opacity"
                                    isNum: true
                                    numMin: 0.0; numMax: 1.0
                                    value: Config.sAdapter.shadow.opacity
                                    onCommit: function(val) { Config.sAdapter.shadow.opacity = Number(val); }
                                }
                                SettingRow {
                                    label: "Outer Shadow Falloff"
                                    isNum: true
                                    numMin: 4; numMax: 64
                                    value: Config.sAdapter.shadow.falloff
                                    onCommit: function(val) { Config.sAdapter.shadow.falloff = Number(val); }
                                }

                                SettingRow {
                                    label: "Inner Edge Glow Enabled"
                                    isBool: true
                                    boolVal: Config.sAdapter.innerEdge.enabled
                                    onCommit: function(val) { Config.sAdapter.innerEdge.enabled = !Config.sAdapter.innerEdge.enabled; }
                                }
                                SettingRow {
                                    label: "Inner Edge Color"
                                    value: Config.sAdapter.innerEdge.color
                                    onCommit: function(val) { Config.sAdapter.innerEdge.color = val; }
                                }
                                SettingRow {
                                    label: "Inner Edge Intensity"
                                    isNum: true
                                    numMin: 0.0; numMax: 2.0
                                    value: Config.sAdapter.innerEdge.intensity
                                    onCommit: function(val) { Config.sAdapter.innerEdge.intensity = Number(val); }
                                }
                                SettingRow {
                                    label: "Inner Edge Falloff"
                                    isNum: true
                                    numMin: 2; numMax: 32
                                    value: Config.sAdapter.innerEdge.falloff
                                    onCommit: function(val) { Config.sAdapter.innerEdge.falloff = Number(val); }
                                }
                            }

                            // --- Wallpaper ---
                            ColumnLayout {
                                visible: contentCol.isTab("Wallpaper") && (contentCol.matches("Wallpaper", "Directory") || contentCol.matches("Wallpaper", "Grid"))
                                Layout.fillWidth: true
                                spacing: 14

                                Text { text: "WALLPAPER"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 12 }

                                // Directory input row + Browse button
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: "Directory:"
                                        color: Theme.textColor
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 80
                                    }

                                    TextField {
                                        id: dirInput
                                        Layout.fillWidth: true
                                        text: Config.sAdapter.wallpaper.directory || "~/Pictures/Wallpapers"
                                        color: Theme.textColor
                                        font.pixelSize: 13
                                        background: Rectangle {
                                            color: "#24273a"
                                            radius: 6
                                            border.color: "#313244"
                                            border.width: 1
                                        }
                                        onEditingFinished: {
                                            Config.sAdapter.wallpaper.directory = text.trim();
                                            root.scanWallpapers();
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 74
                                        Layout.preferredHeight: 32
                                        radius: 6
                                        color: browseMouse.containsMouse ? "#33ffffff" : "#24273a"
                                        border.color: "#313244"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Browse"
                                            color: Theme.textColorAccent
                                            font.pixelSize: 13
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: browseMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: root.openFolderPicker()
                                        }
                                    }
                                }

                                // Empty state notice
                                Text {
                                    visible: root.wallpaperFiles.length === 0
                                    text: "No images (.png, .jpg, .webp) found in directory."
                                    color: Theme.textColorSoft
                                    font.pixelSize: 13
                                }

                                // Thumbnail Grid
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Repeater {
                                        model: root.wallpaperFiles

                                        delegate: Rectangle {
                                            id: thumbCard
                                            required property string modelData
                                            width: 156
                                            height: 118
                                            radius: 8

                                            readonly property string filename: modelData.split("/").pop()
                                            readonly property bool isCurrent: Config.sAdapter.wallpaper.path === modelData

                                            color: isCurrent ? "#22" + Theme.textColorAccent.toString().slice(1) : (thumbMouse.containsMouse ? "#2e3248" : "#24273a")
                                            border.color: isCurrent ? Theme.textColorAccent : (thumbMouse.containsMouse ? "#494d64" : "#313244")
                                            border.width: isCurrent ? 2 : 1

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                spacing: 6

                                                // Thumbnail image preview
                                                Rectangle {
                                                    width: parent.width
                                                    height: 80
                                                    radius: 4
                                                    clip: true
                                                    color: "#181926"

                                                    Image {
                                                        anchors.fill: parent
                                                        source: "file://" + thumbCard.modelData
                                                        fillMode: Image.PreserveAspectCrop
                                                        asynchronous: true
                                                        cache: true
                                                        sourceSize.width: 240
                                                        sourceSize.height: 160
                                                    }
                                                }

                                                // Middle-truncated filename text
                                                Text {
                                                    width: parent.width
                                                    text: root.middleTruncate(thumbCard.filename, 20)
                                                    color: thumbCard.isCurrent ? Theme.textColorAccent : Theme.textColor
                                                    font.pixelSize: 11
                                                    font.bold: thumbCard.isCurrent
                                                    horizontalAlignment: Text.AlignHCenter
                                                }
                                            }

                                            MouseArea {
                                                id: thumbMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    Config.sAdapter.wallpaper.path = thumbCard.modelData;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Setting Row Helper (Includes ComboBox with Hover Highlight)
    // -------------------------------------------------------------------------
    component SettingRow: RowLayout {
        id: row
        required property string label
        property var value: ""
        property bool isNum: false
        property bool isBool: false
        property bool isEnum: false
        property var enumOptions: []
        property bool boolVal: false
        property real numMin: 0
        property real numMax: 100
        property real numStep: 1

        signal commit(var val)

        Layout.fillWidth: true
        Layout.preferredHeight: 38

        Text {
            Layout.fillWidth: true
            text: row.label
            color: Theme.textColor
            font.pixelSize: 14
        }

        ComboBox {
            id: combo
            visible: row.isEnum
            Layout.preferredWidth: 160
            model: row.enumOptions
            currentIndex: Math.max(0, row.enumOptions.indexOf(String(row.value)))

            contentItem: Text {
                leftPadding: 10
                text: combo.displayText
                font.pixelSize: 13
                color: Theme.textColorAccent
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                color: combo.hovered ? "#2e3248" : "#24273a"
                radius: 6
                border.color: combo.hovered ? Theme.textColorAccent : "#313244"
                border.width: 1
            }

            delegate: ItemDelegate {
                id: itemDel
                required property string modelData
                required property int index

                width: combo.width
                height: 32
                hoverEnabled: true

                contentItem: Text {
                    text: itemDel.modelData
                    color: (itemDel.hovered || itemDel.highlighted) ? Theme.textColorAccent : Theme.textColor
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 10
                    font.bold: itemDel.hovered || itemDel.highlighted
                }

                background: Rectangle {
                    color: itemDel.hovered ? "#33ffffff" : (itemDel.highlighted ? "#1affffff" : "transparent")
                    radius: 4
                }
            }

            popup: Popup {
                y: combo.height + 4
                width: combo.width
                implicitHeight: Math.min(200, contentItem.implicitHeight + 8)
                padding: 4

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: combo.popup.visible ? combo.delegateModel : null
                    currentIndex: combo.highlightedIndex
                }

                background: Rectangle {
                    color: "#1e2030"
                    radius: 6
                    border.color: Theme.borderColor
                    border.width: 1
                }
            }

            onActivated: function(index) {
                row.commit(currentText);
            }
        }

        Rectangle {
            visible: row.isBool
            Layout.preferredWidth: 44
            Layout.preferredHeight: 24
            radius: 12
            color: row.boolVal ? Theme.textColorAccent : "#313244"

            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                x: row.boolVal ? 22 : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: row.commit(!row.boolVal)
            }
        }

        Slider {
            visible: row.isNum
            Layout.preferredWidth: 160
            from: row.numMin
            to: row.numMax
            stepSize: row.numStep
            value: Number(row.value) || 0
            onMoved: row.commit(value)
        }

        TextField {
            visible: !row.isBool && !row.isNum && !row.isEnum
            Layout.preferredWidth: 160
            text: String(row.value || "")
            color: Theme.textColor
            font.pixelSize: 13
            background: Rectangle {
                color: "#24273a"
                radius: 6
                border.color: "#313244"
                border.width: 1
            }
            onEditingFinished: row.commit(text)
        }
    }
}
