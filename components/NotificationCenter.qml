pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import "."

Item {
    id: root

    required property var targetScreen
    required property real screenWidth
    required property real screenHeight

    readonly property bool isOpen: NotificationController.isOpenOn(targetScreen)
    readonly property string cornerPosition: Config.sAdapter.notifications.position
    readonly property bool isRight: cornerPosition.indexOf("right") !== -1
    readonly property bool isBottom: cornerPosition.indexOf("bottom") !== -1

    property real finalWidth: Math.min(420, Math.max(320, screenWidth * 0.30))
    property real finalHeight: Math.max(360, screenHeight * 0.75)
    property real cornerRounding: 24

    readonly property real panelCornerRounding: cornerRounding

    readonly property vector4d cornerRadii: isRight
        ? Qt.vector4d(cornerRounding, 0, 0, cornerRounding)
        : Qt.vector4d(0, cornerRounding, cornerRounding, 0)

    readonly property bool visuallyOpen:
        isOpen || (x > -width && x < screenWidth)

    width: finalWidth
    height: finalHeight

    x: isOpen
        ? (isRight ? screenWidth - width : 0)
        : (isRight ? screenWidth + 2 : -width - 2)

    y: (screenHeight - height) / 2

    visible: visuallyOpen

    Behavior on x {
        NumberAnimation {
            id: centerXAnimation

            duration: 330
            easing.type: Easing.OutCubic
        }
    }

    // -------------------------------------------------------------------------
    // Notification model
    // -------------------------------------------------------------------------
    //
    // NotificationController.notifications is a JavaScript array of immutable
    // snapshot objects. Feeding that array directly to ListView causes the view
    // to treat every replacement of the array as a new model.
    //
    // ScriptModel compares the snapshots by their unique "key" property and
    // translates changes into model insertions/removals instead.

    ScriptModel {
        id: notificationModel

        values: NotificationController.notifications
        objectProp: "key"
    }

    // -------------------------------------------------------------------------
    // Scrollbar
    // -------------------------------------------------------------------------

    // Match Settings: accent thumb only, briefly shown while scrolling.
    component TransientScrollBar: ScrollBar {
        id: bar

        orientation: Qt.Vertical
        policy: ScrollBar.AlwaysOn
        hoverEnabled: true
        implicitWidth: 7
        minimumSize: 0.08

        opacity:
            root.isOpen
            && size < 0.999
            && (revealTimer.running || active || pressed || hovered)
                ? 1.0
                : 0.0

        background: null

        contentItem: Rectangle {
            implicitWidth: 4
            implicitHeight: 32
            radius: 2
            color: Theme.textColorAccent
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        function reveal() {
            if (root.isOpen && size < 0.999)
                revealTimer.restart()
        }

        onSizeChanged: {
            if (root.isOpen && size < 0.999)
                Qt.callLater(reveal)
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(reveal)
        }

        Connections {
            target: root

            function onIsOpenChanged() {
                if (root.isOpen)
                    Qt.callLater(bar.reveal)
                else
                    revealTimer.stop()
            }
        }

        Timer {
            id: revealTimer

            interval: 1300
            repeat: false
        }
    }

    // -------------------------------------------------------------------------
    // Tendrils
    // -------------------------------------------------------------------------

    property real tendrilsPer100px: 1.2
    property int tendrilMaxActive: 12
    property int tendrilExtraCount: Math.max(0, Config.sAdapter.notifications.centerExtraTendrilCount)
    property real tendrilExtraReach: Config.sAdapter.notifications.centerExtraTendrilReach
    property real tendrilExtraRootSpread: Config.sAdapter.notifications.centerExtraTendrilRootSpread
    property real tendrilExtraTipSpread: Config.sAdapter.notifications.centerExtraTendrilTipSpread
    // 12 normal + up to 24 configured extra links + headroom.
    property int tendrilSlotCapacityOverride: 40

    property vector2d tendrilMaxLengthRangeOverride:
        Qt.vector2d(100, 280)

    property vector2d tendrilRootThicknessRangeOverride:
        Qt.vector2d(5, 10)

    property vector2d tendrilWaistThicknessRangeOverride:
        Qt.vector2d(1, 3)

    property vector2d tendrilPanelThicknessRangeOverride:
        Qt.vector2d(3, 6)

    property real tendrilBlendRadiusRootOverride: 24
    property real tendrilBlendRadiusPanelOverride: 18
    property real tendrilWaistSmoothingOverride: 42

    property real tendrilGrowSpeedOverride: 0.20
    property real tendrilShrinkSpeedOverride: 0.13

    property int tendrilMaxTop: 6
    property int tendrilMaxBottom: 6
    property int tendrilMaxLeft: 0
    property int tendrilMaxRight: 0
    property int tendrilMaxCorners: 2

    // Center panel starts well away from top/bottom screen borders. Normal
    // tendrils need a wider acquisition range than small corner widgets.
    property bool tendrilUseScreenRelativeAttachDistance: true

    property real tendrilAttachOffset:
        Math.max(0, screenWidth * 0.5 - screenHeight * 0.26)

    // Guaranteed long links: roots live on screen top/bottom, tips attach to
    // center-facing halves of panel's top/bottom edges. These remain visible
    // even when normal perimeter sampling has no nearby screen edge.
    property bool tendrilExtraConnections:
        Config.sAdapter.notifications.centerExtraTendrils

    readonly property real notificationTendrilMaxLength:
        Math.sqrt(
            screenWidth * screenWidth
            + screenHeight * screenHeight
        )

    property vector2d tendrilExtraMaxLengthRangeOverride:
        Qt.vector2d(
            notificationTendrilMaxLength,
            notificationTendrilMaxLength
        )

    property vector2d tendrilExtraRootThicknessRangeOverride:
        Qt.vector2d(5, 10)

    property vector2d tendrilExtraWaistThicknessRangeOverride:
        Qt.vector2d(1.5, 3)

    property vector2d tendrilExtraPanelThicknessRangeOverride:
        Qt.vector2d(3, 6)

    property real tendrilExtraGrowSpeedOverride: 0.16
    property real tendrilExtraShrinkSpeedOverride: 0.10

    function extraTendrilSpecs() {
        var specs = []

        var count = root.tendrilExtraCount

        var top = Theme.borderThickness
        var bottom = screenHeight - Theme.borderThickness
        var innerX = isRight ? x : x + width
        var centerX = screenWidth * 0.5
        var direction = isRight ? -1 : 1
        var inwardSpan = Math.max(60, Math.abs(centerX - innerX))

        for (var i = 0; i < count; ++i) {
            var fraction =
                count === 1
                    ? 0.5
                    : i / (count - 1)

            var rootSpread = root.tendrilExtraRootSpread
            var tipSpread = root.tendrilExtraTipSpread
            var reach = root.tendrilExtraReach

            var rootX =
                innerX
                + direction
                    * inwardSpan
                    * (reach + fraction * rootSpread)

            var tipFraction =
                0.42 + fraction * tipSpread

            var tipX = isRight
                ? x + width * (1.0 - tipFraction)
                : x + width * tipFraction

            specs.push({
                side: "extra-top",
                rootX: rootX,
                rootY: top,
                tipX: tipX,
                tipY: y + 3
            })

            specs.push({
                side: "extra-bottom",
                rootX: rootX,
                rootY: bottom,
                tipX: tipX,
                tipY: y + height - 3
            })
        }

        return specs
    }

    // Prevent click-through to whatever is below the notification center.
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    // -------------------------------------------------------------------------
    // Content
    // -------------------------------------------------------------------------

    Column {
        anchors.fill: parent

        anchors.leftMargin:
            root.isRight
                ? 18
                : Theme.borderThickness + 16

        anchors.rightMargin:
            root.isRight
                ? Theme.borderThickness + 16
                : 18

        anchors.topMargin: 18
        anchors.bottomMargin: 18

        spacing: 12

        Text {
            width: parent.width
            height: 34

            text:
                Config.sAdapter.notifications.centerName.toUpperCase()
                + "  ·  "
                + NotificationController.count

            color: Theme.textColorAccent
            font.pixelSize: 14
            font.bold: true

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            elide: Text.ElideRight
        }

        Item {
            width: parent.width
            height: parent.height - 34 - 30 - parent.spacing * 2

            Text {
                anchors.centerIn: parent

                visible: NotificationController.count === 0

                text: "NO RECENT PULSES"

                color: Theme.textColorSoft
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            ListView {
                id: notificationList

                anchors.fill: parent

                visible: NotificationController.count > 0

                clip: true
                spacing: 8

                boundsBehavior: Flickable.StopAtBounds

                // IMPORTANT:
                //
                // Do not bind this directly to
                // NotificationController.notifications.
                //
                // ScriptModel keeps this QML model stable while translating
                // changes in our snapshot array into insert/remove operations.
                model: notificationModel

                onContentYChanged:
                    notificationScrollBar.reveal()

                delegate: Rectangle {
                    id: card

                    required property var modelData

                    width:
                        ListView.view
                            ? ListView.view.width
                            : 0

                    height:
                        Math.max(
                            82,
                            cardBody.implicitHeight + 24
                        )

                    radius: 12

                    color:
                        cardHover.hovered
                            ? Qt.rgba(
                                Theme.textColorAccent.r,
                                Theme.textColorAccent.g,
                                Theme.textColorAccent.b,
                                0.11
                            )
                            : Theme.secondaryColor

                    border.color:
                        cardHover.hovered
                            ? Theme.textColorAccent
                            : "transparent"

                    border.width: 1

                    HoverHandler {
                        id: cardHover
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked:
                            NotificationController.activate(
                                card.modelData
                            )
                    }

                    IconImage {
                        id: cardIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        width: 36
                        height: 36

                        visible: source !== ""

                        // These are snapshot strings now. We never reach into
                        // the live Notification QObject from this delegate.
                        source: {
                            if (card.modelData.image)
                                return card.modelData.image

                            if (card.modelData.appIcon)
                                return Quickshell.iconPath(
                                    card.modelData.appIcon,
                                    true
                                )

                            return ""
                        }
                    }

                    Column {
                        id: cardBody

                        anchors.left:
                            cardIcon.visible
                                ? cardIcon.right
                                : parent.left

                        anchors.right: cardDismiss.left
                        anchors.top: parent.top

                        anchors.leftMargin:
                            cardIcon.visible
                                ? 10
                                : 12

                        anchors.rightMargin: 12
                        anchors.topMargin: 12

                        spacing: 4

                        Text {
                            width: parent.width

                            text:
                                (
                                    card.modelData.summary
                                    || Config.sAdapter.notifications.toastName
                                )
                                + (
                                    card.modelData.appName
                                        ? " from "
                                            + card.modelData.appName
                                        : ""
                                )

                            color: Theme.textColorAccent

                            font.bold: true
                            font.pixelSize: 14

                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width

                            text: card.modelData.body

                            textFormat: Text.PlainText

                            color: Theme.textColor
                            font.pixelSize: 12

                            wrapMode: Text.Wrap

                            maximumLineCount: 4
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: cardDismiss

                        z: 2

                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 9

                        width: 26
                        height: 26
                        radius: 13

                        color:
                            cardDismissMouse.containsMouse
                                ? Qt.rgba(
                                    Theme.textColorAccent.r,
                                    Theme.textColorAccent.g,
                                    Theme.textColorAccent.b,
                                    0.20
                                )
                                : "transparent"

                        Text {
                            anchors.centerIn: parent

                            text: "×"
                            color: Theme.textColorSoft

                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: cardDismissMouse

                            anchors.fill: parent

                            hoverEnabled: true

                            onClicked:
                                NotificationController.dismiss(
                                    card.modelData
                                )
                        }
                    }
                }

                ScrollBar.vertical: TransientScrollBar {
                    id: notificationScrollBar
                }
            }
        }

        Rectangle {
            id: clearButton

            anchors.horizontalCenter: parent.horizontalCenter

            width: 145
            height: 30
            radius: 8

            color:
                clearMouse.containsMouse
                    ? Qt.rgba(
                        Theme.textColorAccent.r,
                        Theme.textColorAccent.g,
                        Theme.textColorAccent.b,
                        0.18
                    )
                    : Theme.secondaryColor

            Text {
                anchors.centerIn: parent

                width: parent.width - 12

                text:
                    "CLEAR "
                    + Config.sAdapter.notifications.centerName.toUpperCase()

                color: Theme.textColorAccent

                font.pixelSize: 10
                font.bold: true

                horizontalAlignment: Text.AlignHCenter

                elide: Text.ElideRight
            }

            MouseArea {
                id: clearMouse

                anchors.fill: parent

                hoverEnabled: true

                enabled:
                    NotificationController.count > 0

                onClicked: {
                    NotificationController.clearAllAndClose()
                }
            }
        }
    }
}
