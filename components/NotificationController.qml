pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var activeScreen: null

    // The toast may reference the live Notification because it only exists while
    // that notification is active. toastConnections clears it when it closes.
    property var toastNotification: null
    property string toastScreenName: ""
    property int toastSerial: 0

    // Notification history contains SNAPSHOTS, never Notification QObjects.
    //
    // A Notification can be destroyed when the sender closes it. Keeping that
    // QObject in this array would leave history entries referring to dead native
    // objects.
    property var notificationEntries: []

    // Unique key for ScriptModel/history identity. This only needs to be unique
    // for the lifetime of this controller instance.
    property int nextNotificationKey: 0

    // Live Notification objects are kept separately and only while they are
    // actually alive. This allows actions/dismissal to continue working.
    //
    // key -> Notification
    property var liveNotifications: ({})

    readonly property var notifications: notificationEntries
    readonly property int count: notificationEntries.length

    function makeEntry(notification) {
        root.nextNotificationKey++

        return {
            key: "notification-" + root.nextNotificationKey,
            notificationId: notification.id,
            summary: notification.summary || "",
            body: notification.body || "",
            appName: notification.appName || "",
            appIcon: notification.appIcon || "",
            image: notification.image || ""
        }
    }

    function liveNotificationFor(entry) {
        if (!entry || !entry.key)
            return null

        return root.liveNotifications[entry.key] || null
    }

    function removeEntry(entry) {
        if (!entry || !entry.key)
            return

        var entries = root.notificationEntries.slice()

        for (var i = 0; i < entries.length; ++i) {
            if (entries[i].key === entry.key) {
                entries.splice(i, 1)
                root.notificationEntries = entries
                return
            }
        }
    }

    function isOpenOn(screen) {
        return activeScreen && screen && activeScreen.name === screen.name
    }

    function openOn(screen) {
        LauncherController.close()
        SettingsController.close()
        PowerMenuController.close()
        activeScreen = screen
    }

    function close() {
        activeScreen = null
    }

    function toggleOn(screen) {
        isOpenOn(screen) ? close() : openOn(screen)
    }

    function dismiss(entry) {
        if (!entry)
            return

        // Resolve the live object BEFORE modifying the history model.
        var notification = root.liveNotificationFor(entry)

        // History removal operates only on the snapshot.
        root.removeEntry(entry)

        // dismiss() may synchronously cause the Notification QObject to close
        // and be destroyed. Do not access `notification` after this call.
        if (notification)
            notification.dismiss()
    }

    function activate(entry) {
        if (!entry)
            return false

        var notification = root.liveNotificationFor(entry)
        if (!notification)
            return false

        var actions = notification.actions || []
        var chosen = null

        for (var i = 0; i < actions.length; ++i) {
            if (actions[i].identifier === "default") {
                chosen = actions[i]
                break
            }
        }

        if (!chosen && actions.length > 0)
            chosen = actions[0]

        if (!chosen)
            return false

        // Remove the history snapshot first.
        //
        // Invoking an action may cause the application to immediately close the
        // notification, which can destroy the Notification QObject before
        // invoke() returns.
        root.removeEntry(entry)

        // IMPORTANT: Do not access `notification` or `chosen` after this call.
        chosen.invoke()

        return true
    }

    function clearAll() {
        var pending = root.notificationEntries.slice()

        // Clear the history model before touching any live Notification QObjects.
        root.notificationEntries = []

        for (var i = pending.length - 1; i >= 0; --i) {
            var notification = root.liveNotificationFor(pending[i])

            // dismiss() may destroy notification synchronously.
            // Nothing may access it after this line.
            if (notification)
                notification.dismiss()
        }
    }

    property NotificationServer server: NotificationServer {
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            // Quickshell requires notifications we intend to interact with to
            // remain tracked while alive.
            notification.tracked = true

            // Snapshot everything the history UI needs NOW, while the
            // Notification QObject is guaranteed to be alive.
            var entry = root.makeEntry(notification)

            // Keep the live object separately for actions/dismissal.
            root.liveNotifications[entry.key] = notification

            // A Notification QObject may be destroyed immediately after its
            // closed signal handlers finish. Drop our reference during that
            // signal, before destruction occurs.
            notification.closed.connect(function(reason) {
                if (root.liveNotifications[entry.key] === notification)
                    delete root.liveNotifications[entry.key]
            })

            // History contains only the plain snapshot.
            var entries = root.notificationEntries.slice()
            entries.unshift(entry)
            root.notificationEntries = entries

            // Toasts intentionally use the live Notification object.
            root.toastNotification = notification
            root.toastScreenName = Hyprland.focusedMonitor
                ? Hyprland.focusedMonitor.name
                : ""
            root.toastSerial++
        }
    }

    property Connections toastConnections: Connections {
        target: root.toastNotification
        ignoreUnknownSignals: true

        function onClosed(reason) {
            root.toastNotification = null
        }
    }
}
