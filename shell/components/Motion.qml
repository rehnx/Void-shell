pragma Singleton
import QtQuick
import "../services"

QtObject {
    // Writable for existing callers/tests; the shell uses the settings bindings.
    property bool enabled: Settings.animationsEnabled
    property bool reducedMotion: Settings.reducedMotion
    property string level: Settings.animationSpeed
    readonly property bool spatial: enabled && !reducedMotion
    readonly property real speed: level === "fast" ? 0.7 : level === "slow" ? 1.4 : 1
    readonly property int instant: 0
    readonly property int feedback: duration(100)
    readonly property int color: duration(140)
    readonly property int enter: duration(260)
    readonly property int exit: duration(180)
    readonly property int expand: duration(300)
    readonly property int settle: duration(220)
    readonly property int standardCurve: Easing.OutCubic
    readonly property int exitCurve: Easing.InOutCubic
    // Finite, critically damped spring-like settling, without overshoot.
    readonly property int springCurve: Easing.OutQuint
    readonly property real hiddenScale: 0.97
    readonly property real slideDistance: 10
    readonly property real hoverLift: -1
    readonly property real pressScale: 0.975
    readonly property real disabledOpacity: Theme.disabledOpacity

    function duration(milliseconds: int): int {
        return !enabled || reducedMotion ? 0 : Math.round(milliseconds * speed);
    }
}
