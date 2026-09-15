pragma Singleton
import QtQuick

QtObject {
    property string activeScreen: ""
    onActiveScreenChanged: console.log("[PowerMenuController] activeScreen:", activeScreen || "<none>")
    function isOpenOn(screen) { return screen && activeScreen === screen.name }
    function openOn(screen) {
        if (!screen) {
            console.log("[PowerMenuController] open ignored: no screen")
            return
        }
        console.log("[PowerMenuController] open requested:", screen.name, "current:", activeScreen || "<none>")
        LauncherController.close()
        SettingsController.close()
        activeScreen = screen.name
    }
    function close() {
        console.log("[PowerMenuController] close requested; current:", activeScreen || "<none>")
        activeScreen = ""
    }
}
