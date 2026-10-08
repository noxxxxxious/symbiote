import QtQuick
import QtQuick.Controls
import ".."

Button {
    id: root
    property bool selected: false
    implicitHeight: 34
    implicitWidth: label.implicitWidth + 24
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        id: label
        text: root.text
        color: root.selected ? Theme.textColorAccent : Theme.textColor
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 8
        color: Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b,
                       root.down ? 0.24 : root.hovered || root.selected ? 0.14 : 0.05)
        border.color: root.selected ? Theme.textColorAccent : "#454550"
    }
}
