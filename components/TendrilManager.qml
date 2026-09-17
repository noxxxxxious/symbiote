import QtQuick
import "."

QtObject {
    id: manager

    required property Item panel

    property bool enabled: true
    property bool prevEnabled: false
    property int debugCounter: 0
    // Rotate the evenly spaced perimeter samples between activation cycles.
    // A fixed half-step places a repeatable surplus on one side for many panel
    // aspect ratios (especially the launcher/settings dimensions).
    property real perimeterPhase: Math.random()

    property real screenWidth: 0
    property real screenHeight: 0
    property var slots: []

    // Managers used to allocate 200 slots and tick forever while enabled. Keep
    // the same tendril simulation, but make it event-driven once it settles.
    readonly property int maxSlots: panel
        ? (panel.tendrilSlotCapacityOverride ?? Theme.tendrilMaxSlots)
        : 0
    property bool fading: false
    property bool needsUpdate: true
    property bool geometryDirty: true

    // Kept for compatibility with existing panels such as PowerCard. All managers
    // now sleep when settled; this flag no longer has to opt a panel into sleeping.
    readonly property bool staticGeometry: panel ? (panel.tendrilStaticGeometry ?? false) : false

    function markDirty() {
        geometryDirty = true
        needsUpdate = true
    }

    // Any geometry/profile change wakes the manager. Unknown handlers are ignored
    // so one manager can cover every panel type without panel-specific subclasses.
    property Connections geometryChanges: Connections {
        target: manager.panel
        ignoreUnknownSignals: true

        function onXChanged() { manager.markDirty() }
        function onYChanged() { manager.markDirty() }
        function onWidthChanged() { manager.markDirty() }
        function onHeightChanged() { manager.markDirty() }
        function onPanelCornerRoundingChanged() { manager.markDirty() }
        function onCornerRoundingChanged() { manager.markDirty() }

        function onTendrilsPer100pxChanged() { manager.markDirty() }
        function onTendrilMaxActiveChanged() { manager.markDirty() }
        function onTendrilMaxTopChanged() { manager.markDirty() }
        function onTendrilMaxRightChanged() { manager.markDirty() }
        function onTendrilMaxBottomChanged() { manager.markDirty() }
        function onTendrilMaxLeftChanged() { manager.markDirty() }
        function onTendrilMaxCornersChanged() { manager.markDirty() }
        function onTendrilAttachOffsetChanged() { manager.markDirty() }
        function onTendrilUseScreenRelativeAttachDistanceChanged() { manager.markDirty() }
        function onTendrilMaxLengthRangeOverrideChanged() { manager.markDirty() }
        function onTendrilRootThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilWaistThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilPanelThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilGrowSpeedOverrideChanged() { manager.markDirty() }
        function onTendrilShrinkSpeedOverrideChanged() { manager.markDirty() }
        function onTendrilRerollKeyChanged() {
            manager.perimeterPhase = Math.random()
            manager.initSlots()
            manager.markDirty()
        }

        function onTendrilExtraConnectionsChanged() { manager.markDirty() }
        function onTendrilExtraCountChanged() { manager.markDirty() }
        function onTendrilExtraReachChanged() { manager.markDirty() }
        function onTendrilExtraRootSpreadChanged() { manager.markDirty() }
        function onTendrilExtraPanelSpreadChanged() { manager.markDirty() }
        function onTendrilExtraTipSpreadChanged() { manager.markDirty() }
        function onTendrilExtraVerticalCountChanged() { manager.markDirty() }
        function onTendrilExtraHorizontalCountChanged() { manager.markDirty() }
        function onTendrilExtraVerticalReachChanged() { manager.markDirty() }
        function onTendrilExtraHorizontalReachChanged() { manager.markDirty() }
        function onTendrilExtraVerticalReachSpreadChanged() { manager.markDirty() }
        function onTendrilExtraHorizontalReachSpreadChanged() { manager.markDirty() }
        function onTendrilExtraVerticalTipSpreadChanged() { manager.markDirty() }
        function onTendrilExtraHorizontalTipSpreadChanged() { manager.markDirty() }
        function onTendrilExtraMaxLengthRangeOverrideChanged() { manager.markDirty() }
        function onTendrilExtraRootThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilExtraWaistThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilExtraPanelThicknessRangeOverrideChanged() { manager.markDirty() }
        function onTendrilExtraGrowSpeedOverrideChanged() { manager.markDirty() }
        function onTendrilExtraShrinkSpeedOverrideChanged() { manager.markDirty() }
    }

    property Connections themeChanges: Connections {
        target: Theme
        function onBorderThicknessChanged() { manager.markDirty() }
        function onBorderRoundingChanged() { manager.markDirty() }
        function onTendrilsPer100pxChanged() { manager.markDirty() }
        function onTendrilMaxLengthRangeChanged() { manager.markDirty() }
        function onTendrilRootThicknessRangeChanged() { manager.markDirty() }
        function onTendrilWaistThicknessRangeChanged() { manager.markDirty() }
        function onTendrilPanelThicknessRangeChanged() { manager.markDirty() }
        function onTendrilAttachDistanceChanged() { manager.markDirty() }
        function onTendrilGrowSpeedChanged() { manager.markDirty() }
        function onTendrilShrinkSpeedChanged() { manager.markDirty() }
        function onTendrilJitterChanged() { manager.markDirty() }
    }

    onScreenWidthChanged: markDirty()
    onScreenHeightChanged: markDirty()

    readonly property int maxActive:
        panel && panel.tendrilMaxActive !== undefined && panel.tendrilMaxActive > 0
        ? panel.tendrilMaxActive
        : Theme.tendrilMaxActivePerPanel

    readonly property real panelCornerRounding:
        !panel
        ? Theme.borderRounding
        : (panel.panelCornerRounding !== undefined
           ? panel.panelCornerRounding
           : (panel.cornerRounding !== undefined
              ? panel.cornerRounding
              : Theme.borderRounding))

    function panelAlive() {
        return enabled && panel !== null
    }

    function growSpeed() {
        return panel && panel.tendrilGrowSpeedOverride !== undefined
            ? panel.tendrilGrowSpeedOverride
            : Theme.tendrilGrowSpeed
    }

    function shrinkSpeed() {
        return panel && panel.tendrilShrinkSpeedOverride !== undefined
            ? panel.tendrilShrinkSpeedOverride
            : Theme.tendrilShrinkSpeed
    }

    function randRange(r) {
        return r.x + Math.random() * (r.y - r.x);
    }

    function initSlots() {
        var arr = [];

        for (var i = 0; i < maxSlots; i++) {
            arr.push({
                active: false,
                isExtra: false,
                extraIndex: -1,

                activation: 0.0,

                rootX: 0,
                rootY: 0,
                tipX: 0,
                tipY: 0,

                rootThick: 0,
                waistThick: 0,
                panelThick: 0,

                maxLength: 0,
                length: 0,
                tension: 0,

                perimeterIndex: -1,
                breakTipX: 0,
                breakTipY: 0,

                ux: 0,
                uy: 0,
                dirX: 0,
                dirY: 0,
                side: "top"
            });
        }

        slots = arr;
    }

    Component.onCompleted: {
        initSlots()
        prevEnabled = enabled
        markDirty()
    }

    onPanelChanged: {
        perimeterPhase = Math.random()
        initSlots()
        fading = false
        prevEnabled = enabled
        markDirty()
    }

    onMaxSlotsChanged: {
        // Capacity changes are rare configuration events; rebuild once rather than
        // carrying a large dormant pool for the lifetime of the shell.
        initSlots()
        markDirty()
    }

    onEnabledChanged: {
        markDirty()
        if (enabled && !prevEnabled) {
            perimeterPhase = Math.random()
            initSlots()
        }

        if (!enabled)
            fading = slots.some(function(slot) { return slot.activation > 0.001 })
        prevEnabled = enabled
    }

    function buildSegments(w, h, r) {
        var flatW = Math.max(w - 2 * r, 0);
        var flatH = Math.max(h - 2 * r, 0);
        var arcLen = Math.PI * 0.5 * r;

        return [
            { type: "arc", side: "corner-tl", cx: r, cy: r,
              a0: Math.PI, a1: 1.5 * Math.PI, len: arcLen },

            { type: "flat", side: "top",
              x0: r, y0: 0, x1: w - r, y1: 0,
              nx: 0, ny: -1, len: flatW },

            { type: "arc", side: "corner-tr", cx: w - r, cy: r,
              a0: 1.5 * Math.PI, a1: 2 * Math.PI, len: arcLen },

            { type: "flat", side: "right",
              x0: w, y0: r, x1: w, y1: h - r,
              nx: 1, ny: 0, len: flatH },

            { type: "arc", side: "corner-br", cx: w - r, cy: h - r,
              a0: 0, a1: 0.5 * Math.PI, len: arcLen },

            { type: "flat", side: "bottom",
              x0: w - r, y0: h, x1: r, y1: h,
              nx: 0, ny: 1, len: flatW },

            { type: "arc", side: "corner-bl", cx: r, cy: h - r,
              a0: 0.5 * Math.PI, a1: Math.PI, len: arcLen },

            { type: "flat", side: "left",
              x0: 0, y0: h - r, x1: 0, y1: r,
              nx: -1, ny: 0, len: flatH }
        ];
    }

    function perimeterLength(segs) {
        var total = 0;

        for (var i = 0; i < segs.length; i++)
            total += segs[i].len;

        return total > 0 ? total : 1;
    }

    function computePoints(count) {
        var w = Math.max(panel.width, 1);
        var h = Math.max(panel.height, 1);
        var r = Math.max(
            0,
            Math.min(panelCornerRounding, Math.min(w, h) * 0.5)
        );

        var segs = buildSegments(w, h, r);
        var total = perimeterLength(segs);
        var pts = [];

        for (var i = 0; i < count; i++) {
                var distance = (i + manager.perimeterPhase) / count * total;
            var acc = 0;
            var found = null;

            for (var j = 0; j < segs.length; j++) {
                var seg = segs[j];

                if (distance > acc + seg.len) {
                    acc += seg.len;
                    continue;
                }

                var t = seg.len > 0
                    ? (distance - acc) / seg.len
                    : 0;

                t = Math.max(0, Math.min(1, t));

                if (seg.type === "flat") {
                    found = {
                        ux: (seg.x0 + (seg.x1 - seg.x0) * t) / w,
                        uy: (seg.y0 + (seg.y1 - seg.y0) * t) / h,
                        dx: seg.nx,
                        dy: seg.ny,
                        side: seg.side
                    };
                } else {
                    var angle = seg.a0 + (seg.a1 - seg.a0) * t;
                    var nx = Math.cos(angle);
                    var ny = Math.sin(angle);

                    found = {
                        ux: (seg.cx + r * nx) / w,
                        uy: (seg.cy + r * ny) / h,
                        dx: nx,
                        dy: ny,
                        side: seg.side
                    };
                }

                break;
            }

            pts.push(found || {
                ux: 0.5,
                uy: 0,
                dx: 0,
                dy: -1,
                side: "top"
            });
        }

        return pts;
    }

    function desiredPointCount() {
        if (panel.tendrilsPer100px === 0) return 0;
        var w = Math.max(panel.width, 1);
        var h = Math.max(panel.height, 1);
        var r = Math.max(
            0,
            Math.min(panelCornerRounding, Math.min(w, h) * 0.5)
        );

        var total = perimeterLength(
            buildSegments(w, h, r)
        );

        var density = panel.tendrilsPer100px > 0
            ? panel.tendrilsPer100px
            : Theme.tendrilsPer100px;

        var raw = total / 100.0 * density;
        var count = Math.max(1, Math.ceil(raw));

        return Math.min(
            Math.ceil(count * 2.0),
            Theme.tendrilMaxPerimeterPoints
        );
    }

    function anchorFor(pt) {
        return {
            x: panel.x + pt.ux * Math.max(panel.width, 1),
            y: panel.y + pt.uy * Math.max(panel.height, 1)
        };
    }

    function raycastToBorder(ox, oy, dx, dy, minX, minY, maxX, maxY) {
        var bestT = Infinity;
        var edge = "top";

        if (dx > 1e-6) {
            var tx = (maxX - ox) / dx;
            if (tx >= 0 && tx < bestT) {
                bestT = tx;
                edge = "right";
            }
        } else if (dx < -1e-6) {
            var tx2 = (minX - ox) / dx;
            if (tx2 >= 0 && tx2 < bestT) {
                bestT = tx2;
                edge = "left";
            }
        }

        if (dy > 1e-6) {
            var ty = (maxY - oy) / dy;
            if (ty >= 0 && ty < bestT) {
                bestT = ty;
                edge = "bottom";
            }
        } else if (dy < -1e-6) {
            var ty2 = (minY - oy) / dy;
            if (ty2 >= 0 && ty2 < bestT) {
                bestT = ty2;
                edge = "top";
            }
        }

        if (!isFinite(bestT) || bestT < 0)
            bestT = 0;

        return {
            x: ox + dx * bestT,
            y: oy + dy * bestT,
            edge: edge,
            dist: bestT
        };
    }

    function normalMaxLengthRange() {
        return panel.tendrilMaxLengthRangeOverride
            && panel.tendrilMaxLengthRangeOverride.x !== 0
            ? panel.tendrilMaxLengthRangeOverride
            : Theme.tendrilMaxLengthRange;
    }

    function normalRootThicknessRange() {
        return panel.tendrilRootThicknessRangeOverride
            && panel.tendrilRootThicknessRangeOverride.x !== 0
            ? panel.tendrilRootThicknessRangeOverride
            : Theme.tendrilRootThicknessRange;
    }

    function normalPanelThicknessRange() {
        return panel.tendrilPanelThicknessRangeOverride
            && panel.tendrilPanelThicknessRangeOverride.x !== 0
            ? panel.tendrilPanelThicknessRangeOverride
            : Theme.tendrilPanelThicknessRange;
    }

    function normalWaistThicknessRange() {
        return panel.tendrilWaistThicknessRangeOverride
            && panel.tendrilWaistThicknessRangeOverride.x !== 0
            ? panel.tendrilWaistThicknessRangeOverride
            : Theme.tendrilWaistThicknessRange;
    }

    function respawnSlot(slot, perimeterIndex, pt, minX, minY, maxX, maxY) {
        var anchor = anchorFor(pt);

        var hit = raycastToBorder(
            anchor.x,
            anchor.y,
            pt.dx,
            pt.dy,
            minX,
            minY,
            maxX,
            maxY
        );

        var jitter = (Math.random() * 2.0 - 1.0) * Theme.tendrilJitter;

        var rootX = hit.x;
        var rootY = hit.y;

        if (hit.edge === "top" || hit.edge === "bottom")
            rootX += jitter;
        else
            rootY += jitter;

        slot.isExtra = false;
        slot.extraIndex = -1;
        slot.perimeterIndex = perimeterIndex;
        slot.side = pt.side;
        slot.ux = pt.ux;
        slot.uy = pt.uy;
        slot.dirX = pt.dx;
        slot.dirY = pt.dy;

        slot.rootX = rootX;
        slot.rootY = rootY;
        slot.tipX = anchor.x;
        slot.tipY = anchor.y;
        slot.breakTipX = anchor.x;
        slot.breakTipY = anchor.y;

        slot.rootThick = randRange(normalRootThicknessRange());
        slot.panelThick = randRange(normalPanelThicknessRange());
        slot.waistThick = randRange(normalWaistThicknessRange());
        slot.maxLength = randRange(normalMaxLengthRange());

        slot.active = true;
    }

    function extraConnectionsEnabled() {
        return panel.tendrilExtraConnections === true;
    }

    function extraSpecs() {
        if (!extraConnectionsEnabled()
                || typeof panel.extraTendrilSpecs !== "function") {
            return [];
        }

        return panel.extraTendrilSpecs();
    }

    function extraMaxLengthRange() {
        if (panel.tendrilExtraMaxLengthRangeOverride
                && panel.tendrilExtraMaxLengthRangeOverride.x !== 0) {
            return panel.tendrilExtraMaxLengthRangeOverride;
        }

        var diagonal = Math.sqrt(
            screenWidth * screenWidth
            + screenHeight * screenHeight
        );

        return Qt.vector2d(diagonal * 0.55, diagonal * 1.10);
    }

    function extraRootThicknessRange() {
        return panel.tendrilExtraRootThicknessRangeOverride
            && panel.tendrilExtraRootThicknessRangeOverride.x !== 0
            ? panel.tendrilExtraRootThicknessRangeOverride
            : Qt.vector2d(4, 9);
    }

    function extraWaistThicknessRange() {
        return panel.tendrilExtraWaistThicknessRangeOverride
            && panel.tendrilExtraWaistThicknessRangeOverride.x !== 0
            ? panel.tendrilExtraWaistThicknessRangeOverride
            : Qt.vector2d(1, 2);
    }

    function extraPanelThicknessRange() {
        return panel.tendrilExtraPanelThicknessRangeOverride
            && panel.tendrilExtraPanelThicknessRangeOverride.x !== 0
            ? panel.tendrilExtraPanelThicknessRangeOverride
            : Qt.vector2d(2, 4);
    }

    function respawnExtraSlot(slot, spec, extraIndex) {
        slot.isExtra = true;
        slot.extraIndex = extraIndex;
        slot.perimeterIndex = -1;
        slot.side = spec.side || "extra";

        slot.rootX = spec.rootX;
        slot.rootY = spec.rootY;
        slot.tipX = spec.tipX;
        slot.tipY = spec.tipY;
        slot.breakTipX = spec.tipX;
        slot.breakTipY = spec.tipY;

        var rootRange = spec.rootThicknessRange || extraRootThicknessRange();
        var waistRange = spec.waistThicknessRange || extraWaistThicknessRange();
        var panelRange = spec.panelThicknessRange || extraPanelThicknessRange();
        var lengthRange = spec.maxLengthRange || extraMaxLengthRange();

        slot.rootThick = randRange(rootRange);
        slot.waistThick = randRange(waistRange);
        slot.panelThick = randRange(panelRange);
        slot.maxLength = randRange(lengthRange);

        slot.active = true;
    }

    function updateExtraSlots(current) {
        var specs = extraSpecs();

        for (var i = 0; i < current.length; i++) {
            var slot = current[i];

            if (!slot.isExtra)
                continue;

            var spec = specs[slot.extraIndex];

            if (!spec) {
                slot.active = false;
                continue;
            }

            slot.rootX = spec.rootX;
            slot.rootY = spec.rootY;
            slot.tipX = spec.tipX;
            slot.tipY = spec.tipY;
        }

        if (!extraConnectionsEnabled())
            return;

        for (var s = 0; s < specs.length; s++) {
            var alreadyPresent = false;

            for (var j = 0; j < current.length; j++) {
                if (current[j].isExtra
                        && current[j].extraIndex === s
                        && current[j].active) {
                    alreadyPresent = true;
                    break;
                }
            }

            if (alreadyPresent)
                continue;

            var free = -1;

            for (var k = 0; k < current.length; k++) {
                if (!current[k].active && !current[k].isExtra) {
                    free = k;
                    break;
                }
            }

            if (free < 0)
                continue;

            respawnExtraSlot(current[free], specs[s], s);
            current[free].activation = 0.02;
        }
    }

    function sideKey(side) {
        return side.indexOf("corner-") === 0 ? "corners" : side;
    }

    function sideMax(side) {
        var p = panel;

        switch (side) {
        case "top":
            return p.tendrilMaxTop ?? Theme.tendrilMaxTop;
        case "right":
            return p.tendrilMaxRight ?? Theme.tendrilMaxRight;
        case "bottom":
            return p.tendrilMaxBottom ?? Theme.tendrilMaxBottom;
        case "left":
            return p.tendrilMaxLeft ?? Theme.tendrilMaxLeft;
        default:
            return p.tendrilMaxCorners ?? Theme.tendrilMaxCorners;
        }
    }

    function effectiveAttachDistance() {
        if (panel.tendrilUseScreenRelativeAttachDistance)
            return Math.max(
                Theme.tendrilAttachDistance,
                screenWidth * 0.5 - panel.tendrilAttachOffset
            );

        return Theme.tendrilAttachDistance;
    }

    function tick() {
        var current = slots || []

        if (!panel && !fading) {
            needsUpdate = false
            geometryDirty = false
            return
        }

        // Keep one follow-up tick after the most recent geometry/config change.
        // This prevents a moving panel from repeatedly stopping/restarting its timer
        // between animation frames, while still allowing a fully settled panel to sleep.
        var consumedDirty = geometryDirty
        geometryDirty = false

        var gSpeed = growSpeed()
        var sSpeed = shrinkSpeed()

        if (!panelAlive()) {
            var changed = false;
            var stillFading = false;
            for (var d = 0; d < current.length; d++) {
                var dead = current[d];

                dead.active = false;

                if (dead.activation > 0.001) {
                    changed = true;
                    dead.tipX = dead.rootX
                              + (dead.breakTipX - dead.rootX)
                              * dead.activation;
                    dead.tipY = dead.rootY
                              + (dead.breakTipY - dead.rootY)
                              * dead.activation;
                    dead.activation += (0.0 - dead.activation) * sSpeed;
                    if (dead.activation <= 0.001) {
                        dead.activation = 0;
                        dead.isExtra = false;
                    } else stillFading = true;
                }
            }

            if (changed) slots = current.concat()
            fading = stillFading
            needsUpdate = false
            return
        }

        var minX = Theme.borderThickness;
        var minY = Theme.borderThickness;
        var maxX = Math.max(screenWidth - Theme.borderThickness, minX + 1);
        var maxY = Math.max(screenHeight - Theme.borderThickness, minY + 1);

        updateExtraSlots(current);

        var pointCount = desiredPointCount();
        var points = computePoints(pointCount);

        var inRange = [];
        for (var pi = 0; pi < points.length; pi++) {
            var anchor = anchorFor(points[pi]);
            var hit = raycastToBorder(
                anchor.x,
                anchor.y,
                points[pi].dx,
                points[pi].dy,
                minX,
                minY,
                maxX,
                maxY
            );

            if (hit.dist <= effectiveAttachDistance())
                inRange.push(pi);
        }

        var desiredActive = Math.min(maxActive, inRange.length);
        var active = 0;
        var sideCounts = {
            top: 0,
            right: 0,
            bottom: 0,
            left: 0,
            corners: 0
        };

        // Pass 1: update normal slots and count active ones.
        for (var i = 0; i < current.length; i++) {
            var slot = current[i];

            if (!slot.active)
                continue;

            if (slot.isExtra)
                continue;

            slot.tipX = panel.x
                      + slot.ux * Math.max(panel.width, 1);
            slot.tipY = panel.y
                      + slot.uy * Math.max(panel.height, 1);

            var dx = slot.tipX - slot.rootX;
            var dy = slot.tipY - slot.rootY;
            var length = Math.sqrt(dx * dx + dy * dy);

            slot.length = length;
            slot.tension = Math.min(
                1.0,
                Math.max(0.0, length / Math.max(slot.maxLength, 1.0))
            );

            if (length > slot.maxLength) {
                slot.active = false;
                slot.breakTipX = slot.tipX;
                slot.breakTipY = slot.tipY;
            } else {
                active++;

                var key = sideKey(slot.side);
                sideCounts[key] = (sideCounts[key] || 0) + 1;
            }
        }

        // Extra slots are not part of normal perimeter caps.
        for (var ex = 0; ex < current.length; ex++) {
            var extra = current[ex];

            if (!extra.isExtra || !extra.active)
                continue;

            var extraDx = extra.tipX - extra.rootX;
            var extraDy = extra.tipY - extra.rootY;
            var extraLength = Math.sqrt(
                extraDx * extraDx
                + extraDy * extraDy
            );

            extra.length = extraLength;
            extra.tension = Math.min(
                1.0,
                Math.max(
                    0.0,
                    extraLength / Math.max(extra.maxLength, 1.0)
                )
            );

            if (extraLength > extra.maxLength) {
                extra.active = false;
                extra.breakTipX = extra.tipX;
                extra.breakTipY = extra.tipY;
            }
        }

        function pickSpawnCandidate() {
            var used = {};

            for (var j = 0; j < current.length; j++) {
                if (current[j].active
                        && !current[j].isExtra
                        && current[j].perimeterIndex >= 0) {
                    used[current[j].perimeterIndex] = true;
                }
            }

            var cornerCandidates = [];

            for (var k = 0; k < inRange.length; k++) {
                var idx = inRange[k];

                if (used[idx])
                    continue;

                var pt = points[idx];
                var key = sideKey(pt.side);

                if (key !== "corners")
                    continue;

                if (sideCounts.corners >= sideMax(pt.side))
                    continue;

                cornerCandidates.push(idx);
            }

            if (cornerCandidates.length > 0) {
                return cornerCandidates[
                    Math.floor(Math.random() * cornerCandidates.length)
                ];
            }

            var bySide = {
                top: [],
                right: [],
                bottom: [],
                left: []
            };

            for (var k2 = 0; k2 < inRange.length; k2++) {
                var idx2 = inRange[k2];

                if (used[idx2])
                    continue;

                var pt2 = points[idx2];
                var key2 = sideKey(pt2.side);

                if (key2 === "corners")
                    continue;

                if (sideCounts[key2] >= sideMax(pt2.side))
                    continue;

                bySide[key2].push(idx2);
            }

            var bestSide = null;
            var bestRatio = Infinity;

            for (var sideName in bySide) {
                if (bySide[sideName].length === 0)
                    continue;

                var cap = Math.max(sideMax(sideName), 1);
                var ratio = (sideCounts[sideName] || 0) / cap;

                if (ratio < bestRatio) {
                    bestRatio = ratio;
                    bestSide = sideName;
                }
            }

            if (bestSide === null)
                return -1;

            var list = bySide[bestSide];
            return list[Math.floor(Math.random() * list.length)];
        }

        // Pass 2: spawn normal slots and update activation.
        for (var i2 = 0; i2 < current.length; i2++) {
            var slot2 = current[i2];

            if (slot2.isExtra)
                continue;

            if (!slot2.active) {
                if (active < desiredActive) {
                    var freeIdx = pickSpawnCandidate();

                    if (freeIdx >= 0) {
                        slot2.activation = 0.02;
                        active++;
                        var candidatePt = points[freeIdx];
                        respawnSlot(
                            slot2,
                            freeIdx,
                            candidatePt,
                            minX,
                            minY,
                            maxX,
                            maxY
                        );

                        sideCounts[sideKey(candidatePt.side)]++;
                    }
                }
            }

            var target = slot2.active ? 1.0 : 0.0;
            var speed = target > slot2.activation ? gSpeed : sSpeed;
            slot2.activation += (target - slot2.activation) * speed;
        }

        // Extra slots get their own animation profile if provided.
        for (var e = 0; e < current.length; e++) {
            var extraSlot = current[e];

            if (!extraSlot.isExtra)
                continue;

            var extraTarget = extraSlot.active ? 1.0 : 0.0;
            var extraGrow = panel.tendrilExtraGrowSpeedOverride !== undefined
                ? panel.tendrilExtraGrowSpeedOverride
                : gSpeed;
            var extraShrink = panel.tendrilExtraShrinkSpeedOverride !== undefined
                ? panel.tendrilExtraShrinkSpeedOverride
                : sSpeed;

            var extraSpeed = extraTarget > extraSlot.activation
                ? extraGrow
                : extraShrink;

            extraSlot.activation += (
                extraTarget - extraSlot.activation
            ) * extraSpeed;
        }

        // Once every active/inactive slot has reached its target activation and
        // geometry has gone quiet, there is nothing left to simulate. Clamp the
        // last tiny exponential tail so the timer can shut down completely.
        var unsettled = false
        for (var st = 0; st < current.length; ++st) {
            var settledSlot = current[st]
            if (settledSlot.active && settledSlot.activation >= 0.999) {
                settledSlot.activation = 1
            } else if (!settledSlot.active && settledSlot.activation <= 0.001) {
                settledSlot.activation = 0
                if (settledSlot.isExtra && !settledSlot.active)
                    settledSlot.isExtra = false
            } else {
                unsettled = true
            }
        }

        slots = current.concat()
        fading = false
        needsUpdate = unsettled || geometryDirty || consumedDirty
    }

    property Timer timer: Timer {
        interval: panel && panel.tendrilUpdateIntervalOverride !== undefined
            ? panel.tendrilUpdateIntervalOverride
            : 33
        running: manager.fading || (manager.panel && manager.enabled && manager.needsUpdate)
        repeat: true
        onTriggered: manager.tick()
    }
}
