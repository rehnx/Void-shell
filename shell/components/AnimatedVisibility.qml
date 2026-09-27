import QtQuick

Item {
    id: root
    property alias shown: motion.shown
    property alias direction: motion.direction
    readonly property alias present: motion.present
    readonly property alias progress: motion.progress
    readonly property alias animating: motion.running
    signal hidden()
    visible: present
    enabled: shown
    opacity: motion.progress
    scale: motion.surfaceScale
    transform: Translate { y: motion.offset }
    MotionState { id: motion; onHidden: root.hidden() }
}
