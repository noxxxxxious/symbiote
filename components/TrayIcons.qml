// components/TrayIcons.qml
pragma Singleton
import QtQuick
import Quickshell

QtObject {
    // Keyed by SystemTrayItem.id. Values may be either an absolute
    // file path (used directly) or a theme icon name (resolved).
    readonly property var substitutions: ({
        // "someapp": "/home/nox/.local/share/icons/someapp.png",
        // "otherapp": "applications-other"
    })

    readonly property string fallbackIcon: "application-x-executable"

    function resolve(id, icon) {
        const sub = substitutions[id]
        if (sub)
            return sub.startsWith("/") || sub.startsWith("~")
                ? Qt.resolvedUrl(sub)
                : Quickshell.iconPath(sub, fallbackIcon)

        if (!icon)
            return Quickshell.iconPath(fallbackIcon, true)

        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=")
            const base = name.slice(name.lastIndexOf("/") + 1)
            return Qt.resolvedUrl(`${path}/${base}`)
        }

        return icon
    }
}

