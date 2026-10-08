pragma Singleton
import QtQuick
import Quickshell.Networking

QtObject {
    id: root
    // Allow isolated tests to provide a backend without touching the radio.
    property var backend: Networking
    readonly property var adapters: backend.devices.values.filter(device => device.type === DeviceType.Wifi)
    property var selectedAdapter: null
    readonly property var adapter: adapters.indexOf(selectedAdapter) !== -1 ? selectedAdapter : (adapters[0] || null)
    readonly property bool enabled: backend.wifiEnabled
    readonly property bool hardwareEnabled: backend.wifiHardwareEnabled
    readonly property var networks: adapter ? adapter.networks.values.slice().sort((a, b) => {
        if (a.connected !== b.connected) return a.connected ? -1 : 1
        if (a.known !== b.known) return a.known ? -1 : 1
        return b.signalStrength - a.signalStrength
    }) : []
    property var scanAdapter: null
    property var pendingNetwork: null
    property var promptNetwork: null
    property string message: ""
    readonly property bool busy: pendingNetwork !== null
    readonly property string connectivityMessage: backend.connectivity === NetworkConnectivity.Portal
        ? "This network needs a sign-in. Open your browser to complete it."
        : backend.connectivity === NetworkConnectivity.Limited ? "Connected with limited internet access." : ""

    function supportsPassword(network) {
        return network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae
    }
    function stopScan() {
        if (scanAdapter) scanAdapter.scannerEnabled = false
        scanAdapter = null
        scanTimer.stop()
    }
    function startScan() {
        if (!adapter || !enabled || !hardwareEnabled) return
        stopScan()
        scanAdapter = adapter
        scanAdapter.scannerEnabled = true
        scanTimer.restart()
    }
    function togglePower() {
        stopScan()
        cancelPrompt()
        backend.wifiEnabled = !enabled
    }
    function cancelPrompt() { promptNetwork = null }
    function connectNetwork(network) {
        if (busy || !network || !enabled || !hardwareEnabled || network.stateChanging) return
        cancelPrompt()
        message = ""
        if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            beginConnection(network)
            network.connect()
        } else if (supportsPassword(network)) {
            promptNetwork = network
        } else {
            message = "Configure this network's authentication in NetworkManager first, then connect here."
        }
    }
    function submitPassword(password) {
        const network = promptNetwork
        if (!network || busy || !enabled || !hardwareEnabled) return false
        const valid = network.security === WifiSecurityType.Sae
            ? password.length >= 1 && password.length <= 63
            : (password.length >= 8 && password.length <= 63) || /^[0-9a-fA-F]{64}$/.test(password)
        if (!valid) {
            message = network.security === WifiSecurityType.Sae ? "Enter a password of 1–63 characters."
                      : "Enter a password of 8–63 characters, or a 64-digit hexadecimal key."
            return false
        }
        beginConnection(network)
        promptNetwork = null
        network.connectWithPsk(password)
        return true
    }
    function beginConnection(network) {
        pendingNetwork = network
        message = "Connecting to " + network.name + "…"
        connectionTimer.restart()
    }
    function disconnectNetwork(network) {
        if (!network || network.stateChanging) return
        if (pendingNetwork === network) finishConnection()
        if (promptNetwork === network) cancelPrompt()
        message = "Disconnecting from " + network.name + "…"
        network.disconnect()
    }
    function finishConnection() {
        connectionTimer.stop()
        pendingNetwork = null
    }
    function connectionFailed(reason) {
        const network = pendingNetwork
        finishConnection()
        if (reason === ConnectionFailReason.NoSecrets && network && supportsPassword(network)) {
            promptNetwork = network
            message = "A password is needed, or the saved password was rejected. Try again."
        } else {
            message = "Connection failed: " + ConnectionFailReason.toString(reason) + "."
        }
    }
    function validateSelection() {
        if (promptNetwork && networks.indexOf(promptNetwork) === -1) {
            promptNetwork = null
            message = "The network is no longer available. Scan again."
        }
        if (pendingNetwork && networks.indexOf(pendingNetwork) === -1) {
            finishConnection()
            message = "The network is no longer available. Scan again."
        }
    }
    onNetworksChanged: validateSelection()
    onAdapterChanged: stopScan()
    onEnabledChanged: if (!enabled) { stopScan(); cancelPrompt(); finishConnection() }
    onHardwareEnabledChanged: if (!hardwareEnabled) { stopScan(); cancelPrompt(); finishConnection() }
    property Timer scanTimer: Timer { interval: 30000; onTriggered: root.stopScan() }
    property Timer connectionTimer: Timer {
        interval: 60000
        onTriggered: { root.pendingNetwork = null; root.message = "Connection timed out. Check the network and try again." }
    }
    property Connections pendingSignals: Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) { root.connectionFailed(reason) }
        function onConnectedChanged() {
            if (root.pendingNetwork && root.pendingNetwork.connected) {
                root.message = "Connected to " + root.pendingNetwork.name + "."
                root.finishConnection()
            }
        }
    }
}
