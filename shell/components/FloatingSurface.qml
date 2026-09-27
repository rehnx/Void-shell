import QtQuick

GlassSurface {
    id: root
    property alias shown: motion.shown
    property alias direction: motion.direction
    readonly property alias present: motion.present
    readonly property alias progress: motion.progress
    readonly property alias animating: motion.running
    // Opt in only for geometry owned by this item, never Layout-managed sizes.
    property bool animateGeometry: false
    property bool geometryReady: false
    signal hidden()
    visible: present
    enabled: shown
    opacity: motion.progress
    scale: motion.surfaceScale
    transform: Translate { y: motion.offset }
    elevated: true
    elevation: motion.progress
    MotionState { id: motion; onHidden: root.hidden() }
    Component.onCompleted: geometryReady = true
    Behavior on x { enabled: root.animateGeometry && root.geometryReady; MotionAnimation { duration: Motion.expand } }
    Behavior on y { enabled: root.animateGeometry && root.geometryReady; MotionAnimation { duration: Motion.expand } }
    Behavior on width { enabled: root.animateGeometry && root.geometryReady; MotionAnimation { duration: Motion.expand } }
    Behavior on height { enabled: root.animateGeometry && root.geometryReady; MotionAnimation { duration: Motion.expand } }
}
