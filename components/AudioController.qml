pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    property PwObjectTracker tracker: PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }

    function select(node, output) {
        if (output) Pipewire.preferredDefaultAudioSink = node
        else Pipewire.preferredDefaultAudioSource = node
    }
    function adjustVolume(delta) {
        if (sink && sink.audio) {
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
        }
    }
    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }
}
