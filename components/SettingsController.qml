// components/SettingsController.qml
pragma Singleton
import QtQuick

QtObject {
    id: controller

    property var activeScreen: null
    property int trayMenuPreviewSerial: 0
    readonly property bool isOpen: activeScreen !== null

    function isOpenOn(screen) { return activeScreen && screen && activeScreen.name === screen.name }

    function openOn(screen) {
        LauncherController.close()
        activeScreen = screen
    }

    function close() { activeScreen = null }

    function toggleOn(screen) {
        if (isOpenOn(screen)) close()
        else openOn(screen)
    }

    function requestTrayMenuPreview() {
        trayMenuPreviewSerial++
        console.log("[STATE][SettingsController] tray menu preview request", trayMenuPreviewSerial)
    }
}
