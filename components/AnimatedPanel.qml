import QtQuick
import "."

// Purely a geometry driver for now - no visible fill of its own. Its rect is
// fed into border.frag as a second SDF that gets unioned with the ring, so
// visually it shows up as a solid "blob" carved from the same shader that
// draws the border. Real widget content will live inside this Item later.
Item {
    id: panel

    width: 220
    height: 140

    property real margin: 10
    property real topOffset: 20

    property real leftX: Theme.borderThickness + margin
    property real rightX: parent.width - Theme.borderThickness - margin - width

    x: leftX
    y: Theme.borderThickness + topOffset

    // Tendril profile for this panel
    property real tendrilsPer100px: 2     // horizontal density
    property int tendrilMaxActive: 12        // max simultaneously attached
    property int tendrilSlotCapacityOverride: 20
    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(40, 80)

    property int tendrilMaxTop: 8
    property int tendrilMaxRight: 4
    property int tendrilMaxBottom: 8
    property int tendrilMaxLeft: 4
    property int tendrilMaxCorners: 2

    SequentialAnimation on x {
        loops: Animation.Infinite
        running: true

        NumberAnimation {
            from: panel.leftX
            to: panel.rightX
            duration: 5000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            from: panel.rightX
            to: panel.leftX
            duration: 5000
            easing.type: Easing.InOutSine
        }
    }
}

