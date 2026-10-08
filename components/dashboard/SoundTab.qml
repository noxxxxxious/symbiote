pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import ".."

ScrollView {
    id: root
    property var controller: AudioController
    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 14
        Text {
            text: Pipewire.ready ? "Select a default device" : "Waiting for PipeWire…"
            color: Theme.textColorSoft
            font.pixelSize: 13
        }
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 20
            rowSpacing: 0
            Repeater {
                model: [true, false]
                delegate: ColumnLayout {
                    id: section
                    required property bool modelData
                    readonly property var devices: modelData ? root.controller.outputs : root.controller.inputs
                    readonly property var node: modelData ? root.controller.sink : root.controller.source
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignTop
                    spacing: 8
                    Text {
                        text: section.modelData ? "OUTPUT" : "INPUT"
                        color: Theme.textColorAccent
                        font.bold: true
                        font.pixelSize: 16
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        enabled: !!section.node && section.node.ready && !!section.node.audio
                        ControlButton {
                            Layout.minimumWidth: 80
                            Layout.preferredWidth: 80
                            Layout.maximumWidth: 80
                            text: section.node && section.node.audio && section.node.audio.muted ? "Unmute" : "Mute"
                            selected: !!section.node && !!section.node.audio && section.node.audio.muted
                            onClicked: section.node.audio.muted = !section.node.audio.muted
                        }
                        SettingsSlider {
                            Layout.fillWidth: true
                            from: 0; to: 1
                            value: section.node && section.node.audio ? section.node.audio.volume : 0
                            onMoved: section.node.audio.volume = value
                        }
                        Text {
                            text: section.node && section.node.audio ? Math.round(section.node.audio.volume * 100) + "%" : "—"
                            color: Theme.textColor
                            Layout.minimumWidth: 48
                        }
                    }
                    Repeater {
                        model: section.devices
                        delegate: ControlButton {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: (selected ? "●  " : "○  ") + (modelData.description || modelData.nickname || modelData.name)
                            selected: section.node === modelData
                            onClicked: root.controller.select(modelData, section.modelData)
                        }
                    }
                    Text {
                        visible: section.devices.length === 0
                        text: section.modelData ? "No audio outputs available." : "No audio inputs available."
                        color: Theme.textColorSoft
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
