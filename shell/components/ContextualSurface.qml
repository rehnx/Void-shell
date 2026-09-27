import QtQuick

FloatingSurface {
    id: root
    // Both rectangles must be in the same parent coordinate space. Cross-window
    // widgets should open a FloatingSurface; do not interpolate global geometry.
    property rect compactRect: Qt.rect(0, 0, 0, 0)
    property rect expandedRect: compactRect
    property bool expanded: false
    shown: true
    animateGeometry: true
    x: expanded ? expandedRect.x : compactRect.x
    y: expanded ? expandedRect.y : compactRect.y
    width: expanded ? expandedRect.width : compactRect.width
    height: expanded ? expandedRect.height : compactRect.height
    clip: true
}
