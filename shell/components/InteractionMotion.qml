import QtQuick

Item {
    id: root
    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    property bool selected: false
    property bool interactive: true
    property real feedbackScale: Motion.spatial && interactive && pressed ? Motion.pressScale : 1
    property real lift: Motion.spatial && interactive && hovered && !pressed ? Motion.hoverLift : 0
    property real contentOpacity: interactive ? 1 : Motion.disabledOpacity
    property color fill: !interactive ? "transparent" : pressed ? Theme.pressed : selected ? Theme.selected : hovered ? Theme.hover : "transparent"
    property color outline: interactive && focused ? theme.accent : "transparent"
    ControlStyle { id: theme }
    Behavior on feedbackScale { MotionAnimation { duration: root.pressed ? Motion.feedback : Motion.settle } }
    Behavior on lift { MotionAnimation { duration: Motion.feedback } }
    Behavior on contentOpacity { MotionAnimation { duration: Motion.color } }
    Behavior on fill { MotionColorAnimation {} }
    Behavior on outline { MotionColorAnimation {} }
}
