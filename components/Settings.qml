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
                            model: ["All", "Panels", "Launcher", "Clock", "Text", "Border", "Shadows", "Wallpaper"]

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

                            // --- Clock ---
                            ColumnLayout {
                                visible: contentCol.isTab("Clock")
                                      && (
                                          contentCol.matches("Clock", "Position")
                                          || contentCol.matches("Clock", "Slide Direction")
                                          || contentCol.matches("Clock", "Extra")
                                          || contentCol.matches("Clock", "Short")
                                          || contentCol.matches("Clock", "Long")
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
                                          && contentCol.matches("Clock", "Short", "Reach")
                                    label: "Short Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraShortReach
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraShortReach = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Long", "Reach")
                                    label: "Long Reach"
                                    isNum: true
                                    numMin: 0.05
                                    numMax: 0.95
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraLongReach
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraLongReach = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Short", "Count")
                                    label: "Short Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.clock.extraShortCount
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraShortCount = Math.round(Number(value));
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Long", "Count")
                                    label: "Long Count"
                                    isNum: true
                                    numMin: 0
                                    numMax: 12
                                    numStep: 1
                                    value: Config.sAdapter.clock.extraLongCount
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraLongCount = Math.round(Number(value));
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Short", "Reach", "Spread")
                                    label: "Short Root Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraShortReachSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraShortReachSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Long", "Reach", "Spread")
                                    label: "Long Root Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraLongReachSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraLongReachSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Short", "Tip", "Spread")
                                    label: "Short Tip Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraShortTipSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraShortTipSpread = Number(value);
                                    }
                                }

                                SettingRow {
                                    visible: Config.sAdapter.clock.extraTendrils
                                          && contentCol.matches("Clock", "Long", "Tip", "Spread")
                                    label: "Long Tip Spread"
                                    isNum: true
                                    numMin: 0.0
                                    numMax: 0.90
                                    numStep: 0.01
                                    value: Config.sAdapter.clock.extraLongTipSpread
                                    onCommit: function(value) {
                                        Config.sAdapter.clock.extraLongTipSpread = Number(value);
                                    }
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
