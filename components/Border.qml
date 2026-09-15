// components/Border.qml
import QtQuick
import "."

ShaderEffect {
    id: root

    property vector2d size: Qt.vector2d(width, height)
    property real thickness: Theme.borderThickness
    property real rounding: Theme.borderRounding
    property real smoothing: Theme.borderSmoothing
    property vector4d borderColor: Qt.vector4d(
        Theme.borderColor.r,
        Theme.borderColor.g,
        Theme.borderColor.b,
        Theme.borderColor.a * Theme.borderOpacity
    )

    // x: enabled, y: spikes per 100 px, z: outward length, w: length variance.
    function spikeProfile(local) {
        var c = local.spikeOverride ? local : Config.sAdapter.panels
        return Qt.vector4d(c.spikesEnabled ? 1 : 0, c.spikeFrequency, c.spikeLength, c.spikeVariance)
    }
    property vector4d launcherSpikes: spikeProfile(Config.sAdapter.launcher)
    property vector4d clockSpikes: spikeProfile(Config.sAdapter.clock)
    property vector4d traySpikes: spikeProfile(Config.sAdapter.tray)
    property vector4d trayMenuSpikes: spikeProfile(Config.sAdapter.trayMenu)

    function spikeSharpness(local) {
        return (local.spikeOverride ? local : Config.sAdapter.panels).spikeSharpness
    }
    property real launcherSpikeSharpness: spikeSharpness(Config.sAdapter.launcher)
    property real clockSpikeSharpness: spikeSharpness(Config.sAdapter.clock)
    property real traySpikeSharpness: spikeSharpness(Config.sAdapter.tray)
    property real trayMenuSpikeSharpness: spikeSharpness(Config.sAdapter.trayMenu)

    // --- Organic inner border ---
    property real organicBorderEnabledF:
        Config.sAdapter.organicBorder.enabled ? 1.0 : 0.0

    property real organicBorderAmplitude:
        Config.sAdapter.organicBorder.amplitude

    property real organicBorderFrequency:
        Config.sAdapter.organicBorder.frequency

    property real organicBorderPeakSharpness:
        Config.sAdapter.organicBorder.peakSharpness

    property real organicBorderValleySharpness:
        Config.sAdapter.organicBorder.valleySharpness

    property real organicBorderAnimationSpeed:
        Config.sAdapter.organicBorder.animationSpeed

    property real organicBorderSeed:
        Config.sAdapter.organicBorder.seed

    // --- Organic-border parameter morphing ---
    property real organicBorderAnimatedF:
        Config.sAdapter.organicBorder.animated ? 1.0 : 0.0

    property real organicBorderMorphSpeed:
        Config.sAdapter.organicBorder.morphSpeed

    property real organicBorderAmplitudeRange:
        Config.sAdapter.organicBorder.amplitudeRange

    property real organicBorderTime: 0.0

    Timer {
        id: organicBorderClock
        interval: 16
        repeat: true
        running: root.organicBorderEnabledF > 0.5
                 && (root.organicBorderAnimationSpeed > 0.0
                     || root.organicBorderAnimatedF > 0.5)

        onTriggered: {
            root.organicBorderTime += interval / 1000.0;
        }
    }

    // --- Legacy / Active Panel compatibility ---
    property real panelX: launcherWidth > 0 ? launcherX : (clockWidth > 0 ? clockX : -100000)
    property real panelY: launcherHeight > 0 ? launcherY : (clockHeight > 0 ? clockY : -100000)
    property real panelWidth: launcherWidth > 0 ? launcherWidth : (clockWidth > 0 ? clockWidth : 0)
    property real panelHeight: launcherHeight > 0 ? launcherHeight : (clockHeight > 0 ? clockHeight : 0)
    property real panelRounding: launcherWidth > 0 ? launcherRounding : clockRounding

    property vector2d panelPos: Qt.vector2d(panelX, panelY)
    property vector2d panelSize: Qt.vector2d(panelWidth, panelHeight)

    // --- Dedicated Launcher Geometry ---
    property real launcherX: 0
    property real launcherY: 0
    property real launcherWidth: 0
    property real launcherHeight: 0
    property real launcherRounding: Theme.borderRounding
    property vector2d launcherPos: Qt.vector2d(launcherX, launcherY)
    property vector2d launcherSize: Qt.vector2d(launcherWidth, launcherHeight)


    // Dedicated Clock Geometry
    property real clockX: 0
    property real clockY: 0
    property real clockWidth: 0
    property real clockHeight: 0

    // --- Dedicated Tray Geometry ---
    property real trayX: 0
    property real trayY: 0
    property real trayWidth: 0
    property real trayHeight: 0
    property vector4d trayRounding: Qt.vector4d(16, 16, 16, 16)
    property vector2d trayPos: Qt.vector2d(trayX, trayY)
    property vector2d traySize: Qt.vector2d(trayWidth, trayHeight)

    // --- Dedicated Tray Menu Geometry ---
    property real trayMenuX: 0
    property real trayMenuY: 0
    property real trayMenuWidth: 0
    property real trayMenuHeight: 0
    property vector4d trayMenuRounding: Qt.vector4d(12, 12, 12, 12)
    property vector2d trayMenuPos: Qt.vector2d(trayMenuX, trayMenuY)
    property vector2d trayMenuSize: Qt.vector2d(trayMenuWidth, trayMenuHeight)

    // --- Tray Tendril Settings ---
    property real trayBlendRadiusRoot: trayPanel.tendrilBlendRadiusRootOverride ?? 16
    property real trayBlendRadiusPanel: trayPanel.tendrilBlendRadiusPanelOverride ?? 12
    property vector2d trayTendrilBlend: Qt.vector2d(trayBlendRadiusRoot, trayBlendRadiusPanel)
    property real trayWaistSmoothing: trayPanel.tendrilWaistSmoothingOverride ?? 24

    // --- Tray Menu Tendril Settings ---
    property vector2d trayMenuTendrilBlend: Qt.vector2d(10, 8)
    property real trayMenuWaistSmoothing: 28

    // Pool aggregation
    property var traySlots: []
    property var trayMenuSlots: []

    // MUST BE property vector4d, NOT property real!
    property vector4d clockRounding: Qt.vector4d(16, 16, 16, 16)

    property vector2d clockPos: Qt.vector2d(clockX, clockY)
    property vector2d clockSize: Qt.vector2d(clockWidth, clockHeight)

    // --- Outer shadow ---
    property real shadowEnabledF: Theme.shadowEnabled ? 1.0 : 0.0
    property vector4d shadowColor: Qt.vector4d(Theme.shadowColor.r, Theme.shadowColor.g, Theme.shadowColor.b, Theme.shadowColor.a)
    property real shadowOpacity: Theme.shadowOpacity
    property real shadowFalloff: Theme.shadowFalloff

    // --- Inner edge glow ---
    property real innerEdgeEnabledF: Theme.innerEdgeEnabled ? 1.0 : 0.0
    property vector4d innerEdgeColor: Qt.vector4d(Theme.innerEdgeColor.r, Theme.innerEdgeColor.g, Theme.innerEdgeColor.b, Theme.innerEdgeColor.a)
    property real innerEdgeIntensity: Theme.innerEdgeIntensity
    property real innerEdgeFalloff: Theme.innerEdgeFalloff

    // --- Combined Tendril Slot Pool ---
    property var launcherSlots: []
    property var clockSlots: []
    property var tendrilSlots: []

    readonly property int renderCapacity: Theme.tendrilRenderCapacity

    function visibleSlots() {
        var list = [];

        // 1. Gather from launcher
        var lSrc = launcherSlots || [];
        for (var i = 0; i < lSrc.length; i++) {
            if (lSrc[i] && lSrc[i].activation > 0.001)
                list.push(lSrc[i]);
        }

        // 2. Gather from clock
        var cSrc = clockSlots || [];
        for (var j = 0; j < cSrc.length; j++) {
            if (cSrc[j] && cSrc[j].activation > 0.001)
                list.push(cSrc[j]);
        }

                // Gather from tray
        var tSrc = traySlots
        if (tSrc) {
            for (var k = 0; k < tSrc.length; k++) {
                if (tSrc[k] && tSrc[k].activation > 0.001) list.push(tSrc[k])
            }
        }

        // 4. Gather from tray menu
        var tmSrc = trayMenuSlots || [];
        for (var m = 0; m < tmSrc.length; m++) {
            if (tmSrc[m] && tmSrc[m].activation > 0.001)
                list.push(tmSrc[m]);
        }

        // 5. Fallback to raw tendrilSlots if passed directly
        if (list.length === 0 && tendrilSlots && tendrilSlots.length > 0) {
            for (var k = 0; k < tendrilSlots.length; k++) {
                if (tendrilSlots[k] && tendrilSlots[k].activation > 0.001)
                    list.push(tendrilSlots[k]);
            }
        }

        list.sort(function(a, b) { return b.activation - a.activation; });
        return list;
    }

    property var visibleTendrils: visibleSlots()

    // --- Launcher Tendril Settings ---
    property real launcherBlendRadiusRoot: launcherPanel.tendrilBlendRadiusRootOverride || 60
    property real launcherBlendRadiusPanel: launcherPanel.tendrilBlendRadiusPanelOverride || 45
    property vector2d launcherTendrilBlend: Qt.vector2d(launcherBlendRadiusRoot, launcherBlendRadiusPanel)
    property real launcherWaistSmoothing: launcherPanel.tendrilWaistSmoothingOverride || 100

    // --- Clock Tendril Settings ---
    property real clockBlendRadiusRoot: clockPanel.tendrilBlendRadiusRootOverride || 16
    property real clockBlendRadiusPanel: clockPanel.tendrilBlendRadiusPanelOverride || 12
    property vector2d clockTendrilBlend: Qt.vector2d(clockBlendRadiusRoot, clockBlendRadiusPanel)
    property real clockWaistSmoothing: clockPanel.tendrilWaistSmoothingOverride || 24

    property real tendrilPanelStretchExponent: 2.0
    property real tendrilPanelMinStretchThickness: 0.6

    function slotPos(i) {
        var s = visibleTendrils[i];
        return s ? Qt.vector4d(s.rootX, s.rootY, s.tipX, s.tipY) : Qt.vector4d(0, 0, 0, 0);
    }

    function slotThick(i) {
        var s = visibleTendrils[i];
        if (!s) return Qt.vector4d(0, 0, 0, 0);
        var tension = s.tension || 0.0;
        var stretchFactor = Math.pow(tension, tendrilPanelStretchExponent);
        var panelThick = s.panelThick * (1.0 - stretchFactor) + tendrilPanelMinStretchThickness * stretchFactor;
        return Qt.vector4d(s.rootThick, s.waistThick, panelThick, s.activation);
    }

    // ==== Generated uniform bindings 0..63 ====
    property vector4d tendril0Pos: slotPos(0)
    property vector4d tendril1Pos: slotPos(1)
    property vector4d tendril2Pos: slotPos(2)
    property vector4d tendril3Pos: slotPos(3)
    property vector4d tendril4Pos: slotPos(4)
    property vector4d tendril5Pos: slotPos(5)
    property vector4d tendril6Pos: slotPos(6)
    property vector4d tendril7Pos: slotPos(7)
    property vector4d tendril8Pos: slotPos(8)
    property vector4d tendril9Pos: slotPos(9)
    property vector4d tendril10Pos: slotPos(10)
    property vector4d tendril11Pos: slotPos(11)
    property vector4d tendril12Pos: slotPos(12)
    property vector4d tendril13Pos: slotPos(13)
    property vector4d tendril14Pos: slotPos(14)
    property vector4d tendril15Pos: slotPos(15)
    property vector4d tendril16Pos: slotPos(16)
    property vector4d tendril17Pos: slotPos(17)
    property vector4d tendril18Pos: slotPos(18)
    property vector4d tendril19Pos: slotPos(19)
    property vector4d tendril20Pos: slotPos(20)
    property vector4d tendril21Pos: slotPos(21)
    property vector4d tendril22Pos: slotPos(22)
    property vector4d tendril23Pos: slotPos(23)
    property vector4d tendril24Pos: slotPos(24)
    property vector4d tendril25Pos: slotPos(25)
    property vector4d tendril26Pos: slotPos(26)
    property vector4d tendril27Pos: slotPos(27)
    property vector4d tendril28Pos: slotPos(28)
    property vector4d tendril29Pos: slotPos(29)
    property vector4d tendril30Pos: slotPos(30)
    property vector4d tendril31Pos: slotPos(31)
    property vector4d tendril32Pos: slotPos(32)
    property vector4d tendril33Pos: slotPos(33)
    property vector4d tendril34Pos: slotPos(34)
    property vector4d tendril35Pos: slotPos(35)
    property vector4d tendril36Pos: slotPos(36)
    property vector4d tendril37Pos: slotPos(37)
    property vector4d tendril38Pos: slotPos(38)
    property vector4d tendril39Pos: slotPos(39)
    property vector4d tendril40Pos: slotPos(40)
    property vector4d tendril41Pos: slotPos(41)
    property vector4d tendril42Pos: slotPos(42)
    property vector4d tendril43Pos: slotPos(43)
    property vector4d tendril44Pos: slotPos(44)
    property vector4d tendril45Pos: slotPos(45)
    property vector4d tendril46Pos: slotPos(46)
    property vector4d tendril47Pos: slotPos(47)
    property vector4d tendril48Pos: slotPos(48)
    property vector4d tendril49Pos: slotPos(49)
    property vector4d tendril50Pos: slotPos(50)
    property vector4d tendril51Pos: slotPos(51)
    property vector4d tendril52Pos: slotPos(52)
    property vector4d tendril53Pos: slotPos(53)
    property vector4d tendril54Pos: slotPos(54)
    property vector4d tendril55Pos: slotPos(55)
    property vector4d tendril56Pos: slotPos(56)
    property vector4d tendril57Pos: slotPos(57)
    property vector4d tendril58Pos: slotPos(58)
    property vector4d tendril59Pos: slotPos(59)
    property vector4d tendril60Pos: slotPos(60)
    property vector4d tendril61Pos: slotPos(61)
    property vector4d tendril62Pos: slotPos(62)
    property vector4d tendril63Pos: slotPos(63)
    property vector4d tendril0Thick: slotThick(0)
    property vector4d tendril1Thick: slotThick(1)
    property vector4d tendril2Thick: slotThick(2)
    property vector4d tendril3Thick: slotThick(3)
    property vector4d tendril4Thick: slotThick(4)
    property vector4d tendril5Thick: slotThick(5)
    property vector4d tendril6Thick: slotThick(6)
    property vector4d tendril7Thick: slotThick(7)
    property vector4d tendril8Thick: slotThick(8)
    property vector4d tendril9Thick: slotThick(9)
    property vector4d tendril10Thick: slotThick(10)
    property vector4d tendril11Thick: slotThick(11)
    property vector4d tendril12Thick: slotThick(12)
    property vector4d tendril13Thick: slotThick(13)
    property vector4d tendril14Thick: slotThick(14)
    property vector4d tendril15Thick: slotThick(15)
    property vector4d tendril16Thick: slotThick(16)
    property vector4d tendril17Thick: slotThick(17)
    property vector4d tendril18Thick: slotThick(18)
    property vector4d tendril19Thick: slotThick(19)
    property vector4d tendril20Thick: slotThick(20)
    property vector4d tendril21Thick: slotThick(21)
    property vector4d tendril22Thick: slotThick(22)
    property vector4d tendril23Thick: slotThick(23)
    property vector4d tendril24Thick: slotThick(24)
    property vector4d tendril25Thick: slotThick(25)
    property vector4d tendril26Thick: slotThick(26)
    property vector4d tendril27Thick: slotThick(27)
    property vector4d tendril28Thick: slotThick(28)
    property vector4d tendril29Thick: slotThick(29)
    property vector4d tendril30Thick: slotThick(30)
    property vector4d tendril31Thick: slotThick(31)
    property vector4d tendril32Thick: slotThick(32)
    property vector4d tendril33Thick: slotThick(33)
    property vector4d tendril34Thick: slotThick(34)
    property vector4d tendril35Thick: slotThick(35)
    property vector4d tendril36Thick: slotThick(36)
    property vector4d tendril37Thick: slotThick(37)
    property vector4d tendril38Thick: slotThick(38)
    property vector4d tendril39Thick: slotThick(39)
    property vector4d tendril40Thick: slotThick(40)
    property vector4d tendril41Thick: slotThick(41)
    property vector4d tendril42Thick: slotThick(42)
    property vector4d tendril43Thick: slotThick(43)
    property vector4d tendril44Thick: slotThick(44)
    property vector4d tendril45Thick: slotThick(45)
    property vector4d tendril46Thick: slotThick(46)
    property vector4d tendril47Thick: slotThick(47)
    property vector4d tendril48Thick: slotThick(48)
    property vector4d tendril49Thick: slotThick(49)
    property vector4d tendril50Thick: slotThick(50)
    property vector4d tendril51Thick: slotThick(51)
    property vector4d tendril52Thick: slotThick(52)
    property vector4d tendril53Thick: slotThick(53)
    property vector4d tendril54Thick: slotThick(54)
    property vector4d tendril55Thick: slotThick(55)
    property vector4d tendril56Thick: slotThick(56)
    property vector4d tendril57Thick: slotThick(57)
    property vector4d tendril58Thick: slotThick(58)
    property vector4d tendril59Thick: slotThick(59)
    property vector4d tendril60Thick: slotThick(60)
    property vector4d tendril61Thick: slotThick(61)
    property vector4d tendril62Thick: slotThick(62)
    property vector4d tendril63Thick: slotThick(63)
    // ==== end generated ====

    fragmentShader: Qt.resolvedUrl("shaders/border-sharpness.frag.qsb")
    blending: true
}
