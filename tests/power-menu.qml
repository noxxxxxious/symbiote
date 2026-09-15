// Run through run-power-menu.sh; it uses an isolated config and never invokes
// the executable power actions.
import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components"

ShellRoot {
    Window {
        property int slotUpdates: 0
        id: window
        visible: true
        width: 1280; height: 800
        PowerMenu { id: menu; anchors.fill: parent; targetScreen: ({name: "test"}) }
        Connections { target: menu; function onSlotsChanged() { window.slotUpdates++ } }
        PowerTrigger {
            id: trigger
            available: !menu.visuallyOpen
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            onTriggered: PowerMenuController.openOn(menu.targetScreen)
        }
        Timer {
            interval: 100; running: true
            onTriggered: {
                try { testCase.test_gesture_and_menu() }
                catch (error) { console.error(error.stack); Qt.quit(); return }
                console.log("PASS PowerMenu::test_gesture_and_menu")
                Qt.quit()
            }
        }
        TestCase {
            id: testCase
            name: "PowerMenu"
            when: false
            function test_gesture_and_menu() {
                var idleUpdates = window.slotUpdates
                wait(200)
                compare(window.slotUpdates, idleUpdates, "Closed menu stays idle")
                Config.sAdapter.powerMenu.tendrilsPerSide = 1
                mouseClick(trigger, 150, 4)
                verify(!menu.isOpen, "A click must not open the menu")
                mousePress(trigger, 150, 4)
                mouseMove(trigger, 150, -36, 30)
                mouseRelease(trigger, 150, -36)
                verify(!menu.isOpen, "A short drag must not open the menu")
                mousePress(trigger, 150, 4)
                mouseMove(trigger, 150, -90, 30)
                mouseRelease(trigger, 150, -90)
                verify(menu.isOpen, "An upward drag opens the menu")
                verify(!trigger.pressed, "Opening drag releases its grab")
                verify(trigger.enabled, "Trigger remains in the input mask while open")
                verify(!trigger.available, "Trigger rejects gestures while the menu is open")
                wait(1600)
                for (var i = 0; i < 5; ++i) {
                    verify(menu.cards[i].growth > 0.99)
                    var specs = menu.cards[i].extraTendrilSpecs()
                    compare(specs.length, 4)
                    compare(specs[0].rootY, Theme.borderThickness)
                    compare(specs[1].rootX, 1280 - Theme.borderThickness)
                    compare(specs[2].rootY, 800 - Theme.borderThickness)
                    compare(specs[3].rootX, Theme.borderThickness)
                }
                compare(menu.slots.filter(function(s) { return s.isExtra && s.active }).length, 20)
                var sample = menu.slots.filter(function(s) { return s.isExtra && s.active })[0]
                var oldThickness = Config.sAdapter.powerMenu.rootThickness
                Config.sAdapter.powerMenu.rootThickness = oldThickness * 2
                var updated = menu.slots.filter(function(s) { return s.isExtra && s.active })[0]
                compare(updated.rootThick, sample.rootThick * 2, "Thickness changes apply live")
                wait(700)
                var settledUpdates = window.slotUpdates
                wait(200)
                compare(window.slotUpdates, settledUpdates, "Settled power fans stop ticking")
                compare(menu.commandForAction(0), ["systemctl", "poweroff"])
                compare(menu.commandForAction(1), [])
                compare(menu.commandForAction(2), ["systemctl", "suspend"])
                compare(menu.commandForAction(3), ["systemctl", "reboot"])
                menu.activate(1)
                verify(!menu.busy, "Lock remains unavailable")
                Config.sAdapter.powerMenu.tendrilsPerSide = 2
                wait(300)
                compare(menu.slots.filter(function(s) { return s.isExtra && s.active }).length, 40)
                menu.activate(4)
                verify(SettingsController.isOpenOn(menu.targetScreen), "Settings card opens Settings")
                verify(!menu.isOpen, "Settings replaces the power menu")
                SettingsController.close()
                PowerMenuController.openOn(menu.targetScreen)
                wait(600)
                keyClick(Qt.Key_Escape)
                verify(!menu.isOpen)
                wait(600)
                verify(!menu.visuallyOpen)
                PowerMenuController.openOn(menu.targetScreen)
                verify(!PowerMenuController.isOpenOn({name: "other"}), "Only the target screen opens")
                wait(40)
                PowerMenuController.close()
                wait(700)
                verify(!menu.visuallyOpen, "Closing cancels delayed reveals")
                for (var cycle = 0; cycle < 3; ++cycle) {
                    verify(trigger.enabled, "Trigger is re-enabled after closing")
                    mousePress(trigger, 150, 4)
                    mouseMove(trigger, 150, -90, 30)
                    mouseRelease(trigger, 150, -90)
                    verify(menu.isOpen, "Repeated drag reopens the same screen")
                    wait(600)
                    verify(menu.cards[4].growth > 0.9)
                    PowerMenuController.close()
                    wait(450)
                }
                wait(1200)
                var closedUpdates = window.slotUpdates
                wait(200)
                compare(window.slotUpdates, closedUpdates, "No updates after retraction completes")
            }

        }
    }
}
