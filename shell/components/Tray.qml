import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            implicitWidth: 18
            implicitHeight: 18

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayItem.modelData.icon
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                onClicked: function(mouse) {
                    if (mouse.button === Qt.MiddleButton)
                        trayItem.modelData.secondaryActivate();
                    else
                        trayItem.modelData.activate();
                }
            }
        }
    }
}
