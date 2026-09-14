// components/Wallpaper.qml
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "faishell-wallpaper"
    color: "black"

    Image {
        anchors.fill: parent
        source: Theme.wallpaperPath !== "" ? (Theme.wallpaperPath.startsWith("/") ? "file://" + Theme.wallpaperPath : Theme.wallpaperPath) : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        clip: true

        // Smooth fade when changing wallpapers
        Behavior on opacity {
            NumberAnimation { duration: 250 }
        }
    }
}
