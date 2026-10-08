import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: root
    property var controller: AudioController
    property real previousVolume: -1
    property bool previousMute: false
    property var previousNode: null
    property bool shown: false
    readonly property var node: root.controller.sink
    readonly property real volume: node && node.audio ? node.audio.volume : 0
    readonly property bool muted: !!node && !!node.audio && node.audio.muted
    width: 280
    height: 76
    radius: 14
    color: "#ee181820"
    border.color: Theme.textColorAccent
    visible: shown && !!node
    z: 40

    function changed() {
        // A default-device change initializes the baseline without a startup OSD.
        if (!node || !node.ready) {
            previousNode = node
            previousVolume = -1
            return
        }
        if (previousNode !== node || previousVolume < 0) {
            previousNode = node
            previousVolume = volume
            previousMute = muted
            return
        }
        if (Math.abs(volume - previousVolume) > 0.0001 || muted !== previousMute) {
            shown = true
            hideTimer.restart()
        }
        previousVolume = volume
        previousMute = muted
    }
    onVolumeChanged: changed()
    onMutedChanged: changed()
    onNodeChanged: changed()
    Component.onCompleted: changed()
    Connections {
        target: root.node
        function onReadyChanged() { root.changed() }
    }
    Timer { id: hideTimer; interval: 1600; onTriggered: root.shown = false }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        Text {
            text: root.muted ? "Output muted" : "Volume  " + Math.round(root.volume * 100) + "%"
            color: Theme.textColor
            font.pixelSize: 15
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 5
            radius: 3
            color: "#454550"
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.volume))
                height: parent.height
                radius: 3
                color: Theme.textColorAccent
                opacity: root.muted ? 0.35 : 1
            }
        }
    }
}
