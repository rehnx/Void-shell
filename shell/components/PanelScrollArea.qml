import QtQuick
import QtQuick.Controls

Flickable {
    id: root
    property real naturalHeight: 0
    anchors.fill: parent
    anchors.margins: Theme.panelPadding
    contentWidth: width
    contentHeight: naturalHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {
        id: scrollbar
        // Keep the thumb in the panel's padding, clear of text and controls.
        parent: root.parent
        x: root.x + root.width + Theme.spacingTiny
        y: root.y
        height: root.height
        visible: size < 1
        contentItem: Rectangle {
            radius: Theme.radiusSmall
            color: Theme.borderStrong
            implicitWidth: Theme.spacingTiny
            opacity: scrollbar.active ? 1 : Theme.mutedOpacity
            Behavior on opacity { MotionAnimation { duration: Motion.color } }
        }
    }
}
