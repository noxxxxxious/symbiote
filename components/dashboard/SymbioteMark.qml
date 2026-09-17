// components/dashboard/SymbioteMark.qml
import QtQuick
import ".."

Item {
    id: root

    property color accentColor: Theme.textColorAccent
    property color softColor: Theme.textColorSoft

    implicitWidth: 150
    implicitHeight: 120

    function rgba(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onWidthChanged: mark.requestPaint()
    onHeightChanged: mark.requestPaint()
    onAccentColorChanged: mark.requestPaint()
    onSoftColorChanged: mark.requestPaint()

    Canvas {
        id: mark
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width * 0.50
            var cy = height * 0.51
            var scale = Math.min(width, height) / 120.0

            function tendril(x0, y0, c1x, c1y, c2x, c2y, x1, y1, thickness, alpha) {
                ctx.beginPath()
                ctx.moveTo(x0, y0)
                ctx.bezierCurveTo(c1x, c1y, c2x, c2y, x1, y1)
                ctx.lineWidth = thickness * scale
                ctx.lineCap = "round"
                ctx.strokeStyle = root.rgba(root.accentColor, alpha)
                ctx.stroke()
            }

            tendril(cx - 25*scale, cy - 19*scale, cx - 43*scale, cy - 29*scale,
                    cx - 52*scale, cy - 43*scale, cx - 61*scale, cy - 48*scale, 4.8, 0.58)
            tendril(cx + 20*scale, cy - 22*scale, cx + 39*scale, cy - 34*scale,
                    cx + 46*scale, cy - 47*scale, cx + 56*scale, cy - 50*scale, 3.8, 0.50)
            tendril(cx - 29*scale, cy + 4*scale, cx - 49*scale, cy + 1*scale,
                    cx - 57*scale, cy + 12*scale, cx - 63*scale, cy + 23*scale, 4.2, 0.48)
            tendril(cx + 28*scale, cy + 2*scale, cx + 48*scale, cy + 0*scale,
                    cx + 55*scale, cy + 12*scale, cx + 62*scale, cy + 18*scale, 4.5, 0.54)
            tendril(cx - 16*scale, cy + 25*scale, cx - 25*scale, cy + 42*scale,
                    cx - 16*scale, cy + 51*scale, cx - 10*scale, cy + 57*scale, 3.6, 0.46)
            tendril(cx + 14*scale, cy + 24*scale, cx + 25*scale, cy + 41*scale,
                    cx + 20*scale, cy + 50*scale, cx + 29*scale, cy + 57*scale, 4.0, 0.50)

            var gradient = ctx.createRadialGradient(
                cx - 10*scale, cy - 13*scale, 4*scale,
                cx, cy, 39*scale
            )
            gradient.addColorStop(0.0, root.rgba(root.accentColor, 0.42))
            gradient.addColorStop(0.62, root.rgba(root.accentColor, 0.17))
            gradient.addColorStop(1.0, root.rgba(root.accentColor, 0.04))

            ctx.beginPath()
            ctx.moveTo(cx - 27*scale, cy - 15*scale)
            ctx.bezierCurveTo(cx - 19*scale, cy - 34*scale, cx + 5*scale, cy - 37*scale, cx + 25*scale, cy - 23*scale)
            ctx.bezierCurveTo(cx + 39*scale, cy - 12*scale, cx + 36*scale, cy + 10*scale, cx + 24*scale, cy + 26*scale)
            ctx.bezierCurveTo(cx + 10*scale, cy + 38*scale, cx - 12*scale, cy + 36*scale, cx - 28*scale, cy + 22*scale)
            ctx.bezierCurveTo(cx - 40*scale, cy + 10*scale, cx - 39*scale, cy - 3*scale, cx - 27*scale, cy - 15*scale)
            ctx.closePath()
            ctx.fillStyle = gradient
            ctx.fill()
            ctx.lineWidth = 2.5 * scale
            ctx.strokeStyle = root.rgba(root.accentColor, 0.72)
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(cx + 1*scale, cy - 1*scale, 14*scale, 0, Math.PI * 2)
            ctx.fillStyle = root.rgba(root.accentColor, 0.28)
            ctx.fill()
            ctx.lineWidth = 2 * scale
            ctx.strokeStyle = root.rgba(root.accentColor, 0.86)
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(cx - 3*scale, cy - 5*scale, 4.5*scale, 0, Math.PI * 2)
            ctx.fillStyle = root.rgba(root.softColor, 0.52)
            ctx.fill()

            var nodes = [
                [-24, -6, 3.2], [19, -17, 2.8], [26, 10, 3.4],
                [-14, 22, 2.6], [7, 25, 2.3]
            ]
            for (var i = 0; i < nodes.length; ++i) {
                ctx.beginPath()
                ctx.arc(
                    cx + nodes[i][0]*scale,
                    cy + nodes[i][1]*scale,
                    nodes[i][2]*scale,
                    0,
                    Math.PI * 2
                )
                ctx.fillStyle = root.rgba(root.accentColor, 0.60)
                ctx.fill()
            }
        }
    }
}
