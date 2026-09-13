// components/HyprState.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
    id: root

    // Cached map: monitor name -> boolean isFullscreen
    property var fullscreenByMonitor: ({})

    function refresh() {
        const result = {};
        for (const mon of Hyprland.monitors.values) {
            result[mon.name] = mon.activeWorkspace?.hasFullscreen ?? false;
        }
        fullscreenByMonitor = result;
    }

    Component.onCompleted: refresh()

    // Listen to Hyprland workspace and window events
    property Connections hyprlandConnections: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "fullscreen" ||
                event.name === "activewindow" ||
                event.name === "activewindowv2" ||
                event.name === "workspace" ||
                event.name === "workspacev2" ||
                event.name === "moveworkspace" ||
                event.name === "moveworkspacev2") {
                root.refresh();
            }
        }
    }

    function isFullscreen(screen) {
        if (!screen) return false;
        return root.fullscreenByMonitor[screen.name] ?? false;
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        if (!name) return null;
        return Quickshell.screens.find(s => s.name === name) ?? null;
    }
}
