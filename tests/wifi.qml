import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import Quickshell.Networking
import "components"
import "components/dashboard" as Pages

ShellRoot {
    id: root
    QtObject {
        id: fakeBackend
        property var devices: QtObject { property var values: [adapter] }
        property bool wifiEnabled: true
        property bool wifiHardwareEnabled: true
        property int connectivity: NetworkConnectivity.Full
    }
    QtObject {
        id: adapter
        property string name: "test-wlan"
        property int type: DeviceType.Wifi
        property bool scannerEnabled: false
        property var networks: QtObject { property var values: [] }
    }
    Component {
        id: networkFactory
        QtObject {
            property string name: "Test network"
            property bool connected: false
            property bool known: false
            property int security: WifiSecurityType.Wpa2Psk
            property real signalStrength: 0.7
            property int state: ConnectionState.Disconnected
            property bool stateChanging: false
            property int connectCalls: 0
            property int passwordCalls: 0
            property int disconnectCalls: 0
            property string receivedPassword: ""
            signal connectionFailed(int reason)
            function connect() { connectCalls++; stateChanging = true; state = ConnectionState.Connecting }
            function connectWithPsk(password) { receivedPassword = password; passwordCalls++; stateChanging = true; state = ConnectionState.Connecting }
            function disconnect() { disconnectCalls++; connected = false; state = ConnectionState.Disconnected }
        }
    }
    Window {
        visible: true
        width: 650; height: 550
        Loader {
            id: pageLoader
            active: false
            anchors.fill: parent
            sourceComponent: Pages.WifiTab {}
        }
    }
    Component.onCompleted: {
        WifiController.backend = fakeBackend
        pageLoader.active = true
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            try { checks.check() }
            catch (error) { console.error(error.stack); Qt.quit(); return }
            console.log("PASS Wifi::check")
            Qt.quit()
        }
    }
    TestCase {
        id: checks
        when: false
        function button(item, label) {
            if (item.text === label && typeof item.clicked === "function") return item
            for (let child of item.children || []) {
                const found = button(child, label)
                if (found) return found
            }
            return null
        }
        function check() {
            const secure = networkFactory.createObject(root, {name: "Secure Wi-Fi"})
            const open = networkFactory.createObject(root, {name: "Open Wi-Fi", security: WifiSecurityType.Open, signalStrength: 0.9})
            const saved = networkFactory.createObject(root, {name: "Saved Wi-Fi", known: true, signalStrength: 0.3})
            adapter.networks.values = [secure, open, saved]
            wait(30)
            compare(WifiController.networks[0], saved, "Saved networks sort first")
            verify(adapter.scannerEnabled)
            WifiController.stopScan()
            verify(!adapter.scannerEnabled)
            WifiController.scanTimer.interval = 20
            WifiController.startScan()
            wait(50)
            verify(!adapter.scannerEnabled, "Scanning stops on timeout")
            WifiController.scanTimer.interval = 30000

            WifiController.connectNetwork(saved)
            compare(saved.connectCalls, 1, "Saved connections use saved credentials first")
            compare(WifiController.promptNetwork, null)
            saved.stateChanging = false
            saved.connectionFailed(ConnectionFailReason.NoSecrets)
            compare(WifiController.promptNetwork, saved, "Missing saved password prompts for retry")
            verify(!WifiController.busy)
            WifiController.cancelPrompt()

            WifiController.connectNetwork(secure)
            compare(WifiController.promptNetwork, secure)
            verify(!WifiController.submitPassword("short"))
            compare(secure.passwordCalls, 0)
            const password = findChild(pageLoader.item, "wifiPassword")
            verify(password !== null)
            compare(password.echoMode, TextInput.Password)
            password.text = "test-password"
            wait(20)
            const submit = button(pageLoader.item, "Connect with password")
            verify(submit && submit.enabled)
            submit.clicked()
            compare(secure.passwordCalls, 1)
            compare(secure.receivedPassword, "test-password")
            compare(password.text, "", "Password cleared after submission")
            verify(WifiController.busy)
            secure.stateChanging = false
            secure.connected = true
            secure.state = ConnectionState.Connected
            wait(20)
            verify(!WifiController.busy)
            compare(WifiController.networks[0], secure, "Connected network sorts first")
            WifiController.disconnectNetwork(secure)
            compare(secure.disconnectCalls, 1)

            WifiController.connectNetwork(open)
            compare(open.connectCalls, 1)
            compare(WifiController.promptNetwork, null)
            open.stateChanging = false
            open.connectionFailed(ConnectionFailReason.WifiAuthTimeout)
            verify(WifiController.message.includes("failed"))
            verify(!WifiController.busy)

            secure.security = WifiSecurityType.Wpa2Eap
            WifiController.connectNetwork(secure)
            compare(WifiController.promptNetwork, null)
            verify(WifiController.message.includes("authentication"))
            secure.security = WifiSecurityType.Sae
            WifiController.connectNetwork(secure)
            verify(WifiController.submitPassword("a"), "SAE passwords can be shorter than WPA2 passwords")
            secure.stateChanging = false
            secure.connectionFailed(ConnectionFailReason.NoSecrets)
            compare(WifiController.promptNetwork, secure)
            adapter.networks.values = [open, saved]
            wait(20)
            compare(WifiController.promptNetwork, null, "Removed networks dismiss the password prompt")

            WifiController.startScan()
            WifiController.togglePower()
            verify(!fakeBackend.wifiEnabled)
            verify(!adapter.scannerEnabled)
            WifiController.togglePower()
            verify(fakeBackend.wifiEnabled)
            fakeBackend.wifiHardwareEnabled = false
            WifiController.startScan()
            verify(!adapter.scannerEnabled)
            fakeBackend.wifiHardwareEnabled = true
            fakeBackend.connectivity = NetworkConnectivity.Portal
            verify(WifiController.connectivityMessage.includes("sign-in"))
            WifiController.startScan()
            pageLoader.active = false
            wait(20)
            verify(!adapter.scannerEnabled, "Destroying the tab stops scanning")
            fakeBackend.devices.values = []
            compare(WifiController.adapter, null)
            compare(WifiController.networks.length, 0)
        }
    }
}
