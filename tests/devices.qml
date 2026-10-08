import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components"
import "components/dashboard" as Pages

ShellRoot {
    Window {
        id: window
        visible: true
        width: 900; height: 700
        QtObject { id: audio; property real volume: 0.5; property bool muted: false }
        QtObject { id: output; property var audio: audio; property bool ready: true; property string description: "Test speaker" }
        QtObject { id: input; property var audio: audio; property bool ready: true; property string description: "Test microphone" }
        QtObject {
            id: fakeAudio
            property var outputs: [output]
            property var inputs: [input]
            property var sink: output
            property var source: input
            property var selection: null
            property bool selectedOutput: false
            function select(node, isOutput) { selection = node; selectedOutput = isOutput }
        }
        QtObject { id: adapter; property bool enabled: true; property int state: 1 }
        QtObject {
            id: device
            property string name: "Test headphones"
            property string address: "00:11:22:33:44:55"
            property bool paired: false
            property bool connected: false
            property bool pairing: false
            property bool trusted: false
            property bool blocked: false
            property bool batteryAvailable: true
            property real battery: 0.75
            property int state: 0
            property bool forgotten: false
            function forget() { forgotten = true }
        }
        QtObject {
            id: fakeBluetooth
            property var adapter: adapter
            property var devices: [device]
            property var scanAdapter: null
            property bool pairing: false
            property string promptType: ""
            property string promptMessage: ""
            property string message: ""
            property bool needsInput: false
            property var pairingDevice: null
            function stopScan() { scanAdapter = null }
            function toggleScan() { scanAdapter = scanAdapter ? null : adapter }
            function pair(target) { pairingDevice = target; pairing = true }
            function cancelPair() { pairing = false }
            function respond(accept, value) { promptType = "" }
        }
        Pages.SoundTab { id: sound; width: 600; height: 300; controller: fakeAudio }
        Pages.BluetoothTab { id: bluetooth; y: 310; width: 600; height: 350; controller: fakeBluetooth }
        AudioOsd { id: osd; controller: fakeAudio }
        Timer {
            interval: 400
            running: true
            onTriggered: {
                try { checks.check() }
                catch (error) { console.error(error.stack); Qt.quit(); return }
                console.log("PASS Devices::check")
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
            function click(label, item) {
                const target = button(item, label)
                verify(target !== null, "Missing button: " + label)
                verify(target.enabled, "Disabled button: " + label)
                target.clicked()
                wait(10)
            }
            function check() {
                verify(sound.contentWidth > 0)
                verify(bluetooth.contentWidth > 0)
                verify(!BluetoothController.pairing)
                BluetoothController.stopScan()
                compare(BluetoothController.scanAdapter, null)
                verify(!osd.shown)
                output.ready = false
                audio.volume = 0.45
                output.ready = true
                wait(10)
                verify(!osd.shown, "Initial device synchronization does not show the OSD")
                click("●  Test speaker", sound)
                compare(fakeAudio.selection, output)
                verify(fakeAudio.selectedOutput)
                click("●  Test microphone", sound)
                compare(fakeAudio.selection, input)
                verify(!fakeAudio.selectedOutput)
                click("Mute", sound)
                verify(audio.muted)
                verify(osd.shown, "Mute changes show the OSD")
                osd.shown = false
                audio.volume = 0.6
                wait(10)
                verify(osd.shown, "External volume changes show the OSD")
                wait(1700)
                verify(!osd.shown, "OSD hides after timeout")
                click("Scan (30s)", bluetooth)
                compare(fakeBluetooth.scanAdapter, adapter)
                click("Stop scan", bluetooth)
                compare(fakeBluetooth.scanAdapter, null)
                click("Pair & connect", bluetooth)
                compare(fakeBluetooth.pairingDevice, device)
                click("Cancel pairing", bluetooth)
                verify(!fakeBluetooth.pairing)
                device.paired = true
                wait(10)
                click("Connect", bluetooth)
                verify(device.connected)
                click("Disconnect", bluetooth)
                verify(!device.connected)
                click("Trust", bluetooth)
                verify(device.trusted)
                click("Forget", bluetooth)
                verify(device.forgotten)
                // Unplugged and missing-device states must stay usable.
                fakeAudio.sink = null
                fakeAudio.source = null
                fakeAudio.outputs = []
                fakeAudio.inputs = []
                fakeBluetooth.adapter = null
                fakeBluetooth.devices = []
                wait(10)
                verify(!BluetoothController.pairing)
            }
        }
    }
}
