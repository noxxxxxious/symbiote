pragma ComponentBehavior: Bound
import QtQuick
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

    // Workspace tendrils belong to the entire indicator organism. They are
    // exported as ordinary border tendril slots so Border.qml/border.frag owns
    // the actual union with the screen border, just like every other panel.
    readonly property int tendrilCount: Math.max(0, Math.min(16, Math.round(config.tendrilCount)))
    readonly property real tendrilReach: Math.max(0, config.tendrilReach)
    readonly property real tendrilRootWidth: Math.max(0.1, config.tendrilRootWidth)
    readonly property real tendrilTipWidth: Math.max(0.1, config.tendrilTipWidth)
    readonly property real tendrilJitter: Math.max(0, config.tendrilJitter)
    readonly property real tendrilSpread: Math.max(0.05, Math.min(1.0, config.tendrilSpread))
    readonly property real requestedDockInset: Math.max(0, config.dockInset ?? 0)

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

    // Two-lobe liquid dynamics. The leader still uses the configured transition
    // timing; the follower is an underdamped spring mass. It therefore lags on
    // launch, carries its momentum through the leader at arrival, overshoots,
    // crosses back with less energy, and naturally settles into the same chamber.
    property real liquidPosition: liquidTarget
    property real liquidFollowerPosition: liquidTarget
    property real liquidVelocity: 0
    property real liquidFollowerVelocity: 0
    property real liquidPreviousPosition: liquidTarget
    property real liquidLastTickMs: 0
    property real liquidPulsePhase: 0

    readonly property real liquidFollowerScale: Math.max(0.25, Math.min(2.0, config.liquidFollowerScale ?? 0.72))
    readonly property real liquidSlingshot: Math.max(0.2, Math.min(2.5, config.liquidSlingshot ?? 1.0))
    readonly property real liquidRecoil: Math.max(0.2, Math.min(2.5, config.liquidRecoil ?? 1.0))
    readonly property bool liquidIdlePulse: config.liquidIdlePulse ?? true
    readonly property real liquidPulseStrength: Math.max(0, config.liquidPulseStrength ?? 1.75)
    readonly property real liquidPulseSpeed: Math.max(0.05, config.liquidPulseSpeed ?? 0.55)
    readonly property real liquidDurationSeconds: Math.max(0.15, config.duration / 1000.0)
    readonly property real liquidMotionStrength: Math.min(2.0, Math.max(Math.abs(liquidVelocity), Math.abs(liquidFollowerVelocity)) * liquidDurationSeconds / 3.0)
    readonly property bool dwelling: changeTimer.running

    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on liquidPosition {
        enabled: root.fullyShown
        NumberAnimation { duration: root.config.duration; easing.type: Easing.InOutCubic }
    }

    function resetLiquidDynamics(position) {
        liquidFollowerPosition = position
        liquidVelocity = 0
        liquidFollowerVelocity = 0
        liquidPreviousPosition = position
        liquidLastTickMs = Date.now()
    }

    Timer {
        id: liquidDynamicsClock
        interval: 16
        repeat: true
        running: root.enabled && root.liquidEnabledF > 0.5

        onRunningChanged: {
            root.liquidLastTickMs = Date.now()
            root.liquidPreviousPosition = root.liquidPosition
            if (!running) {
                root.liquidVelocity = 0
                root.liquidFollowerVelocity = 0
            }
        }

        onTriggered: {
            var now = Date.now()
            var dt = root.liquidLastTickMs > 0 ? (now - root.liquidLastTickMs) / 1000.0 : interval / 1000.0
            root.liquidLastTickMs = now
            dt = Math.max(0.008, Math.min(0.033, dt))

            // Smoothed measured leader velocity drives directional stretching.
            var measuredVelocity = (root.liquidPosition - root.liquidPreviousPosition) / dt
            root.liquidPreviousPosition = root.liquidPosition
            var velocityBlend = 1.0 - Math.exp(-20.0 * dt)
            root.liquidVelocity += (measuredVelocity - root.liquidVelocity) * velocityBlend

            // Keep the same qualitative spring response as transition duration
            // changes: stiffness scales with 1/t^2 and damping with 1/t.
            var timeScale = 0.30 / root.liquidDurationSeconds
            var spring = 120.0 * timeScale * timeScale * root.liquidSlingshot
            // Higher recoil deliberately means less damping / more return swing.
            var damping = 10.0 * timeScale / root.liquidRecoil
            var displacement = root.liquidPosition - root.liquidFollowerPosition
            var acceleration = displacement * spring - root.liquidFollowerVelocity * damping

            root.liquidFollowerVelocity += acceleration * dt
            root.liquidFollowerPosition += root.liquidFollowerVelocity * dt

            // Allow a real overshoot beyond the endpoint center, but keep the
            // secondary lobe inside the endpoint chamber instead of leaving the
            // workspace organism entirely.
            var endpointMargin = root.config.chamberRadius / Math.max(root.config.nodeSpacing, 1) * 0.78
            var minimum = -endpointMargin
            var maximum = Math.max(0, root.entries.length - 1) + endpointMargin
            if (root.liquidFollowerPosition < minimum) {
                root.liquidFollowerPosition = minimum
                if (root.liquidFollowerVelocity < 0) root.liquidFollowerVelocity *= -0.12
            } else if (root.liquidFollowerPosition > maximum) {
                root.liquidFollowerPosition = maximum
                if (root.liquidFollowerVelocity > 0) root.liquidFollowerVelocity *= -0.12
            }

            // Kill only sub-pixel numerical ringing after the visible recoil is
            // finished. This keeps the idle state perfectly stable for pulsing.
            if (Math.abs(root.liquidPosition - root.liquidTarget) < 0.0005
                    && Math.abs(root.liquidFollowerPosition - root.liquidPosition) < 0.0005
                    && Math.abs(root.liquidFollowerVelocity) < 0.005
                    && Math.abs(root.liquidVelocity) < 0.005) {
                root.liquidFollowerPosition = root.liquidPosition
                root.liquidFollowerVelocity = 0
                root.liquidVelocity = 0
            }

            if (root.liquidIdlePulse) {
                root.liquidPulsePhase += dt * 6.28318530718 * root.liquidPulseSpeed
                if (root.liquidPulsePhase > 6.28318530718)
                    root.liquidPulsePhase -= 6.28318530718
            }
        }
    }

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
        resetLiquidDynamics(liquidTarget)
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
    readonly property real maxDockInset: Math.max(0,
        (vertical ? width - surfaceWidth : height - surfaceHeight)
        - 2 * (Theme.borderThickness + 6))
    readonly property real dockInset: Math.min(requestedDockInset, maxDockInset)

    // dockInset always means "farther into the screen", regardless of edge.
    readonly property real restX: edge === "left"
        ? Theme.borderThickness + 6 + dockInset
        : edge === "right"
            ? width - Theme.borderThickness - 6 - dockInset - surfaceWidth
            : (width - surfaceWidth) / 2
    readonly property real restY: edge === "top"
        ? Theme.borderThickness + 6 + dockInset
        : edge === "bottom"
            ? height - Theme.borderThickness - 6 - dockInset - surfaceHeight
            : (height - surfaceHeight) / 2

    property alias hotZone: hotZone
    property alias hitSurface: surface
    visible: config.enabled && !suppressed
    enabled: visible

    // Geometry exported to the shared Border shader. firstNodeCenter is in
    // screen coordinates and remains correct for all four docking edges.
    readonly property vector2d firstNodeCenter: Qt.vector2d(
        surface.x + config.chamberRadius + 10,
        surface.y + config.chamberRadius + 10
    )
    readonly property real shaderEnabledF: enabled && reveal > 0.001 ? 1.0 : 0.0
    readonly property real liquidEnabledF: activeIndex >= 0 && (!config.vdesk || !WorkspaceController.vdeskError) ? 1.0 : 0.0

    function tendrilHash(n) {
        var value = Math.sin(n * 12.9898 + 78.233) * 43758.5453
        return value - Math.floor(value)
    }

    function buildTendrilSlots() {
        if (!enabled || reveal <= 0.001 || !config.tendrils || tendrilCount <= 0 || entries.length <= 0)
            return []

        var count = tendrilCount
        var nodeEnd = Math.max(0, entries.length - 1) * config.nodeSpacing
        var organismStart = -config.chamberRadius * 0.78
        var organismEnd = nodeEnd + config.chamberRadius * 0.78
        var organismSpan = Math.max(1, organismEnd - organismStart)
        var occupiedSpan = organismSpan * tendrilSpread
        var occupiedStart = (organismStart + organismEnd - occupiedSpan) * 0.5
        var widthBoost = Math.max(0, config.tendrilWidth) * 0.2
        var rootThick = tendrilRootWidth + widthBoost
        var panelThick = tendrilTipWidth + widthBoost
        var waistThick = Math.max(0.65, Math.min(rootThick, panelThick) * 0.45)
        var slots = []

        for (var j = 0; j < count; ++j) {
            var distributed = count <= 1 ? 0.5 : j / (count - 1)
            var seed = j + entries.length * 17.0
            var tipAlong = occupiedStart + distributed * occupiedSpan
            tipAlong += (tendrilHash(seed) - 0.5) * 2.0 * tendrilJitter
            tipAlong = Math.max(organismStart, Math.min(organismEnd, tipAlong))

            var rootAlong = tipAlong + (tendrilHash(seed + 31.7) - 0.5) * 2.0 * tendrilReach
            rootAlong = Math.max(organismStart, Math.min(organismEnd, rootAlong))

            var tipX = firstNodeCenter.x
            var tipY = firstNodeCenter.y
            var rootX = tipX
            var rootY = tipY

            if (vertical) {
                tipY += tipAlong
                rootY += rootAlong
                rootX = edge === "left" ? Theme.borderThickness : width - Theme.borderThickness
            } else {
                tipX += tipAlong
                rootX += rootAlong
                rootY = edge === "top" ? Theme.borderThickness : height - Theme.borderThickness
            }

            slots.push({
                active: true,
                isExtra: true,
                activation: reveal,
                rootX: rootX,
                rootY: rootY,
                tipX: tipX,
                tipY: tipY,
                rootThick: rootThick,
                waistThick: waistThick,
                panelThick: panelThick,
                maxLength: 100000,
                length: Math.sqrt((tipX - rootX) * (tipX - rootX) + (tipY - rootY) * (tipY - rootY)),
                tension: 0.0,
                side: edge
            })
        }
        return slots
    }

    readonly property var tendrilSlots: buildTendrilSlots()

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
        resetLiquidDynamics(liquidTarget)
    }
    onEnabledChanged: if (!enabled) cancelReveal()
    onEdgeChanged: cancelReveal()

    Timer {
        id: hideTimer
        interval: 900
        onTriggered: if (!root.surfaceHovered && !root.edgeHovered && !root.sharedHotZoneHovered) root.engaged = false
    }

    // The wake zone remains on the physical screen edge even when dockInset
    // moves the indicator farther into the display.
    Item {
        id: hotZone
        x: root.vertical ? (root.edge === "left" ? 0 : root.width - width) : (root.width - width) / 2
        y: root.vertical ? (root.height - height) / 2 : (root.edge === "top" ? 0 : root.height - height)
        width: root.vertical ? Math.max(8, Theme.borderThickness) : root.surfaceWidth
        height: root.vertical ? root.surfaceHeight : Math.max(8, Theme.borderThickness)
        HoverHandler { blocking: false; onHoveredChanged: root.edgeHovered = hovered }
    }

    // Interaction/text only. The organism itself is rendered by Border.frag.
    Item {
        id: surface
        width: root.surfaceWidth
        height: root.surfaceHeight
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
            }
        }
    }
}
