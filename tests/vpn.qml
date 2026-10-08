import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components"
import "components/dashboard" as Pages

ShellRoot {
    QtObject {
        id: fakeVpn
        property var profiles: [{name: "Test profile", path: "/test/profile.ovpn", uuid: "test-uuid", state: 0}]
        property var active: []
        property bool available: true
        readonly property bool connected: active.some(connection => connection.state === 2)
        property bool busy: false
        property string error: ""
        property string message: ""
        property int refreshCalls: 0
        property string connectedPath: ""
        property string disconnectedUuid: ""
        function refresh() { refreshCalls++ }
        function connectProfile(profile) { connectedPath = profile.path }
        function disconnectVpn(uuid) { disconnectedUuid = uuid }
    }
    Window {
        id: window
        visible: true
        width: 1000; height: 700
        Pages.VpnTab { id: page; width: 650; height: 350; controller: fakeVpn }
        Tray {
            id: tray
            targetScreen: ({name: "test"})
            screenWidth: window.width
            screenHeight: window.height
            vpnController: fakeVpn
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            try { checks.check() }
            catch (error) { console.error(error.stack); Qt.quit(); return }
            console.log("PASS Vpn::check")
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
            verify(fakeVpn.refreshCalls > 0)
            verify(!tray.hasVpnIndicator)
            const originalCount = tray.itemCount
            let connectButton = button(page, "Connect")
            verify(connectButton && connectButton.enabled)
            connectButton.clicked()
            compare(fakeVpn.connectedPath, "/test/profile.ovpn")
            fakeVpn.busy = true
            verify(!connectButton.enabled)
            fakeVpn.busy = false
            fakeVpn.active = [{uuid: "test-uuid", name: "Test profile", state: 1}]
            wait(20)
            verify(!tray.hasVpnIndicator, "Connecting does not show the connected lock")
            verify(!connectButton.enabled, "Cannot start another VPN while one is active")
            fakeVpn.active = [{uuid: "test-uuid", name: "Test profile", state: 2}]
            fakeVpn.profiles = [{name: "Test profile", path: "/test/profile.ovpn", uuid: "test-uuid", state: 2}]
            wait(30)
            verify(tray.hasVpnIndicator)
            compare(tray.itemCount, originalCount + 1)
            const icon = findChild(tray, "vpnTrayIcon")
            verify(icon !== null)
            tray.summon()
            wait(250)
            mouseClick(icon)
            verify(tray.vpnPopupVisible)
            verify(tray.popupVisible)
            compare(tray.vpnMenuItems.length, 1)
            compare(tray.vpnMenuItems[0].text, "Disconnect VPN")
            tray.vpnMenuItems[0].triggered()
            compare(fakeVpn.disconnectedUuid, "test-uuid")
            fakeVpn.disconnectedUuid = ""
            const disconnectButton = button(page, "Disconnect VPN")
            verify(disconnectButton && disconnectButton.enabled)
            disconnectButton.clicked()
            compare(fakeVpn.disconnectedUuid, "test-uuid")
            fakeVpn.active = []
            wait(30)
            verify(!tray.hasVpnIndicator)
            verify(!tray.vpnPopupVisible)
            verify(!tray.popupVisible, "Disconnecting closes the VPN menu")
            compare(tray.itemCount, originalCount)
            fakeVpn.profiles = []
            fakeVpn.available = false
            fakeVpn.error = "Plugin unavailable"
            wait(20)
            verify(!tray.hasVpnIndicator)
        }
    }
}
