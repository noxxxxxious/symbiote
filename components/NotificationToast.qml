pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import "."

Item {
    id: root

    required property var targetScreen
    required property real screenWidth
    required property real screenHeight

    readonly property var notification: NotificationController.toastNotification
    readonly property string screenMode: Config.sAdapter.notifications.toastScreenMode
    readonly property bool screenMatches: screenMode === "all screens"
        || (screenMode === "specific screen" && Config.sAdapter.notifications.toastScreen === targetScreen.name)
        || (screenMode === "current active screen" && NotificationController.toastScreenName === targetScreen.name)
    property bool presenting: false
    readonly property bool shown: presenting && notification !== null && screenMatches

    property real finalWidth: Math.min(380, Math.max(280, screenWidth * 0.28))
    property real finalHeight: 116
    property real margin: 14
    readonly property real horizontalInset: margin + Config.sAdapter.notifications.toastHorizontalOffset
    readonly property real verticalInset: margin + Config.sAdapter.notifications.toastVerticalOffset
    property real cornerRounding: 18
    readonly property real panelCornerRounding: cornerRounding
    readonly property string cornerPosition: Config.sAdapter.notifications.toastPosition
    readonly property bool isTop: cornerPosition.indexOf("top") !== -1
    readonly property bool isLeft: cornerPosition.indexOf("left") !== -1
    readonly property bool isRight: cornerPosition.indexOf("right") !== -1
    readonly property bool isBottom: cornerPosition.indexOf("bottom") !== -1
    readonly property real restingX: isRight
        ? screenWidth - Theme.borderThickness - horizontalInset - width
        : isLeft ? Theme.borderThickness + horizontalInset
        : (screenWidth - width) / 2
    readonly property real restingY: isBottom
        ? screenHeight - Theme.borderThickness - verticalInset - height
        : isTop ? Theme.borderThickness + verticalInset
        : (screenHeight - height) / 2
    readonly property real hiddenX: isRight ? screenWidth + width : isLeft ? -width : restingX
    readonly property real hiddenY: isBottom ? screenHeight + height : isTop ? -height : restingY

    width: finalWidth
    height: finalHeight
    x: shown ? restingX : hiddenX
    y: shown ? restingY : hiddenY
    visible: shown || (x > -width && x < screenWidth && y > -height && y < screenHeight)

    property real tendrilsPer100px: Config.sAdapter.notifications.toastTendrilsPer100px
    property int tendrilMaxActive: Config.sAdapter.notifications.toastTendrils ? Config.sAdapter.notifications.toastTendrilMaxActive : 0
    property vector2d tendrilMaxLengthRangeOverride: Qt.vector2d(55, 130)
    property vector2d tendrilRootThicknessRangeOverride: Qt.vector2d(3, 6)
    property vector2d tendrilWaistThicknessRangeOverride: Qt.vector2d(1, 2)
    property vector2d tendrilPanelThicknessRangeOverride: Qt.vector2d(2, 4)
    property real tendrilBlendRadiusRootOverride: 14
    property real tendrilBlendRadiusPanelOverride: 10
    property real tendrilWaistSmoothingOverride: 26
    property real tendrilGrowSpeedOverride: 0.28
    property real tendrilShrinkSpeedOverride: 0.18
    property int tendrilMaxTop: isTop ? 3 : 0
    property int tendrilMaxBottom: isBottom ? 3 : 0
    property int tendrilMaxLeft: isLeft ? 3 : 0
    property int tendrilMaxRight: isRight ? 3 : 0
    property int tendrilMaxCorners: 2

    // Extra links may only anchor to screen borders selected by toast position.
    property bool tendrilExtraConnections: Config.sAdapter.notifications.toastExtraTendrils
    readonly property real toastExtraMaxLength: Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight)
    property vector2d tendrilExtraMaxLengthRangeOverride: Qt.vector2d(toastExtraMaxLength, toastExtraMaxLength)
    property vector2d tendrilExtraRootThicknessRangeOverride: Qt.vector2d(Config.sAdapter.notifications.toastExtraTendrilRootWidth, Config.sAdapter.notifications.toastExtraTendrilRootWidth)
    property vector2d tendrilExtraWaistThicknessRangeOverride: Qt.vector2d(Config.sAdapter.notifications.toastExtraTendrilWaistWidth, Config.sAdapter.notifications.toastExtraTendrilWaistWidth)
    property vector2d tendrilExtraPanelThicknessRangeOverride: Qt.vector2d(Config.sAdapter.notifications.toastExtraTendrilPanelWidth, Config.sAdapter.notifications.toastExtraTendrilPanelWidth)
    property real tendrilExtraGrowSpeedOverride: 0.20
    property real tendrilExtraShrinkSpeedOverride: 0.14

    function extraTendrilSpecs() {
        var specs = []
        var count = Math.max(0, Config.sAdapter.notifications.toastExtraTendrilCount)
        var reach = Config.sAdapter.notifications.toastExtraTendrilReach
        var rootSpread = Config.sAdapter.notifications.toastExtraTendrilRootSpread
        var panelSpread = Config.sAdapter.notifications.toastExtraTendrilPanelSpread
        var inset = Theme.borderThickness

        function fractionAt(index) {
            return count === 1 ? 0.5 : index / (count - 1)
        }
        // `panelSide` is toast edge receiving tips; `border` is screen edge
        // receiving roots. Keeping these separate avoids reversed fans.
        function addVerticalSide(panelSide, border, edgeAligned) {
            for (var i = 0; i < count; ++i) {
                var fraction = fractionAt(i)
                var panelFraction = 0.5 + (fraction - 0.5) * panelSpread
                var tipY = y + height * panelFraction
                var tipX = panelSide === "left" ? x + 3 : x + width - 3
                var rootBaseX = edgeAligned
                    ? (panelSide === "left"
                       ? tipX * (1 - reach)
                       : tipX + (screenWidth - tipX) * reach)
                    : tipX + (screenWidth * 0.5 - tipX) * reach
                var rootX = Math.max(inset, Math.min(screenWidth - inset,
                    rootBaseX + (fraction - 0.5) * (screenWidth - inset * 2) * rootSpread))
                specs.push({
                    side: "extra-" + border,
                    rootX: rootX,
                    rootY: border === "bottom" ? screenHeight - inset : inset,
                    tipX: tipX,
                    tipY: tipY
                })
            }
        }
        function addHorizontalSide(panelSide, border, edgeAligned) {
            for (var i = 0; i < count; ++i) {
                var fraction = fractionAt(i)
                var panelFraction = 0.5 + (fraction - 0.5) * panelSpread
                var tipX = x + width * panelFraction
                var tipY = panelSide === "top" ? y + 3 : y + height - 3
                var rootBaseY = edgeAligned
                    ? (panelSide === "top"
                       ? tipY * (1 - reach)
                       : tipY + (screenHeight - tipY) * reach)
                    : tipY + (screenHeight * 0.5 - tipY) * reach
                var rootY = Math.max(inset, Math.min(screenHeight - inset,
                    rootBaseY + (fraction - 0.5) * (screenHeight - inset * 2) * rootSpread))
                specs.push({
                    side: "extra-" + border,
                    rootX: border === "right" ? screenWidth - inset : inset,
                    rootY: rootY,
                    tipX: tipX,
                    tipY: tipY
                })
            }
        }

        // Panel-side → screen-border map. Fans always leave toward available
        // screen space, then reach a border perpendicular to that panel side.
        if (isTop && isLeft) {
            addVerticalSide("right", "top")
            addHorizontalSide("bottom", "left")
        } else if (isTop && isRight) {
            addVerticalSide("left", "top")
            addHorizontalSide("bottom", "right")
        } else if (isBottom && isLeft) {
            addVerticalSide("right", "bottom")
            addHorizontalSide("top", "left")
        } else if (isBottom && isRight) {
            addVerticalSide("left", "bottom")
            addHorizontalSide("top", "right")
        } else if (isTop || isBottom) {
            var verticalBorder = isTop ? "top" : "bottom"
            addVerticalSide("left", verticalBorder, true)
            addVerticalSide("right", verticalBorder, true)
        } else if (isLeft || isRight) {
            var horizontalBorder = isLeft ? "left" : "right"
            addHorizontalSide("top", horizontalBorder, true)
            addHorizontalSide("bottom", horizontalBorder, true)
        }
        return specs
    }

    Behavior on y {
        NumberAnimation { id: toastYAnimation; duration: 260; easing.type: Easing.OutCubic }
    }
    Behavior on x {
        NumberAnimation { id: toastXAnimation; duration: 260; easing.type: Easing.OutCubic }
    }

    Connections {
        target: NotificationController
        function onToastSerialChanged() {
            if (!root.screenMatches) return
            root.presenting = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: Math.max(2500, Config.sAdapter.notifications.toastDuration)
        onTriggered: root.presenting = false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: hideTimer.stop()
        onExited: if (root.presenting) hideTimer.restart()
        onClicked: {
            if (!NotificationController.activate(root.notification))
                NotificationController.openOn(root.targetScreen)
            root.presenting = false
        }
    }

    IconImage {
        id: appIcon
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 36
        visible: source !== ""
        source: {
            if (!root.notification) return ""
            if (root.notification.image) return root.notification.image
            if (root.notification.appIcon) return Quickshell.iconPath(root.notification.appIcon, true)
            return ""
        }
    }

    Column {
        anchors.left: appIcon.visible ? appIcon.right : parent.left
        anchors.leftMargin: 14
        anchors.right: dismissButton.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            width: parent.width
            text: root.notification
                ? (root.notification.summary || Config.sAdapter.notifications.toastName)
                    + (root.notification.appName ? " from " + root.notification.appName : "")
                : ""
            color: Theme.textColorAccent
            font.pixelSize: 15
            font.bold: true
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.notification ? root.notification.body : ""
            textFormat: Text.PlainText
            color: Theme.textColor
            font.pixelSize: 13
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 3
        }
    }

    Rectangle {
        id: dismissButton
        z: 2
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 26
        height: 26
        radius: 13
        color: dismissMouse.containsMouse ? Qt.rgba(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, 0.20) : "transparent"
        Text { anchors.centerIn: parent; text: "×"; color: Theme.textColorSoft; font.pixelSize: 19 }
        MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                hideTimer.stop()
                root.presenting = false
                NotificationController.dismiss(root.notification)
            }
        }
    }
}
