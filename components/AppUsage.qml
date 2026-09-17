// components/AppUsage.qml
//
// Tracks how many times each app has been launched from the launcher,
// persisted to disk so it survives restarts. Same FileView+JsonAdapter
// pattern as Config.qml, but kept as a separate file/singleton since this
// is runtime-generated data, not user-editable theming - you wouldn't want
// a hand-edit to config.json accidentally wiping out weeks of usage stats,
// or vice versa.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root

    path: Quickshell.shellDir + "/app_usage.json"

    printErrors: false

    // App usage is low-value recovery data; direct writes are preferable here
    // to creating app_usage.json.XXXXXX siblings on every launcher update.
    atomicWrites: false

    property bool internalWriteWindow: false

    watchChanges: true
    onFileChanged: {
        if (!root.internalWriteWindow)
            reload()
    }

    property Timer internalWriteGuard: Timer {
        interval: 400
        repeat: false
        onTriggered: root.internalWriteWindow = false
    }

    property Timer saveDebounce: Timer {
        interval: 120
        repeat: false
        onTriggered: {
            root.internalWriteWindow = true
            root.writeAdapter()
            internalWriteGuard.restart()
        }
    }

    onAdapterUpdated: saveDebounce.restart()

    property alias sAdapter: usageAdapter

    JsonAdapter {
        id: usageAdapter

        // Arbitrary map of desktop-entry id -> launch count. `var` is the
        // JsonAdapter type for free-form JSON objects/arrays whose keys
        // aren't known ahead of time (app ids vary per machine), unlike
        // Config.qml's JsonObject sections which have a fixed schema.
        property var counts: ({})
    }

    // Reassigning the WHOLE object (rather than mutating usageAdapter.counts
    // in place) is required - QML property change notification only fires
    // on assignment, not on mutating a nested JS object's fields in place.
    function recordUsage(appId) {
        if (!appId)
            return;
        var c = Object.assign({}, usageAdapter.counts);
        c[appId] = (c[appId] || 0) + 1;
        usageAdapter.counts = c;
    }

    function usageFor(appId) {
        if (!appId)
            return 0;
        return usageAdapter.counts[appId] || 0;
    }
}
