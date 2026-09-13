import QtQuick
import "." // required even though Theme.qml is in this same dir - see qmldir

QtObject {
    id: manager

    required property Item panel

    property bool enabled: true

    property bool _prevEnabled: false

    // property int _debugCounter: 0

    Component.onCompleted: _prevEnabled = enabled

    onEnabledChanged: {
        if (enabled && !_prevEnabled) {
            slots = initSlots();
        }
        _prevEnabled = enabled;
    }

    property real screenWidth: 0
    property real screenHeight: 0

    property var slots: initSlots()

    readonly property int maxSlots: Theme.tendrilMaxSlots
    property int maxActive: panel.tendrilMaxActive > 0
                         ? panel.tendrilMaxActive
                         : Theme.tendrilMaxActivePerPanel

    readonly property real panelCornerRounding:
            panel.cornerRounding !== undefined
                ? panel.cornerRounding
                : Theme.borderRounding

    function panelAlive() {
        return enabled;
    }

    function growSpeed() {
        return (panel.tendrilGrowSpeedOverride !== undefined && panel.tendrilGrowSpeedOverride > 0)
                ? panel.tendrilGrowSpeedOverride
                : Theme.tendrilGrowSpeed;
    }

    function shrinkSpeed() {
        return (panel.tendrilShrinkSpeedOverride !== undefined && panel.tendrilShrinkSpeedOverride > 0)
                ? panel.tendrilShrinkSpeedOverride
                : Theme.tendrilShrinkSpeed;
    }

    function initSlots() {
        var arr = [];
        for (var i = 0; i < maxSlots; i++) {
            arr.push({
                active: false,
                activation: 0.0,
                rootX: 0, rootY: 0,
                tipX: 0, tipY: 0,
                rootThick: 0, waistThick: 0, panelThick: 0,
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
        return arr;
    }

    function randRange(r) {
        return r.x + Math.random() * (r.y - r.x);
    }

    function raycastToBorder(ox, oy, dx, dy, minX, minY, maxX, maxY) {
        var bestT = Infinity;
        var edge = "top";

        if (dx > 1e-6) {
            var tx = (maxX - ox) / dx;
            if (tx < bestT) { bestT = tx; edge = "right"; }
        } else if (dx < -1e-6) {
            var tx2 = (minX - ox) / dx;
            if (tx2 < bestT) { bestT = tx2; edge = "left"; }
        }

        if (dy > 1e-6) {
            var ty = (maxY - oy) / dy;
            if (ty < bestT) { bestT = ty; edge = "bottom"; }
        } else if (dy < -1e-6) {
            var ty2 = (minY - oy) / dy;
            if (ty2 < bestT) { bestT = ty2; edge = "top"; }
        }

        if (!isFinite(bestT) || bestT < 0)
            bestT = 0;

        return { x: ox + dx * bestT, y: oy + dy * bestT, edge: edge, dist: bestT };
    }

    function buildSegments(w, h, r) {
        var flatW = Math.max(w - 2 * r, 0);
        var flatH = Math.max(h - 2 * r, 0);
        var arcLen = (Math.PI / 2) * r;

        return [
            { type: "arc",  side: "corner-tl", cx: r,     cy: r,     a0: Math.PI, a1: 1.5 * Math.PI, len: arcLen },
            { type: "flat", side: "top",       x0: r,     y0: 0,     x1: w - r,   y1: 0,  nx: 0,  ny: -1,    len: flatW },
            { type: "arc",  side: "corner-tr", cx: w - r, cy: r,     a0: 1.5 * Math.PI, a1: 2 * Math.PI,   len: arcLen },
            { type: "flat", side: "right",     x0: w,     y0: r,     x1: w,     y1: h - r, nx: 1, ny: 0,   len: flatH },
            { type: "arc",  side: "corner-br", cx: w - r, cy: h - r, a0: 0,     a1: 0.5 * Math.PI,         len: arcLen },
            { type: "flat", side: "bottom",    x0: w - r, y0: h,     x1: r,     y1: h, nx: 0, ny: 1,       len: flatW },
            { type: "arc",  side: "corner-bl", cx: r,     cy: h - r, a0: 0.5 * Math.PI, a1: Math.PI,       len: arcLen },
            { type: "flat", side: "left",      x0: 0,     y0: h - r, x1: 0,     y1: r, nx: -1, ny: 0,      len: flatH }
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
        var r = Math.max(0, Math.min(panelCornerRounding, Math.min(w, h) / 2));
        var segs = buildSegments(w, h, r);
        var total = perimeterLength(segs);

        var pts = [];

        for (var ci = 0; ci < segs.length; ci++) {
            var seg = segs[ci];
            if (seg.type !== "arc" || r <= 0)
                continue;
            var midAng = (seg.a0 + seg.a1) / 2;
            var nx = Math.cos(midAng);
            var ny = Math.sin(midAng);
            pts.push({
                ux: (seg.cx + r * nx) / w,
                uy: (seg.cy + r * ny) / h,
                dx: nx,
                dy: ny,
                side: seg.side
            });
        }

        for (var i = 0; i < count; i++) {
            var s = (i + 0.5) / count * total;
            var acc = 0;
            var found = null;

            for (var j = 0; j < segs.length; j++) {
                var seg2 = segs[j];
                if (s <= acc + seg2.len || j === segs.length - 1) {
                    var t = seg2.len > 0 ? (s - acc) / seg2.len : 0;
                    t = Math.max(0, Math.min(1, t));

                    if (seg2.type === "flat") {
                        found = {
                            ux: (seg2.x0 + (seg2.x1 - seg2.x0) * t) / w,
                            uy: (seg2.y0 + (seg2.y1 - seg2.y0) * t) / h,
                            dx: seg2.nx,
                            dy: seg2.ny,
                            side: seg2.side
                        };
                    } else {
                        var ang = seg2.a0 + (seg2.a1 - seg2.a0) * t;
                        var nx2 = Math.cos(ang);
                        var ny2 = Math.sin(ang);
                        found = {
                            ux: (seg2.cx + r * nx2) / w,
                            uy: (seg2.cy + r * ny2) / h,
                            dx: nx2,
                            dy: ny2,
                            side: seg2.side
                        };
                    }
                    break;
                }
                acc += seg2.len;
            }

            pts.push(found || { ux: 0.5, uy: 0, dx: 0, dy: -1, side: "top" });
        }
        return pts;
    }

    function desiredPointCount() {
        var w = Math.max(panel.width, 1);
        var h = Math.max(panel.height, 1);
        var r = Math.max(0, Math.min(panelCornerRounding, Math.min(w, h) / 2));
        var segs = buildSegments(w, h, r);
        var total = perimeterLength(segs);

        var density = panel.tendrilsPer100px > 0
                ? panel.tendrilsPer100px
                : Theme.tendrilsPer100px;

        var raw = (total / 100.0) * density;
        var count = Math.max(1, Math.ceil(raw));

        var oversampleFactor = 2.0;
        count = Math.min(Math.ceil(count * oversampleFactor),
                         Theme.tendrilMaxPerimeterPoints);

        return count;
    }

    function anchorFor(pt) {
        var w = Math.max(panel.width, 1);
        var h = Math.max(panel.height, 1);
        return { x: panel.x + pt.ux * w, y: panel.y + pt.uy * h };
    }

    function respawnSlot(slot, perimeterIndex, pt, minX, minY, maxX, maxY) {
        var a = anchorFor(pt);
        var hit = raycastToBorder(a.x, a.y, pt.dx, pt.dy, minX, minY, maxX, maxY);

        var jitter = (Math.random() * 2 - 1) * Theme.tendrilJitter;
        var rootX = hit.x;
        var rootY = hit.y;
        if (hit.edge === "top" || hit.edge === "bottom")
            rootX += jitter;
        else
            rootY += jitter;

        slot.perimeterIndex = perimeterIndex;
        slot.side = pt.side;

        slot.ux = pt.ux;
        slot.uy = pt.uy;
        slot.dirX = pt.dx;
        slot.dirY = pt.dy;

        slot.tipX = a.x;
        slot.tipY = a.y;
        slot.rootX = rootX;
        slot.rootY = rootY;
        slot.breakTipX = a.x;
        slot.breakTipY = a.y;

        var maxLenRange = panel.tendrilMaxLengthRangeOverride.x != 0
                ? panel.tendrilMaxLengthRangeOverride
                : Theme.tendrilMaxLengthRange;

        var rootRange = panel.tendrilRootThicknessRangeOverride && panel.tendrilRootThicknessRangeOverride.x > 0
                ? panel.tendrilRootThicknessRangeOverride
                : Theme.tendrilRootThicknessRange;
        var panelRange = panel.tendrilPanelThicknessRangeOverride && panel.tendrilPanelThicknessRangeOverride.x > 0
                ? panel.tendrilPanelThicknessRangeOverride
                : Theme.tendrilPanelThicknessRange;
        var waistRange = panel.tendrilWaistThicknessRangeOverride && panel.tendrilWaistThicknessRangeOverride.x > 0
                ? panel.tendrilWaistThicknessRangeOverride
                : Theme.tendrilWaistThicknessRange;

        slot.rootThick = randRange(rootRange);
        slot.panelThick = randRange(panelRange);
        slot.waistThick = randRange(waistRange);
        slot.maxLength = randRange(maxLenRange);
        slot.active = true;
    }

    function sideMax(side) {
        var p = panel;
        switch (side) {
        case "top":    return p.tendrilMaxTop    || Theme.tendrilMaxTop;
        case "right":  return p.tendrilMaxRight  || Theme.tendrilMaxRight;
        case "bottom": return p.tendrilMaxBottom || Theme.tendrilMaxBottom;
        case "left":   return p.tendrilMaxLeft   || Theme.tendrilMaxLeft;
        default:       return p.tendrilMaxCorners || Theme.tendrilMaxCorners;
        }
    }

    function effectiveAttachDistance() {
        if (panel.tendrilUseScreenRelativeAttachDistance) {
            return Math.max(
                Theme.tendrilAttachDistance,
                (screenWidth / 2) - (panel.tendrilAttachOffset || 50)
            );
        }
        return Theme.tendrilAttachDistance;
    }

    function sideKey(side) {
        return side && side.indexOf("corner-") === 0 ? "corners" : (side || "top");
    }

    function tick() {
        var current = slots;
        var gSpeed = growSpeed();
        var sSpeed = shrinkSpeed();

        if (!panelAlive()) {
            for (var di = 0; di < current.length; di++) {
                var dslot = current[di];
                dslot.active = false;

                if (dslot.activation > 0.001) {
                    dslot.tipX = dslot.rootX + (dslot.breakTipX - dslot.rootX) * dslot.activation;
                    dslot.tipY = dslot.rootY + (dslot.breakTipY - dslot.rootY) * dslot.activation;
                }

                dslot.activation += (0.0 - dslot.activation) * sSpeed;
            }

            slots = current.concat();
            return;
        }

        var minX = Theme.borderThickness;
        var minY = Theme.borderThickness;
        var maxX = Math.max(screenWidth - Theme.borderThickness, minX + 1);
        var maxY = Math.max(screenHeight - Theme.borderThickness, minY + 1);

        var attachDist = effectiveAttachDistance();

        var pointCount = desiredPointCount();
        var points = computePoints(pointCount);

        var inRange = [];
        for (var pi = 0; pi < points.length; pi++) {
            var a = anchorFor(points[pi]);
            var hit = raycastToBorder(a.x, a.y, points[pi].dx, points[pi].dy,
                                      minX, minY, maxX, maxY);
            if (hit.dist <= attachDist)
                inRange.push(pi);
        }

        var desiredActive = Math.min(maxActive, inRange.length);
        var active = 0;
        var sideCounts = { top: 0, right: 0, bottom: 0, left: 0, corners: 0 };

        // PASS 1: update every currently-active slot (recompute tip,
        // check for breaking) and build a COMPLETE, accurate sideCounts
        // tally across the ENTIRE slot array before any spawn decision
        // happens. This used to be interleaved with the spawn-decision
        // logic in a single combined loop, which meant a cap check for
        // side X only saw side-X slots at LOWER array indices than the
        // one currently being decided - any already-active side-X slots
        // sitting at higher indices hadn't been counted yet, so the cap
        // check could pass when it shouldn't have. That let some sides
        // silently overshoot their cap (eating shared budget), which
        // starved other sides that were correctly capped - producing a
        // persistent, session-to-session skew that had nothing to do with
        // geometry or randomness.
        for (var i = 0; i < current.length; i++) {
            var slot = current[i];
            if (!slot.active)
                continue;

            slot.tipX = panel.x + slot.ux * Math.max(panel.width, 1);
            slot.tipY = panel.y + slot.uy * Math.max(panel.height, 1);

            var dx = slot.tipX - slot.rootX;
            var dy = slot.tipY - slot.rootY;
            var length = Math.sqrt(dx * dx + dy * dy);

            slot.length = length;
            slot.tension = Math.min(1.0, Math.max(0.0, length / slot.maxLength));

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

        function pickSpawnCandidate() {
            var used = {};
            for (var j = 0; j < current.length; j++) {
                if (current[j].active)
                    used[current[j].perimeterIndex] = true;
            }

            var cornerCandidates = [];
            for (var k = 0; k < inRange.length; k++) {
                var idx = inRange[k];
                if (used[idx])
                    continue;
                var pt = points[idx];
                if (sideKey(pt.side) !== "corners")
                    continue;
                if ((sideCounts.corners || 0) >= sideMax(pt.side))
                    continue;
                cornerCandidates.push(idx);
            }

            if (cornerCandidates.length > 0)
                return cornerCandidates[Math.floor(Math.random() * cornerCandidates.length)];

            var bySide = { top: [], right: [], bottom: [], left: [] };
            for (var k2 = 0; k2 < inRange.length; k2++) {
                var idx2 = inRange[k2];
                if (used[idx2])
                    continue;
                var pt2 = points[idx2];
                var key2 = sideKey(pt2.side);
                if (key2 === "corners")
                    continue;
                if ((sideCounts[key2] || 0) >= sideMax(key2))
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

        // PASS 2: spawn decisions now run against the fully-accurate
        // sideCounts/active tally from pass 1 (kept up to date as this
        // pass spawns more), plus the shrink/grow activation update for
        // every slot.
        for (var i2 = 0; i2 < current.length; i2++) {
            var slot2 = current[i2];

            if (!slot2.active
                    && slot2.activation < 0.02
                    && active < desiredActive) {
                var freeIdx = pickSpawnCandidate();
                if (freeIdx >= 0) {
                    var candidatePt = points[freeIdx];
                    var candidateKey = sideKey(candidatePt.side);

                    respawnSlot(slot2, freeIdx, candidatePt, minX, minY, maxX, maxY);
                    sideCounts[candidateKey] = (sideCounts[candidateKey] || 0) + 1;
                    active++;
                }
            }

            if (!slot2.active && slot2.activation > 0.001) {
                slot2.tipX = slot2.rootX + (slot2.breakTipX - slot2.rootX) * slot2.activation;
                slot2.tipY = slot2.rootY + (slot2.breakTipY - slot2.rootY) * slot2.activation;
            }

            var target = slot2.active ? 1.0 : 0.0;
            var speed = target > slot2.activation ? gSpeed : sSpeed;

            slot2.activation += (target - slot2.activation) * speed;
        }

        // manager._debugCounter++;
        // if (manager._debugCounter % 30 === 0) {
        //     var liveCounts = { top: 0, right: 0, bottom: 0, left: 0, corners: 0 };
        //     for (var dbgI = 0; dbgI < current.length; dbgI++) {
        //         var dbgSlot = current[dbgI];
        //         if (dbgSlot.active) {
        //             var dbgKey = dbgSlot.side && dbgSlot.side.indexOf("corner-") === 0
        //                     ? "corners" : (dbgSlot.side || "top");
        //             liveCounts[dbgKey] = (liveCounts[dbgKey] || 0) + 1;
        //         }
        //     }
        //     console.log("[tendril-debug] active side counts:", JSON.stringify(liveCounts),
        //                 " panel.x:", panel.x, " panel.width:", panel.width,
        //                 " screenWidth:", screenWidth);
        // }

        slots = current.concat();
    }

    property Timer timer: Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: manager.tick()
    }
}
