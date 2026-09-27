import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "components"
import "panels"
import "services"
import "widgets"

ShellRoot {
    id: root
    property string lastPowerAction: ""

    SystemService {
        id: system
        actionsEnabled: false
        shortcutAppId: "quickshell-core-test"
        onPowerActionRequested: action => root.lastPowerAction = action
    }
    OSD { id: osd; service: system }
    PowerMenu {
        id: powerMenu
        service: system
        shortcutAppId: "quickshell-core-test"
    }
    CalendarPanel {
        id: calendarPanel
        shortcutAppId: "quickshell-core-test"
    }
    Item {
        Calendar { id: calendar }
    }
    TestCase { id: powerInput; when: false; parent: powerMenu.contentItem }
    TestCase { id: calendarInput; when: false; parent: calendarPanel.contentItem }

    IpcHandler {
        target: "coreTest"

        function state(): string {
            return JSON.stringify({
                cpu: system.cpuUsage,
                memory: system.memoryUsage,
                temperature: system.temperature,
                temperatureAvailable: system.temperatureAvailable,
                batteryAvailable: system.batteryAvailable,
                batteryPercentage: system.batteryPercentage,
                batteryStatus: system.batteryStatus,
                brightnessAvailable: system.brightnessAvailable,
                brightnessValue: system.brightnessValue,
                brightnessStatus: system.brightnessStatus,
                osdVisible: system.osdVisible,
                osdWindowVisible: osd.visible,
                osdKind: system.osdKind,
                osdLabel: system.osdLabel,
                osdValue: system.osdValue,
                osdMuted: system.osdMuted,
                pendingAction: powerMenu.pendingAction,
                powerOpened: powerMenu.opened,
                lastPowerAction: root.lastPowerAction
            });
        }

        function refreshStats(): string {
            system.refreshStats();
            powerInput.wait(150);
            system.refreshStats();
            powerInput.wait(150);
            return state();
        }

        function requestPower(action: string): string {
            root.lastPowerAction = "";
            powerMenu.opened = true;
            powerMenu.request(action);
            return state();
        }

        function confirmPower(): string {
            powerMenu.confirm();
            return state();
        }

        function cancelPower(): string {
            powerMenu.pendingAction = "";
            return state();
        }

        function showOsd(kind: string, label: string, value: real, muted: bool): string {
            system.showOsd(kind, label, value, muted);
            return state();
        }

        function calendarState(): string {
            let todayCells = 0;
            for (let index = 0; index < 42; index++) {
                if (calendar.sameDay(calendar.dateForCell(index), calendar.today))
                    todayCells++;
            }
            return JSON.stringify({
                year: calendar.shownMonth.getFullYear(),
                month: calendar.shownMonth.getMonth(),
                todayYear: calendar.today.getFullYear(),
                todayMonth: calendar.today.getMonth(),
                todayCells: todayCells
            });
        }

        function previousMonth(): string {
            calendar.previousMonth();
            return calendarState();
        }

        function nextMonth(): string {
            calendar.nextMonth();
            return calendarState();
        }

        function currentMonth(): string {
            calendar.showCurrentMonth();
            return calendarState();
        }

        function panelInteractions(): string {
            powerMenu.opened = true;
            powerInput.wait(300);
            powerInput.keyClick(Qt.Key_Escape);
            if (powerMenu.opened) return "Power Escape failed";
            powerInput.wait(300);
            powerMenu.opened = true;
            powerInput.wait(300);
            powerInput.mouseClick(powerMenu.contentItem, 10, 10);
            if (powerMenu.opened) return "Power outside click failed";

            calendarPanel.opened = true;
            calendarInput.wait(300);
            calendarInput.keyClick(Qt.Key_Escape);
            if (calendarPanel.opened) return "Calendar Escape failed";
            calendarInput.wait(300);
            calendarPanel.opened = true;
            calendarInput.wait(300);
            calendarInput.mouseClick(calendarPanel.contentItem, 10, 10);
            if (calendarPanel.opened) return "Calendar outside click failed";
            return "passed";
        }
    }
}
