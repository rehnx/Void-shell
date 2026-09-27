pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

ColumnLayout {
    spacing: Theme.spacingSmall
    id: root
    property date shownMonth: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)
    readonly property date today: clock.date
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    ControlStyle { id: theme }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    function previousMonth() {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() - 1, 1);
    }
    function nextMonth() {
        shownMonth = new Date(shownMonth.getFullYear(), shownMonth.getMonth() + 1, 1);
    }
    function showCurrentMonth() {
        shownMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    }
    function dateForCell(index) {
        const firstWeekday = (new Date(shownMonth.getFullYear(), shownMonth.getMonth(), 1).getDay() + 6) % 7;
        return new Date(shownMonth.getFullYear(), shownMonth.getMonth(), index - firstWeekday + 1);
    }
    function sameDay(left, right) {
        return left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
    }

    RowLayout {
        spacing: Theme.spacingSmall
        Layout.fillWidth: true
        ShellButton { text: "‹"; Accessible.name: "Previous month"; onClicked: root.previousMonth() }
        ShellButton {
            Layout.fillWidth: true
            text: root.monthNames[root.shownMonth.getMonth()] + " " + root.shownMonth.getFullYear()
            Accessible.name: "Show current month"
            prominent: true
            onClicked: root.showCurrentMonth()
        }
        ShellButton { text: "›"; Accessible.name: "Next month"; onClicked: root.nextMonth() }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: theme.spacingSmall
        columnSpacing: theme.spacingSmall
        Repeater {
            model: root.dayNames
            ShellText {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                color: theme.secondary
                font.pixelSize: theme.fontSmall
                horizontalAlignment: Text.AlignHCenter
            }
        }
        Repeater {
            model: 42
            Rectangle {
                id: cell
                required property int index
                readonly property date cellDate: root.dateForCell(index)
                readonly property bool currentMonth: cellDate.getMonth() === root.shownMonth.getMonth()
                    && cellDate.getFullYear() === root.shownMonth.getFullYear()
                readonly property bool isToday: root.sameDay(cellDate, root.today)
                Layout.fillWidth: true
                implicitHeight: Theme.calendarCellHeight
                radius: theme.radiusSmall
                color: isToday ? theme.accent : "transparent"
                ShellText {
                    anchors.centerIn: parent
                    text: cell.cellDate.getDate()
                    color: cell.isToday ? Theme.textOnAccent : cell.currentMonth ? theme.text : theme.secondary
                    opacity: cell.currentMonth || cell.isToday ? 1 : Theme.mutedOpacity
                    font.pixelSize: theme.fontBody
                }
            }
        }
    }
    ShellText {
        Layout.fillWidth: true
        text: "No events"
        color: theme.secondary
        font.pixelSize: theme.fontSmall
        horizontalAlignment: Text.AlignHCenter
    }
}
