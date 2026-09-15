pragma Singleton
import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import "."
import "WorkspaceLogic.js" as Logic

QtObject {
    id: root
    readonly property bool vdeskMode: Config.sAdapter.workspaces.vdesk
    property int activeVdesk: 0
    property var vdesks: []
    property string vdeskError: ""
    property int eventSerial: 0
    property int querySerial: 0
    function refresh() {
        if (vdeskMode && !query.running) {
            querySerial = eventSerial
            query.running = true
        }
    }
    function acceptState(text) {
        try {
            var state = Logic.parseVdesks(text)
            vdesks = state.desks
            if (querySerial === eventSerial) activeVdesk = state.active
            vdeskError = ""
        } catch (error) {
            activeVdesk = 0
            vdeskError = "Virtual desktops unavailable — check that the plugin is loaded."
        }
    }
    function handleEvent(name, data) {
        if (!vdeskMode) return
        if (name === "vdesk") {
            var id = Number(data.trim())
            if (Number.isInteger(id) && id > 0) {
                ++eventSerial
                activeVdesk = id
                vdeskError = ""
            }
        }
        if (name === "vdesk" || name === "configreloaded" || name.indexOf("monitor") === 0)
            refreshSoon.restart()
    }
    onVdeskModeChanged: {
        activeVdesk = 0
        vdesks = []
        vdeskError = ""
        refresh()
    }
    Component.onCompleted: refresh()
    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event) { root.handleEvent(event.name, event.data) }
    }
    property Timer refreshSoon: Timer { interval: 100; onTriggered: root.refresh() }
    // Recover after plugin reloads and missed events, only while vdesk mode is on.
    property Timer refreshTimer: Timer { interval: 3000; repeat: true; running: root.vdeskMode; onTriggered: root.refresh() }
    property Process query: Process {
        command: ["hyprctl", "-j", "printstate"]
        stdout: StdioCollector { onStreamFinished: if (root.vdeskMode) root.acceptState(text) }
    }
    function select(screen, entry, currentId) {
        if (!entry || entry.id === currentId) return
        var command = Logic.command(entry.id, entry.name, vdeskMode)
        if (!command || (vdeskMode && vdeskError)) return
        if (!vdeskMode && screen) Hyprland.dispatch("focusmonitor " + screen.name)
        Hyprland.dispatch(command)
    }
}
