import QtQuick
import Quickshell

ShellRoot {
    Launcher {
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
            }
        }
    }
}
