import QtQuick
import "."

MouseArea {
    id: root
    property real availableWidth: 300
    property bool available: true
    property string debugName: ""
    // Keep this MouseArea enabled for the entire lifetime of the shell. Removing
    // it from the input mask while the menu is open can leave the compositor's
    // region stale until the pointer leaves and re-enters the screen. The
    // `available` property gates the gesture below without changing the region.
    enabled: true
    property real startY: 0
    property real pull: 0
    property bool fired: false
    property bool dragging: false
    readonly property real restingHeight: Math.max(8, Theme.borderThickness)
    signal triggered()
    width: Math.min(300, availableWidth)
    // Once pressed, grow the input area upward so the compositor continues
    // delivering motion events throughout the drag. It contracts on release.
    height: dragging ? Math.max(96, restingHeight) : restingHeight
    preventStealing: true
    onAvailableChanged: console.log("[PowerTrigger]", debugName || "<unnamed>", "available:", available, "pressed:", pressed, "enabled:", enabled)
    onDraggingChanged: console.log("[PowerTrigger]", debugName || "<unnamed>", "drag capture:", dragging, "height:", height)
    onPressed: function(mouse) {
        console.log("[PowerTrigger]", debugName || "<unnamed>", "pressed y:", mouse.y, "available:", available, "height:", height, "menu grab:", mouse.source)
        if (!available) {
            console.log("[PowerTrigger]", debugName || "<unnamed>", "press rejected (unavailable)")
            mouse.accepted = false
            return
        }
        dragging = true
        startY = mouse.y; pull = 0; fired = false
    }
    onPositionChanged: function(mouse) {
        if (!pressed || fired) return
        pull = Math.max(0, startY - mouse.y)
        if (pull >= 80) {
            fired = true
            console.log("[PowerTrigger]", debugName || "<unnamed>", "threshold reached; pull:", pull)
            triggered()
        }
    }
    onReleased: {
        console.log("[PowerTrigger]", debugName || "<unnamed>", "released; pull:", pull, "fired:", fired)
        dragging = false; pull = 0; fired = false
    }
    onCanceled: {
        console.log("[PowerTrigger]", debugName || "<unnamed>", "canceled; pull:", pull, "fired:", fired)
        dragging = false; pull = 0; fired = false
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        width: root.pressed ? 120 : 56
        height: 3
        radius: 1.5
        color: Theme.textColorAccent
        opacity: root.pressed ? 0.9 : 0.35
    }
}
