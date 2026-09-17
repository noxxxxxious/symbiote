// components/dashboard/MediaTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "MEDIA"
            color: Theme.textColorAccent
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 1.1
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "MPRIS playback controls will live here."
            color: Theme.textColorSoft
            font.pixelSize: 13
        }
    }
}
