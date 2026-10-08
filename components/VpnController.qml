pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property var profiles: []
    property var active: []
    property bool available: false
    property string statusError: ""
    property string operationError: ""
    readonly property string error: operationError || statusError
    property string message: ""
    readonly property bool connected: active.some(connection => connection.state === 2)
    readonly property bool busy: actionProcess.running
    property bool pollingEnabled: true
    property string operation: ""
    function command(action, value) {
        const args = ["python3", Quickshell.shellPath("components/vpn-helper.py"), action]
        if (value) args.push(value)
        return args
    }
    function applySnapshot(result, fromAction) {
        if (result.profiles !== undefined) root.profiles = result.profiles
        if (result.active !== undefined) root.active = result.active
        else if (!fromAction && result.error) root.active = []
        if (result.available !== undefined) root.available = result.available
        if (fromAction) root.operationError = result.error || ""
        else root.statusError = result.error || ""
        if (result.message) root.message = result.message
    }
    function refresh() {
        if (!statusProcess.running && !busy) statusProcess.running = true
    }
    function connectProfile(profile) {
        if (busy || !available || active.length > 0) return
        operationError = ""
        statusProcess.running = false
        operation = "connect"
        message = "Connecting to " + profile.name + "…"
        actionProcess.command = command("connect", profile.path)
        actionProcess.running = true
    }
    function disconnectVpn(uuid) {
        if (busy) return
        operationError = ""
        statusProcess.running = false
        operation = "disconnect"
        message = "Disconnecting VPN…"
        actionProcess.command = command("disconnect", uuid)
        actionProcess.running = true
    }
    property Timer pollTimer: Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.pollingEnabled
        onTriggered: root.refresh()
    }
    property Process statusProcess: Process {
        command: root.command("list", "")
        stdout: StdioCollector {
            onStreamFinished: {
                try { if (!root.busy) root.applySnapshot(JSON.parse(text), false) }
                catch (error) { root.statusError = "Could not read VPN status." }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.statusError = "VPN helper failed. Check Python and NetworkManager."
        }
    }
    property Process actionProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.applySnapshot(JSON.parse(text), true) }
                catch (error) { root.operationError = "VPN operation failed. Check Python and NetworkManager." }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.operationError = "VPN helper failed. Check Python and NetworkManager."
        }
        onExited: root.refresh()
    }
}
