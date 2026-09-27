import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    spacing: Theme.spacingSmall

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            implicitWidth: Theme.iconMedium
            implicitHeight: Theme.iconMedium

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.iconSmall
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
