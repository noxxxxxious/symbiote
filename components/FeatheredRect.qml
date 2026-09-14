import QtQuick

ShaderEffect {
    id: root

    property vector2d size: Qt.vector2d(width, height)
    property color color: "white"
    property real radius: 0
    property real feather: 20

    blending: true
    fragmentShader: Qt.resolvedUrl("./shaders/feathered_rect.frag.qsb")
}
