pragma Singleton
import QtQuick
import "."

QtObject {
    id: root

    readonly property var validCorners: ["top-left", "top-right", "bottom-left", "bottom-right"]

    function positionOf(panel) {
        if (panel === "clock") return Config.sAdapter.clock.position
        if (panel === "tray") return Config.sAdapter.tray.position
        if (panel === "notifications") return Config.sAdapter.notifications.position
        return ""
    }

    function setPosition(panel, position) {
        if (panel === "clock") Config.sAdapter.clock.position = position
        else if (panel === "tray") Config.sAdapter.tray.position = position
        else if (panel === "notifications") Config.sAdapter.notifications.position = position
    }

    // Corner ownership is a permutation. Moving into an occupied corner swaps
    // its owner into the mover's old corner, so no panel can overlap another.
    function move(panel, destination) {
        if (validCorners.indexOf(destination) < 0) return
        var origin = positionOf(panel)
        if (!origin || origin === destination) return

        var panels = ["clock", "tray", "notifications"]
        var occupant = ""
        for (var i = 0; i < panels.length; ++i) {
            if (panels[i] !== panel && positionOf(panels[i]) === destination) {
                occupant = panels[i]
                break
            }
        }

        if (occupant) setPosition(occupant, origin)
        setPosition(panel, destination)
    }
}
