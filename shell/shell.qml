pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

ShellRoot {
    ControlCenter {
        id: controlCenter
    }

    Launcher {
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                onControlCenterRequested: controlCenter.toggle(modelData)
            }
        }
    }
}
