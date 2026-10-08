pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

QtObject {
    id: root
    property var selectedAdapter: null
    readonly property var adapter: selectedAdapter && Bluetooth.adapters.values.indexOf(selectedAdapter) !== -1
                                   ? selectedAdapter : Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values : []
    property var scanAdapter: null
    property var pairingDevice: null
    property string message: ""
    property string promptType: ""
    property string promptMessage: ""
    readonly property bool pairing: pairProcess.running
    readonly property bool needsInput: promptType === "pin" || promptType === "passkey"

    function stopScan() {
        if (scanAdapter) scanAdapter.discovering = false
        scanAdapter = null
        scanTimer.stop()
    }
    function toggleScan() {
        if (!adapter || !adapter.enabled) return
        if (scanAdapter) { stopScan(); return }
        scanAdapter = adapter
        scanAdapter.discovering = true
        scanTimer.restart()
    }
    function pair(device) {
        if (pairing) return
        pairingDevice = device
        message = "Pairing with " + (device.name || device.address) + "…"
        promptType = ""
        pairProcess.command = ["python3", Quickshell.shellPath("components/bluetooth-pair.py"), device.dbusPath]
        pairProcess.running = true
    }
    function respond(accept, value) {
        pairProcess.write(JSON.stringify({accept: accept, value: value || ""}) + "\n")
        promptType = ""
    }
    function cancelPair() {
        if (pairingDevice && pairingDevice.pairing) pairingDevice.cancelPair()
        pairProcess.running = false
        pairingDevice = null
        promptType = ""
        message = "Pairing cancelled."
    }
    onAdapterChanged: stopScan()
    property Timer scanTimer: Timer { interval: 30000; onTriggered: root.stopScan() }
    property Process pairProcess: Process {
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data)
                    if (event.kind === "prompt") {
                        root.promptType = event.promptType
                        root.promptMessage = event.message
                    } else if (event.kind === "cancelled") {
                        root.promptType = ""
                    } else if (event.message) {
                        root.message = event.message
                    }
                } catch (error) { console.warn("[Bluetooth] Invalid agent response:", error) }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.message = "Pairing agent failed: " + text.trim()
        }
        onExited: code => {
            root.promptType = ""
            root.pairingDevice = null
            if (code !== 0 && !root.message.includes("requires")) root.message = "Pairing agent failed. " + root.message
        }
    }
}
