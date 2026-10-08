pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import ".."

ScrollView {
    id: root
    property var controller: WifiController
    clip: true
    contentWidth: availableWidth
    function submit() {
        if (controller.submitPassword(password.text)) password.clear()
    }
    onVisibleChanged: {
        if (visible) controller.startScan()
        else { controller.stopScan(); controller.cancelPrompt(); password.clear() }
    }
    Component.onCompleted: if (visible) controller.startScan()
    Component.onDestruction: { controller.stopScan(); controller.cancelPrompt() }
    Connections {
        target: root.controller
        function onPromptNetworkChanged() { password.clear(); showPassword.checked = false }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "WI-FI"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 16 }
            Item { Layout.fillWidth: true }
            ControlButton {
                text: root.controller.enabled ? "Power off" : "Power on"
                enabled: !!root.controller.adapter && root.controller.hardwareEnabled
                onClicked: root.controller.togglePower()
            }
            ControlButton {
                text: root.controller.scanAdapter ? "Stop scan" : "Scan (30s)"
                enabled: !!root.controller.adapter && root.controller.enabled && root.controller.hardwareEnabled
                onClicked: {
                    if (root.controller.scanAdapter) root.controller.stopScan()
                    else root.controller.startScan()
                }
            }
        }
        RowLayout {
            visible: root.controller.adapters.length > 1
            Repeater {
                model: root.controller.adapters
                delegate: ControlButton {
                    required property var modelData
                    text: modelData.name
                    selected: modelData === root.controller.adapter
                    onClicked: { root.controller.selectedAdapter = modelData; root.controller.startScan() }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: !root.controller.adapter ? "No Wi-Fi adapter found. Check that NetworkManager is running and managing the adapter."
                  : !root.controller.hardwareEnabled ? "Wi-Fi is blocked by the hardware/radio switch."
                  : !root.controller.enabled ? "Wi-Fi is off."
                  : root.controller.networks.length === 0 ? "No networks found. Scan again or move closer to the access point."
                  : "Select a network to connect. Saved passwords are reused automatically."
            color: Theme.textColorSoft
            font.pixelSize: 13
        }
        Text {
            visible: text.length > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.controller.connectivityMessage
            color: Theme.textColorAccent
        }
        Text {
            visible: text.length > 0
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: root.controller.message
            color: Theme.textColorSoft
        }
        ColumnLayout {
            visible: !!root.controller.promptNetwork
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: root.controller.promptNetwork ? "Password for " + root.controller.promptNetwork.name : ""
                color: Theme.textColorAccent
            }
            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: password
                    objectName: "wifiPassword"
                    Layout.fillWidth: true
                    placeholderText: "Network password"
                    echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                    selectByMouse: true
                    onAccepted: root.submit()
                }
                CheckBox { id: showPassword; text: "Show" }
            }
            RowLayout {
                ControlButton {
                    text: "Connect with password"
                    enabled: !root.controller.busy && password.text.length > 0
                    onClicked: root.submit()
                }
                ControlButton { text: "Cancel"; onClicked: { root.controller.cancelPrompt(); password.clear() } }
            }
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: root.controller.networks
                delegate: Rectangle {
                    id: networkCard
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: cardContent.implicitHeight + 20
                    radius: 8
                    color: Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, modelData.connected ? 0.12 : 0.04)
                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: 10
                        Text {
                            Layout.fillWidth: true
                            text: networkCard.modelData.name || "Hidden network"
                            color: Theme.textColor
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: Math.round(networkCard.modelData.signalStrength * 100) + "% · "
                                  + WifiSecurityType.toString(networkCard.modelData.security)
                            color: Theme.textColorSoft
                        }
                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            text: ConnectionState.toString(networkCard.modelData.state) + (networkCard.modelData.known ? " · Saved" : "")
                            color: networkCard.modelData.connected ? Theme.textColorAccent : Theme.textColorSoft
                        }
                        ControlButton {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: networkCard.modelData.connected ? "Disconnect" : networkCard.modelData.stateChanging ? "Connecting…" : "Connect"
                            enabled: root.controller.enabled && root.controller.hardwareEnabled && !networkCard.modelData.stateChanging
                                     && (networkCard.modelData.connected || !root.controller.busy) && !!networkCard.modelData.name
                            onClicked: {
                                if (networkCard.modelData.connected) root.controller.disconnectNetwork(networkCard.modelData)
                                else root.controller.connectNetwork(networkCard.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
