pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

ScrollView {
    id: root
    property var controller: VpnController
    clip: true
    contentWidth: availableWidth
    Component.onCompleted: controller.refresh()
    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "VPN"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 16 }
            Item { Layout.fillWidth: true }
            ControlButton { text: "Refresh"; enabled: !root.controller.busy; onClicked: root.controller.refresh() }
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.controller.profiles.length ? "OpenVPN profiles from ~/.vpn" : "Put your OpenVPN .ovpn files in ~/.vpn, then refresh."
            color: Theme.textColorSoft
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text.length > 0
            text: root.controller.error || root.controller.message
            color: root.controller.error ? Theme.textColorAccent : Theme.textColorSoft
        }
        Repeater {
            model: root.controller.active
            delegate: RowLayout {
                id: activeRow
                required property var modelData
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: (activeRow.modelData.state === 2 ? "Connected: " : activeRow.modelData.state === 1 ? "Connecting: " : "Disconnecting: ") + activeRow.modelData.name
                    color: Theme.textColorAccent
                    elide: Text.ElideRight
                }
                ControlButton {
                    text: "Disconnect VPN"
                    enabled: !root.controller.busy && activeRow.modelData.state !== 3
                    onClicked: root.controller.disconnectVpn(activeRow.modelData.uuid)
                }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: root.controller.profiles
                delegate: Rectangle {
                    id: profileCard
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    implicitHeight: contents.implicitHeight + 20
                    radius: 8
                    color: Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, modelData.state === 2 ? 0.12 : 0.04)
                    ColumnLayout {
                        id: contents
                        anchors.fill: parent
                        anchors.margins: 10
                        Text {
                            Layout.fillWidth: true
                            text: profileCard.modelData.name
                            elide: Text.ElideRight
                            color: Theme.textColor
                            font.bold: true
                        }
                        ControlButton {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: profileCard.modelData.state === 2 ? "Disconnect VPN" : "Connect"
                            enabled: !root.controller.busy && (profileCard.modelData.state === 2 || (root.controller.available && root.controller.active.length === 0))
                            onClicked: {
                                if (profileCard.modelData.state === 2) root.controller.disconnectVpn(profileCard.modelData.uuid)
                                else root.controller.connectProfile(profileCard.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
