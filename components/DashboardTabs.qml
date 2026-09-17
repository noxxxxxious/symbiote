// components/DashboardTabs.qml
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "."

Item {
    id: root

    property int currentIndex: 0
    signal tabRequested(int index)

    readonly property var tabs: [
        "INFO",
        "SOUND",
        "WI-FI",
        "VPN",
        "BLUETOOTH",
        "MEDIA"
    ]

    implicitHeight: 42

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: root.tabs

            delegate: Item {
                id: tab
                required property int index
                required property string modelData

                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property bool selected: index === root.currentIndex

                Rectangle {
                    id: tabButton
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"

                    AccentHighlight {
                        anchors.fill: parent
                        hovered: mouse.containsMouse
                        selected: tab.selected
                        selectedOpacity: 0.10
                        radius: tabButton.radius

                        // Dashboard tabs use the Settings highlight language, but the
                        // signature edge lives on TOP instead of on the left.
                        edgeOpacity: 0
                    }

                    Rectangle {
                        visible: mouse.containsMouse || tab.selected
                        anchors.top: parent.top
                        anchors.topMargin: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(0, parent.width - 10)
                        height: 3
                        radius: 2
                        color: Theme.textColorAccent
                        opacity: mouse.containsMouse ? 1.0 : (tab.selected ? 0.45 : 0.0)

                        Behavior on opacity { NumberAnimation { duration: 80 } }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: tab.modelData
                    color: tab.selected ? Theme.textColorAccent : Theme.textColor
                    font.pixelSize: 12
                    font.bold: tab.selected
                    font.letterSpacing: 0.8
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabRequested(tab.index)
                }
            }
        }
    }
}
