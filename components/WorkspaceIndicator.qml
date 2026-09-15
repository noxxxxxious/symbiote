pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Hyprland
import "."
import "WorkspaceLogic.js" as Logic

Item {
    id: root
    required property var targetScreen
    property bool suppressed: false
    readonly property var config: Config.sAdapter.workspaces
    readonly property string edge: config.edge
    readonly property bool vertical: edge === "left" || edge === "right"
    property var monitor: Hyprland.monitors.values.find(function(m) { return m.name === root.targetScreen.name }) || null
    readonly property int currentId: config.vdesk ? WorkspaceController.activeVdesk : (monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 0)
    readonly property int displayCount: Math.max(1, Math.min(config.count, 12, Math.floor(((vertical ? height : width) - 40) / config.nodeSpacing)))
    // Tendril geometry is intentionally code-level tuning rather than a
    // settings surface. The visual dock controls below remain user-facing.
    property int tendrilCount: 10
    property real tendrilReach: 36
    property real tendrilRootWidth: 4
    property real tendrilTipWidth: 2
    property var nativeWorkspaces: Hyprland.workspaces.values
    readonly property var entries: Logic.entries(currentId, displayCount, config.vdesk ? WorkspaceController.vdesks : nativeWorkspaces)
    readonly property int activeIndex: entries.findIndex(function(e) { return e.id === root.currentId })
    property bool engaged: false
    property bool surfaceHovered: false
    property bool edgeHovered: false
    property bool sharedHotZoneHovered: false
    property bool changeReveal: false
    property bool initialized: false
    property int previousId: 0
    property real liquidTarget: 0
    readonly property bool shown: !config.autoHide || engaged || changeReveal
    property real reveal: shown ? 1 : 0
    readonly property bool fullyShown: enabled && reveal === 1
    property alias liquidPosition: fluid.liquidPosition
    readonly property bool dwelling: changeTimer.running
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    function applyLiquidTarget() {
        if (fullyShown || !changeReveal) liquidTarget = Math.max(0, activeIndex)
    }
    function beginChangePresentation() {
        if (changeReveal) changeTimer.restart()
        // Let Behavior.enabled observe arrival before changing its target.
        Qt.callLater(applyLiquidTarget)
    }
    function syncWorkspace() {
        if (!initialized) return
        var changed = currentId !== previousId
        var hadWorkspace = previousId !== 0
        previousId = currentId
        if (changed && hadWorkspace && currentId !== 0 && config.showOnChange && enabled) {
            changeTimer.stop()
            changeReveal = true
            if (fullyShown) beginChangePresentation()
        } else if (!changeReveal || fullyShown) {
            liquidTarget = Math.max(0, activeIndex)
        }
    }
    Component.onCompleted: {
        previousId = currentId
        liquidTarget = Math.max(0, activeIndex)
        initialized = true
    }
    onCurrentIdChanged: Qt.callLater(syncWorkspace)
    onActiveIndexChanged: Qt.callLater(syncWorkspace)
    onFullyShownChanged: if (fullyShown) beginChangePresentation()
    Timer {
        id: changeTimer
        interval: Math.max(1, root.config.revealDuration)
        onTriggered: root.changeReveal = false
    }
    readonly property real span: Math.max(0, entries.length - 1) * config.nodeSpacing + config.chamberRadius * 2 + 20
    readonly property real surfaceWidth: vertical ? 54 : span
    readonly property real surfaceHeight: vertical ? span : 54
    readonly property real restX: edge === "left" ? Theme.borderThickness + 6 : edge === "right" ? width - Theme.borderThickness - 6 - surfaceWidth : (width - surfaceWidth) / 2
    readonly property real restY: edge === "top" ? Theme.borderThickness + 6 : edge === "bottom" ? height - Theme.borderThickness - 6 - surfaceHeight : (height - surfaceHeight) / 2
    property alias hotZone: hotZone
    property alias hitSurface: surface
    visible: config.enabled && !suppressed
    enabled: visible
    function summon() {
        if (!enabled) return
        engaged = true
        hideTimer.restart()
    }
    function hoverChanged() {
        if (surfaceHovered || edgeHovered || sharedHotZoneHovered) { engaged = true; hideTimer.stop() }
        else hideTimer.restart()
    }
    onSurfaceHoveredChanged: hoverChanged()
    onEdgeHoveredChanged: hoverChanged()
    onSharedHotZoneHoveredChanged: hoverChanged()
    function cancelReveal() {
        engaged = false
        changeReveal = false
        hideTimer.stop()
        changeTimer.stop()
        liquidTarget = Math.max(0, activeIndex)
    }
    onEnabledChanged: if (!enabled) cancelReveal()
    onEdgeChanged: cancelReveal()
    Timer {
        id: hideTimer
        interval: 900
        onTriggered: if (!root.surfaceHovered && !root.edgeHovered && !root.sharedHotZoneHovered) root.engaged = false
    }
    Item {
        id: hotZone
        x: root.vertical ? (root.edge === "left" ? 0 : root.width - width) : (root.width - width) / 2
        y: root.vertical ? (root.height - height) / 2 : (root.edge === "top" ? 0 : root.height - height)
        width: root.vertical ? Math.max(8, Theme.borderThickness) : root.surfaceWidth
        height: root.vertical ? root.surfaceHeight : Math.max(8, Theme.borderThickness)
        HoverHandler { blocking: false; onHoveredChanged: root.edgeHovered = hovered }
    }
    ShaderEffect {
        id: fluid
        readonly property real band: Theme.borderThickness + 6 + root.config.chamberRadius * 2 + 8
        x: root.vertical ? (root.edge === "left" ? 0 : root.width - band) : surface.x
        y: root.vertical ? surface.y : (root.edge === "top" ? 0 : root.height - band)
        width: root.vertical ? band : surface.width
        height: root.vertical ? surface.height : band
        visible: root.reveal > 0.001
        opacity: root.reveal
        property vector2d size: Qt.vector2d(width, height)
        property vector2d nodeOrigin: Qt.vector2d(surface.x - x, surface.y - y)
        property real verticalF: root.vertical ? 1 : 0
        property real nodeCount: root.entries.length
        property real nodeSpacing: root.config.nodeSpacing
        property real chamberRadius: root.config.chamberRadius
        property real tubeRadius: root.config.tubeRadius
        property real liquidPosition: root.liquidTarget
        property real liquidEnabled: root.activeIndex >= 0 && (!root.config.vdesk || !WorkspaceController.vdeskError) ? 1 : 0
        property real tendrilsEnabled: root.config.tendrils ? 1 : 0
        property real tendrilWidth: root.config.tendrilWidth
        property real tendrilCount: root.tendrilCount
        property real tendrilReach: root.tendrilReach
        property real tendrilRootWidth: root.tendrilRootWidth
        property real tendrilTipWidth: root.tendrilTipWidth
        property real dockSign: root.edge === "top" || root.edge === "left" ? 1 : -1
        property real dockNormal: (root.edge === "top" || root.edge === "left" ? Theme.borderThickness : band - Theme.borderThickness)
            - (root.vertical ? nodeOrigin.x : nodeOrigin.y) - 27
        property vector4d baseColor: Qt.vector4d(Theme.borderColor.r, Theme.borderColor.g, Theme.borderColor.b, Theme.borderColor.a)
        property vector4d liquidColor: Qt.vector4d(Theme.textColorAccent.r, Theme.textColorAccent.g, Theme.textColorAccent.b, Theme.textColorAccent.a)
        Behavior on liquidPosition {
            enabled: root.fullyShown
            NumberAnimation { duration: root.config.duration; easing.type: Easing.InOutCubic }
        }
        fragmentShader: Qt.resolvedUrl("shaders/workspace-docked.frag.qsb")
    }
    Item {
        id: surface
        width: root.surfaceWidth; height: root.surfaceHeight
        readonly property real hiddenX: root.edge === "left" ? -width : root.edge === "right" ? root.width : root.restX
        readonly property real hiddenY: root.edge === "top" ? -height : root.edge === "bottom" ? root.height : root.restY
        x: hiddenX + (root.restX - hiddenX) * root.reveal
        y: hiddenY + (root.restY - hiddenY) * root.reveal
        HoverHandler { onHoveredChanged: root.surfaceHovered = hovered }
        Repeater {
            model: root.entries
            delegate: Item {
                required property int index
                required property var modelData
                x: root.vertical ? 0 : 4 + index * root.config.nodeSpacing
                y: root.vertical ? 4 + index * root.config.nodeSpacing : 0
                width: root.vertical ? root.config.chamberRadius * 2 + 20 : root.config.nodeSpacing
                height: root.vertical ? root.config.nodeSpacing : root.config.chamberRadius * 2 + 20
                Text {
                    anchors.centerIn: parent
                    text: root.config.showNumbers ? (parent.modelData.id > 0 ? parent.modelData.id : "•") : ""
                    color: Theme.textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                MouseArea {
                    id: nodeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WorkspaceController.select(root.targetScreen, parent.modelData, root.currentId)
                    onWheel: function(wheel) {
                        var next = Math.max(1, root.currentId + (wheel.angleDelta.y < 0 ? 1 : -1))
                        WorkspaceController.select(root.targetScreen, {id: next, name: String(next)}, root.currentId)
                        wheel.accepted = true
                    }
                }
                ToolTip.visible: nodeMouse.containsMouse
                ToolTip.delay: 500
                ToolTip.text: root.config.vdesk && WorkspaceController.vdeskError ? WorkspaceController.vdeskError : (root.config.vdesk ? "Desktop " : "Workspace ") + modelData.name
            }
        }
    }
}
