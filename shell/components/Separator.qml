import QtQuick

Rectangle {
    property bool vertical: false
    implicitWidth: vertical ? Theme.borderWidth : 0
    implicitHeight: vertical ? 0 : Theme.borderWidth
    color: Theme.separator
}
