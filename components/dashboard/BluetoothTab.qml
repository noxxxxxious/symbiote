pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import ".."

ScrollView {
    id: root
    property var controller: BluetoothController
    clip: true
    contentWidth: availableWidth
    Component.onDestruction: root.controller.stopScan()

    ColumnLayout {
        width: root.availableWidth
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "BLUETOOTH"; color: Theme.textColorAccent; font.bold: true; font.pixelSize: 16 }
            Item { Layout.fillWidth: true }
            ControlButton {
                text: root.controller.adapter && root.controller.adapter.enabled ? "Power off" : "Power on"
                enabled: !!root.controller.adapter && root.controller.adapter.state !== BluetoothAdapterState.Blocked
                onClicked: {
                    root.controller.stopScan()
                    root.controller.adapter.enabled = !root.controller.adapter.enabled
                }
            }
            ControlButton {
                text: root.controller.scanAdapter ? "Stop scan" : "Scan (30s)"
                enabled: !!root.controller.adapter && root.controller.adapter.enabled
                onClicked: root.controller.toggleScan()
            }
        }
        RowLayout {
            visible: Bluetooth.adapters.values.length > 1
            Repeater {
                model: Bluetooth.adapters
                delegate: ControlButton {
                    required property var modelData
                    text: modelData.name
                    selected: modelData === root.controller.adapter
                    onClicked: root.controller.selectedAdapter = modelData
                }
            }
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: !root.controller.adapter ? "No Bluetooth adapter found. Check that BlueZ is running."
                  : root.controller.adapter.state === BluetoothAdapterState.Blocked ? "Bluetooth is blocked by the hardware/radio switch."
                  : !root.controller.adapter.enabled ? "Bluetooth is off."
                  : root.controller.devices.length === 0 ? "Put your device in pairing mode, then scan."
                  : "Pair a new device or connect a saved device."
            color: Theme.textColorSoft
            font.pixelSize: 13
        }
        Text {
            visible: text.length > 0
            text: root.controller.message
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Theme.textColorSoft
        }
        ColumnLayout {
            visible: root.controller.promptType.length > 0
            Layout.fillWidth: true
            Text {
                text: root.controller.promptMessage
                color: Theme.textColorAccent
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            TextField {
                id: pairingInput
                visible: root.controller.needsInput
                Layout.fillWidth: true
                placeholderText: root.controller.promptType === "pin" ? "PIN" : "Passkey"
                maximumLength: root.controller.promptType === "pin" ? 16 : 6
                onAccepted: root.controller.respond(true, text)
            }
            RowLayout {
                ControlButton {
                    text: root.controller.needsInput ? "Submit" : "Confirm"
                    onClicked: { root.controller.respond(true, pairingInput.text); pairingInput.clear() }
                }
                ControlButton { text: "Reject"; onClicked: root.controller.respond(false, "") }
            }
        }
        ControlButton {
            visible: root.controller.pairing
            text: "Cancel pairing"
            onClicked: root.controller.cancelPair()
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: root.controller.devices
                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData
                    readonly property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                                                || modelData.state === BluetoothDeviceState.Disconnecting
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: deviceContent.implicitHeight + 20
                    radius: 8
                    color: Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, 0.04)
                    ColumnLayout {
                        id: deviceContent
                        anchors.fill: parent
                        anchors.margins: 10
                        Text {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.name || deviceRow.modelData.address
                            color: Theme.textColor
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: (deviceRow.modelData.pairing ? "Pairing…" : BluetoothDeviceState.toString(deviceRow.modelData.state))
                                  + (deviceRow.modelData.batteryAvailable ? " · " + Math.round(deviceRow.modelData.battery * 100) + "%" : "")
                            color: Theme.textColorSoft
                            wrapMode: Text.Wrap
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            enabled: !!root.controller.adapter && root.controller.adapter.enabled
                            ControlButton {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: deviceRow.modelData.paired ? (deviceRow.modelData.connected ? "Disconnect" : "Connect") : "Pair & connect"
                                enabled: !deviceRow.busy && !root.controller.pairing && !deviceRow.modelData.blocked
                                onClicked: {
                                    if (!deviceRow.modelData.paired) root.controller.pair(deviceRow.modelData)
                                    else deviceRow.modelData.connected = !deviceRow.modelData.connected
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: deviceRow.modelData.paired
                                ControlButton {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: deviceRow.modelData.trusted ? "Trusted" : "Trust"
                                    selected: deviceRow.modelData.trusted
                                    enabled: !deviceRow.busy
                                    onClicked: deviceRow.modelData.trusted = !deviceRow.modelData.trusted
                                }
                                ControlButton {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: "Forget"
                                    enabled: !deviceRow.busy && !root.controller.pairing
                                    onClicked: deviceRow.modelData.forget()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
