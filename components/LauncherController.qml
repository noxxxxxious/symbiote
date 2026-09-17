// components/LauncherController.qml
pragma Singleton
import QtQuick

QtObject {
    id: controller

    // Holds the actual screen object (from Quickshell.screens / modelData),
    // or null when closed. Using the screen reference itself as the "which
    // screen" key avoids needing IDs or indices.
    property var activeScreen: ""

    function isOpenOn(screen) {
        return activeScreen === screen.name;
    }

    function openOn(screen) {
        PowerMenuController.close()
        SettingsController.close();
        NotificationController.close();
        DashboardController.close()
        activeScreen = screen.name;
    }

    function close() {
        activeScreen = "";
    }

    function toggleOn(screen) {
        if (isOpenOn(screen)) {
            close();
        } else {
            openOn(screen);
        }
    }
}
