import QtQuick
import QtQuick.Controls
import "."

Slider {
    id: root
    implicitHeight: 30
    hoverEnabled: true

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 7
        radius: 3.5
        color: "#181926"
        border.color: root.hovered || root.pressed ? Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, 0.6) : "#313244"
        border.width: 1

        Rectangle {
            x: 1
            y: 1
            width: Math.max(0, (parent.width - 2) * root.visualPosition)
            height: parent.height - 2
            radius: 2.5
            color: Theme.textColorAccent
            opacity: root.pressed ? 1.0 : 0.82
            Behavior on width { NumberAnimation { duration: 55 } }
        }
    }

    handle: Rectangle {
        id: sliderHandle
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        implicitWidth: handleHover.hovered || root.pressed ? 19 : 16
        implicitHeight: implicitWidth
        radius: width / 2
        color: Theme.borderColor
        border.color: Theme.textColorAccent
        border.width: 2

        HoverHandler { id: handleHover; blocking: false }

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 6
            radius: 3
            color: Theme.textColorAccent
        }

        Behavior on implicitWidth { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    }
}
