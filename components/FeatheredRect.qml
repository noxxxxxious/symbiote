import QtQuick

ShaderEffect {
    id: root

    property color color: "white"
    property real radius: 0
    property real feather: 20

    fragmentShader: Qt.resolvedUrl("../shaders/feathered_rect.frag.qsb")
}
