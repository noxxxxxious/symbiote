import QtQuick
import "."

MouseArea {
    id: root
    property real availableWidth: 300
    property bool available: true
    property string debugName: ""
    property int debugWorkspaceId: 0
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
    // Trigger grows upward after press. MouseArea-local y therefore shifts by
    // ~its growth amount; use parent coordinates so pull measures real cursor
    // movement, independent of the resized hit area.
    function stablePointerY(mouse) {
        return mapToItem(parent, mouse.x, mouse.y).y
    }
    function trace(stage, mouse) {
        var localY = mouse ? mouse.y : "-"
        var stableY = mouse ? stablePointerY(mouse) : "-"
        console.log("[PowerTrigger]", stage,
                    "monitor=", debugName || "<unnamed>",
                    "workspace=", debugWorkspaceId,
                    "available=", available,
                    "enabled=", enabled,
                    "visible=", visible,
                    "contains=", containsMouse,
                    "pressed=", pressed,
                    "dragging=", dragging,
                    "fired=", fired,
                    "geom=", x, y, width, height,
                    "localY=", localY,
                    "stableY=", stableY,
                    "startY=", startY,
                    "pull=", pull)
    }
    Component.onCompleted: trace("ready")
    onAvailableChanged: trace("available-changed")
    onDebugWorkspaceIdChanged: trace("workspace-changed")
    onDraggingChanged: trace("dragging-changed")
    onHeightChanged: trace("height-changed")
    onContainsMouseChanged: trace("contains-mouse-changed")
    onPressedChanged: trace("pressed-changed")
    onPressed: function(mouse) {
        trace("press", mouse)
        if (!available) {
            trace("press-rejected-unavailable", mouse)
            mouse.accepted = false
            return
        }
        startY = stablePointerY(mouse); pull = 0; fired = false
        dragging = true
        trace("drag-start", mouse)
    }
    onPositionChanged: function(mouse) {
        if (!pressed || fired) {
            trace("motion-ignored", mouse)
            return
        }
        pull = Math.max(0, startY - stablePointerY(mouse))
        trace("drag-motion", mouse)
        if (pull >= 80) {
            fired = true
            trace("threshold-reached", mouse)
            triggered()
        }
    }
    onReleased: function(mouse) {
        trace("release", mouse)
        dragging = false; pull = 0; fired = false
    }
    onCanceled: function(mouse) {
        trace("cancel", mouse)
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
