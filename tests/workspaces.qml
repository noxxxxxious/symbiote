import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "components"
import "components/WorkspaceLogic.js" as Logic

ShellRoot {
    Window {
        visible: true
        width: 1280; height: 800
        WorkspaceIndicator {
            id: indicator
            anchors.fill: parent
            targetScreen: ({name: "test"})
            sharedHotZoneHovered: edge === "bottom" && trigger.containsMouse
            monitor: ({activeWorkspace: {id: 3}})
            nativeWorkspaces: [{id: 3, name: "3"}, {id: -1337, name: "coding"}]
        }
        PowerTrigger {
            id: trigger
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            z: 31
            hoverEnabled: true
            onTriggered: indicator.suppressed = true
        }
        Timer {
            interval: 100; running: true
            onTriggered: {
                try { testCase.check() }
                catch (error) { console.error(error.stack); Qt.quit(); return }
                console.log("PASS Workspaces::check")
                Qt.quit()
            }
        }
        TestCase {
            id: testCase
            when: false
            function check() {
                compare(Logic.entries(8, 5, []).map(function(e) { return e.id }), [6,7,8,9,10])
                compare(Logic.entries(-1337, 5, [{id:-1337,name:"coding"}])[0].name, "coding")
                compare(Logic.command(-1337, "coding", false), "workspace name:coding")
                compare(Logic.command(3, "coding", true), "vdesk 3")
                compare(indicator.currentId, 3)
                compare(indicator.activeIndex, 2)
                var edges = ["top", "right", "bottom", "left"]
                for (var i = 0; i < edges.length; ++i) {
                    Config.sAdapter.workspaces.edge = edges[i]
                    indicator.summon()
                    wait(250)
                    verify(indicator.hitSurface.x >= 0 && indicator.hitSurface.y >= 0)
                    verify(indicator.hitSurface.x + indicator.hitSurface.width <= 1280)
                    verify(indicator.hitSurface.y + indicator.hitSurface.height <= 800)
                    compare(indicator.vertical, i === 1 || i === 3)
                }
                Config.sAdapter.workspaces.count = 1
                compare(indicator.entries.length, 1)
                compare(indicator.activeIndex, 0)
                Config.sAdapter.workspaces.count = 5
                Config.sAdapter.workspaces.vdesk = true
                wait(200)
                compare(WorkspaceController.activeVdesk, 2)
                compare(indicator.currentId, 2)
                // Native workspace changes must not alter the active vdesk.
                indicator.monitor = {activeWorkspace: {id: 99}}
                compare(indicator.currentId, 2)
                WorkspaceController.handleEvent("vdesk", "4")
                compare(indicator.currentId, 4)
                // An in-flight response from before the event must not revert it.
                WorkspaceController.acceptState('[{"id":2,"focused":true,"name":"work"}]')
                compare(indicator.currentId, 4)
                WorkspaceController.acceptState('unknown request')
                verify(WorkspaceController.vdeskError.length > 0)
                compare(WorkspaceController.activeVdesk, 0)
                Config.sAdapter.workspaces.vdesk = false
                Config.sAdapter.workspaces.edge = "bottom"
                mouseMove(trigger, 150, 4)
                wait(1100)
                verify(indicator.shown, "Shared power hot zone keeps the indicator summoned")
                mousePress(trigger, 150, 4)
                mouseMove(trigger, 150, -90, 30)
                mouseRelease(trigger, 150, -90)
                verify(indicator.suppressed, "Power drag wins over bottom indicator")
                verify(!indicator.enabled, "Suppressed indicator releases its input regions")
                indicator.suppressed = false
                mouseMove(indicator, 20, 300)
                wait(1200)
                verify(!indicator.shown, "Indicator hides after pointer leaves")
                wait(250)
                Config.sAdapter.workspaces.edge = "top"
                Config.sAdapter.workspaces.showOnChange = true
                Config.sAdapter.workspaces.revealDuration = 400
                Config.sAdapter.workspaces.duration = 1000
                var oldLiquid = indicator.liquidPosition
                indicator.monitor = {activeWorkspace: {id: 100}}
                wait(80)
                verify(indicator.shown && !indicator.fullyShown, "Change begins slide-in")
                verify(!indicator.dwelling, "Dwell excludes entrance animation")
                compare(indicator.liquidPosition, oldLiquid, "Liquid waits for arrival")
                wait(180)
                verify(indicator.fullyShown && indicator.dwelling)
                wait(200)
                verify(indicator.shown, "Full visible time starts after arrival")
                verify(indicator.liquidPosition < indicator.activeIndex, "Liquid duration is independent")
                wait(200)
                verify(!indicator.shown, "Dwell expiry starts slide-out without waiting for liquid")
                verify(indicator.reveal > 0, "Exit animation follows dwell")
                wait(250)
                compare(indicator.reveal, 0)
                indicator.monitor = {activeWorkspace: {id: 101}}
                wait(300)
                indicator.monitor = {activeWorkspace: {id: 102}}
                wait(300)
                verify(indicator.shown, "Another change restarts the full visible time")
                wait(400)
                verify(!indicator.shown)
                Config.sAdapter.workspaces.showOnChange = false
                indicator.monitor = {activeWorkspace: {id: 103}}
                wait(250)
                verify(!indicator.shown, "Automatic reveal can be disabled")
            }
        }
    }
}
