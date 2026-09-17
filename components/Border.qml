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
    property vector4d dashboardSpikes: spikeProfile(Config.sAdapter.panels)
    property vector4d clockSpikes: spikeProfile(Config.sAdapter.clock)
    property vector4d traySpikes: spikeProfile(Config.sAdapter.tray)
    property vector4d trayMenuSpikes: spikeProfile(Config.sAdapter.trayMenu)
    property vector4d notificationSpikes: spikeProfile(Config.sAdapter.notifications)

    function spikeSharpness(local) {
        return (local.spikeOverride ? local : Config.sAdapter.panels).spikeSharpness
    }
    property real launcherSpikeSharpness: spikeSharpness(Config.sAdapter.launcher)
    property real dashboardSpikeSharpness: spikeSharpness(Config.sAdapter.panels)
    property real clockSpikeSharpness: spikeSharpness(Config.sAdapter.clock)
    property real traySpikeSharpness: spikeSharpness(Config.sAdapter.tray)
    property real trayMenuSpikeSharpness: spikeSharpness(Config.sAdapter.trayMenu)
    property real notificationSpikeSharpness: spikeSharpness(Config.sAdapter.notifications)

    property vector4d powerRect0: Qt.vector4d(0, 0, 0, 0)
    property vector4d powerRect1: Qt.vector4d(0, 0, 0, 0)
    property vector4d powerRect2: Qt.vector4d(0, 0, 0, 0)
    property vector4d powerRect3: Qt.vector4d(0, 0, 0, 0)
    property vector4d powerRect4: Qt.vector4d(0, 0, 0, 0)
    property vector4d powerSpikes: spikeProfile(Config.sAdapter.powerMenu)
    property real powerSpikeSharpness: spikeSharpness(Config.sAdapter.powerMenu)
    property var powerSlots: []

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

    // --- Dedicated Dashboard Geometry ---
    property real dashboardX: 0
    property real dashboardY: 0
    property real dashboardWidth: 0
    property real dashboardHeight: 0
    property real dashboardRounding: 24
    property vector2d dashboardPos: Qt.vector2d(dashboardX, dashboardY)
    property vector2d dashboardSize: Qt.vector2d(dashboardWidth, dashboardHeight)
    property var dashboardSlots: []
    property vector2d dashboardTendrilBlend: Qt.vector2d(34, 24)
    property real dashboardWaistSmoothing: 54

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

    // --- Notification Geometry ---
    property real notificationCenterX: 0
    property real notificationCenterY: 0
    property real notificationCenterWidth: 0
    property real notificationCenterHeight: 0
    property vector4d notificationCenterRounding: Qt.vector4d(24, 24, 24, 24)
    property vector2d notificationCenterPos: Qt.vector2d(notificationCenterX, notificationCenterY)
    property vector2d notificationCenterSize: Qt.vector2d(notificationCenterWidth, notificationCenterHeight)
    property real notificationCenterJoinRadius: 20

    property real notificationToastX: 0
    property real notificationToastY: 0
    property real notificationToastWidth: 0
    property real notificationToastHeight: 0
    property vector4d notificationToastRounding: Qt.vector4d(18, 18, 18, 18)
    property vector2d notificationToastPos: Qt.vector2d(notificationToastX, notificationToastY)
    property vector2d notificationToastSize: Qt.vector2d(notificationToastWidth, notificationToastHeight)

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
    property var notificationCenterSlots: []
    property var notificationToastSlots: []

    // --- Workspace Indicator Geometry ---
    // The workspace organism is rendered by border.frag so its body and
    // tendrils are unioned with the same physical border as every other panel.
    property real workspaceEnabledF: 0.0
    property vector2d workspaceOrigin: Qt.vector2d(-100000, -100000)
    property real workspaceVerticalF: 0.0
    property real workspaceNodeCount: 0.0
    property real workspaceNodeSpacing: 46.0
    property real workspaceChamberRadius: 17.0
    property real workspaceTubeRadius: 5.0
    property real workspaceLiquidPosition: 0.0
    property real workspaceLiquidFollowerPosition: 0.0
    property real workspaceLiquidVelocity: 0.0
    property real workspaceLiquidFollowerVelocity: 0.0
    property real workspaceLiquidDurationMs: 480.0
    property real workspaceLiquidFollowerScale: 0.72
    property real workspaceLiquidPulsePhase: 0.0
    property real workspaceLiquidPulseEnabledF: 0.0
    property real workspaceLiquidPulseStrength: 0.0
    property real workspaceLiquidMotionStrength: 0.0
    property real workspaceLiquidEnabledF: 0.0
    property vector4d workspaceLiquidColor: Qt.vector4d(
        Theme.textColorAccent.r,
        Theme.textColorAccent.g,
        Theme.textColorAccent.b,
        Theme.textColorAccent.a
    )
    property var workspaceSlots: []
    property vector2d workspaceTendrilBlend: Qt.vector2d(8, 8)
    property real workspaceWaistSmoothing: 18

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

        function collect(source, profile) {
            for (var i = 0; i < source.length; ++i) {
                var slot = source[i];

                if (slot && slot.activation > 0.001) {
                    list.push({
                        slot: slot,
                        profile: profile
                    });
                }
            }
        }

        var power = [];
        var pSrc = powerSlots || [];

        for (var p = 0; p < pSrc.length; ++p) {
            if (pSrc[p] && pSrc[p].activation > 0.001) {
                power.push({
                    slot: pSrc[p],
                    profile: Qt.vector4d(40, 24, 60, 0)
                });
            }
        }

        collect(
            launcherSlots || [],
            Qt.vector4d(
                launcherTendrilBlend.x,
                launcherTendrilBlend.y,
                launcherWaistSmoothing,
                0
            )
        );

        collect(
            dashboardSlots || [],
            Qt.vector4d(
                dashboardTendrilBlend.x,
                dashboardTendrilBlend.y,
                dashboardWaistSmoothing,
                0
            )
        );

        collect(
            clockSlots || [],
            Qt.vector4d(
                clockTendrilBlend.x,
                clockTendrilBlend.y,
                clockWaistSmoothing,
                0
            )
        );

        collect(
            traySlots || [],
            Qt.vector4d(
                trayTendrilBlend.x,
                trayTendrilBlend.y,
                trayWaistSmoothing,
                0
            )
        );

        collect(
            trayMenuSlots || [],
            Qt.vector4d(
                trayMenuTendrilBlend.x,
                trayMenuTendrilBlend.y,
                trayMenuWaistSmoothing,
                0
            )
        );

        collect(
            notificationCenterSlots || [],
            Qt.vector4d(24, 18, 42, 0)
        );

        collect(
            notificationToastSlots || [],
            Qt.vector4d(14, 10, 26, 0)
        );

        collect(
            workspaceSlots || [],
            Qt.vector4d(
                workspaceTendrilBlend.x,
                workspaceTendrilBlend.y,
                workspaceWaistSmoothing,
                0
            )
        );

        if (!list.length && !power.length) {
            collect(
                tendrilSlots || [],
                Qt.vector4d(
                    launcherTendrilBlend.x,
                    launcherTendrilBlend.y,
                    launcherWaistSmoothing,
                    0
                )
            );
        }

        function activationSort(a, b) {
            return b.slot.activation - a.slot.activation;
        }

        list.sort(activationSort);
        power.sort(activationSort);

        /*
         * Normally power tendrils retain their existing priority.
         *
         * During a power -> launcher/settings handoff, however, both organisms
         * coexist briefly. Treat them as one pool ordered by activation so
         * incoming tendrils can progressively replace retracting power tendrils
         * instead of remaining invisible until every power tendril is gone.
         */
        var centerPanelVisible =
            launcherWidth > 5
            && launcherHeight > 5;

        if (centerPanelVisible && power.length > 0) {
            var handoff = power.concat(list);

            handoff.sort(activationSort);

            return handoff.slice(0, renderCapacity);
        }

        return power.concat(list).slice(0, renderCapacity);
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
        var entry = visibleTendrils[i];
        var s = entry ? entry.slot : null;
        return s ? Qt.vector4d(s.rootX, s.rootY, s.tipX, s.tipY) : Qt.vector4d(0, 0, 0, 0);
    }

    function slotThick(i) {
        var entry = visibleTendrils[i];
        var s = entry ? entry.slot : null;
        if (!s) return Qt.vector4d(0, 0, 0, 0);
        var tension = s.tension || 0.0;
        var stretchFactor = Math.pow(tension, tendrilPanelStretchExponent);
        var panelThick = s.panelThick * (1.0 - stretchFactor) + tendrilPanelMinStretchThickness * stretchFactor;
        return Qt.vector4d(s.rootThick, s.waistThick, panelThick, s.activation);
    }

    function slotProfile(i) {
        var entry = visibleTendrils[i];
        return entry ? entry.profile : Qt.vector4d(0, 0, 0, 0);
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
    property vector4d tendril0Profile: slotProfile(0)
    property vector4d tendril1Profile: slotProfile(1)
    property vector4d tendril2Profile: slotProfile(2)
    property vector4d tendril3Profile: slotProfile(3)
    property vector4d tendril4Profile: slotProfile(4)
    property vector4d tendril5Profile: slotProfile(5)
    property vector4d tendril6Profile: slotProfile(6)
    property vector4d tendril7Profile: slotProfile(7)
    property vector4d tendril8Profile: slotProfile(8)
    property vector4d tendril9Profile: slotProfile(9)
    property vector4d tendril10Profile: slotProfile(10)
    property vector4d tendril11Profile: slotProfile(11)
    property vector4d tendril12Profile: slotProfile(12)
    property vector4d tendril13Profile: slotProfile(13)
    property vector4d tendril14Profile: slotProfile(14)
    property vector4d tendril15Profile: slotProfile(15)
    property vector4d tendril16Profile: slotProfile(16)
    property vector4d tendril17Profile: slotProfile(17)
    property vector4d tendril18Profile: slotProfile(18)
    property vector4d tendril19Profile: slotProfile(19)
    property vector4d tendril20Profile: slotProfile(20)
    property vector4d tendril21Profile: slotProfile(21)
    property vector4d tendril22Profile: slotProfile(22)
    property vector4d tendril23Profile: slotProfile(23)
    property vector4d tendril24Profile: slotProfile(24)
    property vector4d tendril25Profile: slotProfile(25)
    property vector4d tendril26Profile: slotProfile(26)
    property vector4d tendril27Profile: slotProfile(27)
    property vector4d tendril28Profile: slotProfile(28)
    property vector4d tendril29Profile: slotProfile(29)
    property vector4d tendril30Profile: slotProfile(30)
    property vector4d tendril31Profile: slotProfile(31)
    property vector4d tendril32Profile: slotProfile(32)
    property vector4d tendril33Profile: slotProfile(33)
    property vector4d tendril34Profile: slotProfile(34)
    property vector4d tendril35Profile: slotProfile(35)
    property vector4d tendril36Profile: slotProfile(36)
    property vector4d tendril37Profile: slotProfile(37)
    property vector4d tendril38Profile: slotProfile(38)
    property vector4d tendril39Profile: slotProfile(39)
    property vector4d tendril40Profile: slotProfile(40)
    property vector4d tendril41Profile: slotProfile(41)
    property vector4d tendril42Profile: slotProfile(42)
    property vector4d tendril43Profile: slotProfile(43)
    property vector4d tendril44Profile: slotProfile(44)
    property vector4d tendril45Profile: slotProfile(45)
    property vector4d tendril46Profile: slotProfile(46)
    property vector4d tendril47Profile: slotProfile(47)
    property vector4d tendril48Profile: slotProfile(48)
    property vector4d tendril49Profile: slotProfile(49)
    property vector4d tendril50Profile: slotProfile(50)
    property vector4d tendril51Profile: slotProfile(51)
    property vector4d tendril52Profile: slotProfile(52)
    property vector4d tendril53Profile: slotProfile(53)
    property vector4d tendril54Profile: slotProfile(54)
    property vector4d tendril55Profile: slotProfile(55)
    property vector4d tendril56Profile: slotProfile(56)
    property vector4d tendril57Profile: slotProfile(57)
    property vector4d tendril58Profile: slotProfile(58)
    property vector4d tendril59Profile: slotProfile(59)
    property vector4d tendril60Profile: slotProfile(60)
    property vector4d tendril61Profile: slotProfile(61)
    property vector4d tendril62Profile: slotProfile(62)
    property vector4d tendril63Profile: slotProfile(63)
    // ==== end generated ====

    fragmentShader: Qt.resolvedUrl("shaders/border-fast.frag.qsb")
    blending: true
}
