// components/Launcher.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import "."
import "fuzzy.js" as Fuzzy

Item {
    id: launcher

    required property var targetScreen
    readonly property bool isOpen: LauncherController.isOpenOn(targetScreen)

    property real finalWidth: 640
    property real finalHeight: 420
    property real cornerRounding: 28

    property real tendrilsPer100px: 0.5
    property int tendrilMaxActive: 20
    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(500, 900)
    property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(15, 40)
    property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(3, 5)
    property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(7, 11)
    property bool tendrilUseScreenRelativeAttachDistance: true
    property real tendrilAttachOffset: 200

    property real tendrilBlendRadiusRootOverride: 60
    property real tendrilBlendRadiusPanelOverride: 40
    property real tendrilWaistSmoothingOverride: 100

    property real tendrilGrowSpeedOverride: 0.25
    property real tendrilShrinkSpeedOverride: 0.12

    property int tendrilMaxCorners: 4

    // Sorted, filtered results: most-used apps float to the top even while
    // a search query is active, as long as they still match the query.
    property var filteredApps: []

    anchors.centerIn: parent
    clip: true

    width: isOpen ? finalWidth : 1
    height: isOpen ? finalHeight : 1

    visible: width > 5 || height > 5

    Behavior on width {
        NumberAnimation { duration: 340; easing.type: Easing.OutBack; }
    }
    Behavior on height {
        NumberAnimation { duration: 340; easing.type: Easing.OutBack; }
    }

    function rebuildList() {
        var src = DesktopEntries.applications;
        var apps = src.values ? src.values : [];

        var q = searchField.text.trim();
        var scored = [];

        for (var i = 0; i < apps.length; i++) {
            var entry = apps[i];
            if (!entry || entry.noDisplay)
                continue;

            var matchScore = 0;
            if (q.length > 0) {
                matchScore = Fuzzy.score(q, entry.name);
                if (matchScore < 0)
                    continue; // no match at all - excluded, not just ranked low
            }

            scored.push({
                entry: entry,
                score: matchScore,
                usage: AppUsage.usageFor(entry.id)
            });
        }

        scored.sort(function (a, b) {
            // Usage always wins first, REGARDLESS of query - a frequently
            // used app that still matches the current search stays pinned
            // above less-used matches, rather than pure fuzzy score
            // deciding order on its own.
            if (b.usage !== a.usage)
                return b.usage - a.usage;
            if (b.score !== a.score)
                return b.score - a.score;
            return a.entry.name.localeCompare(b.entry.name);
        });

        var result = [];
        for (var j = 0; j < scored.length; j++)
            result.push(scored[j].entry);

        filteredApps = result;
    }

    function launchApp(entry) {
        if (!entry)
            return;
        AppUsage.recordUsage(entry.id);
        entry.execute();
        LauncherController.close();
    }

    onIsOpenChanged: {
        if (isOpen) {
            searchField.text = "";
            rebuildList();
            // Qt.callLater ensures this runs after the width/height bindings
            // and visibility have actually taken effect this frame - trying
            // to forceActiveFocus() in the same tick the item becomes
            // visible can silently no-op on some platforms.
            Qt.callLater(function () { searchField.forceActiveFocus(); });
        }
    }

    Connections {
        target: searchField
        function onTextChanged() { launcher.rebuildList(); }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { launcher.rebuildList(); }
    }

    // -------------------------------------------------------------------------
    // 1. Soft Feathered Glow / Border (Behind solid rect)
    // -------------------------------------------------------------------------
    Rectangle {
        id: apronSource
        anchors.fill: panelBackground
        anchors.margins: -12 // Expands 16px OUTWARD beyond the solid rect
        radius: panelBackground.radius + 12
        color: Theme.launcherBackgroundColor
        visible: false // Hidden because MultiEffect renders it
    }

    MultiEffect {
        anchors.fill: apronSource
        source: apronSource
        blurEnabled: true
        blur: 1.0          // Maximum blur softness
        blurMax: 32        // Pixel spread
        opacity: 1
    }

    // -------------------------------------------------------------------------
    // 2. Solid Inner Background & Content Container
    // -------------------------------------------------------------------------

    Rectangle {
        id: panelBackground
        anchors.fill: parent
        anchors.margins: Theme.innerEdgeFalloff + 10
        radius: Math.max(0, launcher.cornerRounding - Theme.innerEdgeFalloff)
        antialiasing: true
        color: Theme.launcherBackgroundColor

        Item {
            id: content
            width: panelBackground.width
            height: panelBackground.height
            anchors.centerIn: parent

            // Swallows clicks anywhere within the launcher's own bounds so they
            // don't fall through to shell.qml's full-screen click-outside-to-
            // close catcher underneath. Must be the FIRST child here so the
            // Column (and its TextField/ListView) are added after it and thus
            // painted on top / hit-tested first for their own specific clicks.
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                

                TextField {
                    id: searchField
                    width: parent.width
                    placeholderText: "Search apps..."
                    placeholderTextColor: Theme.textColorSoft
                    color: Theme.textColorAccent
                    font.pixelSize: 20
                    background: null

                    Keys.onEscapePressed: LauncherController.close()

                    // Down arrow navigation
                    Keys.onDownPressed: {
                        if (resultsList.count > 0) {
                            resultsList.currentIndex = Math.min(resultsList.count - 1, resultsList.currentIndex + 1);
                        }
                    }

                    // Up arrow navigation
                    Keys.onUpPressed: {
                        if (resultsList.count > 0) {
                            resultsList.currentIndex = Math.max(0, resultsList.currentIndex - 1);
                        }
                    }

                    // Enter / Return launches selected app
                    Keys.onReturnPressed: {
                        if (resultsList.currentIndex >= 0 && resultsList.currentIndex < launcher.filteredApps.length) {
                            launcher.launchApp(launcher.filteredApps[resultsList.currentIndex]);
                        } else if (launcher.filteredApps.length > 0) {
                            launcher.launchApp(launcher.filteredApps[0]);
                        }
                    }

                    // Vim navigation: Ctrl+N (Next / Down) and Ctrl+P (Prev / Up)
                    Keys.onPressed: function(event) {
                        if (event.modifiers & Qt.ControlModifier) {
                            if (event.key === Qt.Key_N) {
                                if (resultsList.count > 0) {
                                    resultsList.currentIndex = Math.min(resultsList.count - 1, resultsList.currentIndex + 1);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_P) {
                                if (resultsList.count > 0) {
                                    resultsList.currentIndex = Math.max(0, resultsList.currentIndex - 1);
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }

            Shape {
                id: divider
                width: parent.width
                height: 2

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"

                    // Horizontal gradient across the width of the line
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: divider.width; y2: 0

                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Theme.textColorSoft }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    // Draw a rectangle path that fills the shape's bounds
                    startX: 0; startY: 0
                    PathLine { x: divider.width; y: 0 }
                    PathLine { x: divider.width; y: 2 }
                    PathLine { x: 0; y: 2 }
                    PathLine { x: 0; y: 0 }
                }
            }

                ListView {
                    id: resultsList
                    width: parent.width
                    height: parent.height - searchField.height - 12
                    clip: true
                    model: launcher.filteredApps

                    // Reset selection to the first item whenever results refresh
                    onModelChanged: currentIndex = 0

                    // Keep the highlighted row scrolled into view as you navigate
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        width: resultsList.width
                        height: 48
                        radius: 8

                        // Highlight if hovered OR if currently selected via keyboard
                        readonly property bool isSelected: index === resultsList.currentIndex
                        color: (isSelected || rowMouse.containsMouse) ? "#33ffffff" : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 12

                            IconImage {
                                visible: Theme.launcherShowIcons
                                anchors.verticalCenter: parent.verticalCenter
                                implicitSize: 32
                                source: Quickshell.iconPath(delegateRoot.modelData.icon, "application-x-executable")
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: delegateRoot.modelData.name
                                    color: delegateRoot.isSelected ? Theme.textColorAccent : "white"
                                    font.pixelSize: 15
                                    font.bold: delegateRoot.isSelected
                                }

                                Text {
                                    text: delegateRoot.modelData.genericName || ""
                                    color: "#aaaaaa"
                                    font.pixelSize: 11
                                    visible: text.length > 0
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: resultsList.currentIndex = delegateRoot.index
                            onClicked: launcher.launchApp(delegateRoot.modelData)
                        }
                    }
                }
            }
        }
    }
}
