import QtQuick

Item {
    id: root
    property bool shown: false
    property real direction: -1
    property bool ready: false
    property real progress: ready && shown ? 1 : 0
    readonly property bool present: shown || progress > 0
    readonly property bool running: progress > 0 && progress < 1
    readonly property real surfaceScale: Motion.spatial ? Motion.hiddenScale + (1 - Motion.hiddenScale) * progress : 1
    readonly property real offset: Motion.spatial ? direction * Motion.slideDistance * (1 - progress) : 0
    signal hidden()

    Component.onCompleted: ready = true
    onProgressChanged: if (!shown && progress === 0) hidden()
    // Behavior-owned animations cannot be completed imperatively. Reapply our
    // target binding with the Behavior disabled when motion is switched off.
    Connections {
        target: Motion
        function onSpatialChanged() {
            if (!Motion.spatial)
                root.progress = Qt.binding(() => root.ready && root.shown ? 1 : 0);
        }
    }
    Behavior on progress {
        enabled: Motion.spatial
        MotionAnimation {
            duration: root.shown ? Motion.enter : Motion.exit
            easing.type: root.shown ? Motion.springCurve : Motion.exitCurve
        }
    }
}
