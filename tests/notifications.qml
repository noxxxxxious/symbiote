import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components"

ShellRoot {
    Window {
        id: window
        visible: true
        width: 1280
        height: 800
        property var fakeScreen: ({name: "test"})

        NotificationCenter {
            id: center
            targetScreen: window.fakeScreen
            screenWidth: window.width
            screenHeight: window.height
        }

        Tray {
            id: tray
            targetScreen: window.fakeScreen
            screenWidth: window.width
            screenHeight: window.height
        }

        NotificationToast {
            id: toast
            targetScreen: window.fakeScreen
            screenWidth: window.width
            screenHeight: window.height
        }

        // Load settings too: notification controls live there.
        Settings {
            id: settings
            targetScreen: window.fakeScreen
        }

        Timer {
            interval: 100
            running: true
            onTriggered: {
                try { testCase.check() }
                catch (error) { console.error(error.stack); Qt.quit(); return }
                console.log("PASS Notifications::check")
                Qt.quit()
            }
        }

        TestCase {
            id: testCase
            when: false

            function check() {
                Config.sAdapter.clock.position = "top-left"
                Config.sAdapter.tray.position = "top-right"
                Config.sAdapter.notifications.position = "bottom-right"
                compare(tray.itemCount, tray.systemItemCount)
                verify(!toast.shown)

                DockingController.move("notifications", "top-right")
                compare(Config.sAdapter.notifications.position, "top-right")
                compare(Config.sAdapter.tray.position, "bottom-right")

                DockingController.move("clock", "bottom-right")
                compare(Config.sAdapter.clock.position, "bottom-right")
                compare(Config.sAdapter.tray.position, "top-left")
                compare(new Set([
                    Config.sAdapter.clock.position,
                    Config.sAdapter.tray.position,
                    Config.sAdapter.notifications.position
                ]).size, 3, "Dock ownership remains unique")

                var invoked = ""
                var dismissed = false
                var actionable = {
                    actions: [
                        {identifier: "secondary", invoke: function() { invoked = "secondary" }},
                        {identifier: "default", invoke: function() { invoked = "default" }}
                    ],
                    tracked: true,
                    dismiss: function() { dismissed = true; this.tracked = false }
                }
                verify(NotificationController.activate(actionable))
                compare(invoked, "default", "Default action wins over list order")
                verify(dismissed, "Action removes notification from active list")
                verify(!NotificationController.activate({actions: []}), "No-action notification is not consumed")

                NotificationController.openOn(window.fakeScreen)
                wait(380)
                verify(center.isOpen)
                compare(center.height, 600)
                compare(center.x, 1280 - center.width)
                compare(center.cornerRadii.y, 0)
                compare(center.cornerRadii.z, 0)
                compare(center.extraTendrilSpecs().length, 6)
                compare(center.extraTendrilSpecs()[0].rootY, Theme.borderThickness)
                compare(center.extraTendrilSpecs()[1].rootY, 800 - Theme.borderThickness)

                Config.sAdapter.notifications.centerExtraTendrils = false
                verify(!center.tendrilExtraConnections)
                Config.sAdapter.notifications.centerExtraTendrils = true

                Config.sAdapter.notifications.toastHorizontalOffset = 30
                Config.sAdapter.notifications.toastVerticalOffset = 20
                compare(toast.restingX, 30 + Theme.borderThickness + toast.margin)
                Config.sAdapter.notifications.toastHorizontalOffset = 0
                Config.sAdapter.notifications.toastVerticalOffset = 0

                NotificationController.close()
                wait(380)
                verify(!center.visuallyOpen)
            }
        }
    }
}
