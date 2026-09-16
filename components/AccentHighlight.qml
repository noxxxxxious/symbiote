import QtQuick
import "."

Rectangle {
    id: root

    property bool hovered: false
    property bool selected: false
    property real hoverOpacity: 0.18
    property real selectedOpacity: 0.07
    property real borderOpacity: 0.48
    property real edgeOpacity: hovered ? 1.0 : (selected ? 0.45 : 0.0)
    property real edgeInset: 5

    function accent(alpha) {
        return Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, alpha)
    }

    color: hovered ? accent(hoverOpacity) : (selected ? accent(selectedOpacity) : "transparent")
    border.color: hovered ? accent(borderOpacity) : "transparent"
    border.width: 1
    radius: 5

    Behavior on color { ColorAnimation { duration: 80 } }

    Rectangle {
        visible: root.hovered || root.selected
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Math.max(0, parent.height - root.edgeInset * 2)
        radius: 2
        color: Theme.textColorAccent
        opacity: root.edgeOpacity
        Behavior on opacity { NumberAnimation { duration: 80 } }
    }
}
