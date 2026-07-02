import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var tabButtonList: [
        {"name": Translation.tr("Timer"), "icon": "search_activity"},
        {"name": Translation.tr("Customize"), "icon": "tune"}
    ]

<<<<<<< HEAD
    // Pomodoro keybinds
=======
>>>>>>> pr-3463
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                tabBar.incrementCurrentIndex();
            } else if (event.key === Qt.Key_PageUp) {
                tabBar.decrementCurrentIndex();
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Space || event.key === Qt.Key_S) {
            if (tabBar.currentIndex === 0) {
                TimerService.togglePomodoro()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_R) {
            if (tabBar.currentIndex === 0) {
                TimerService.resetPomodoro()
            }
            event.accepted = true
<<<<<<< HEAD
=======
        } else if (event.key === Qt.Key_L) {
            TimerService.stopwatchRecordLap()
            event.accepted = true
>>>>>>> pr-3463
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        SecondaryTabBar {
            id: tabBar
            currentIndex: swipeView.currentIndex

            Repeater {
                model: root.tabButtonList
                delegate: SecondaryTabButton {
                    buttonText: modelData.name
                    buttonIcon: modelData.icon
                }
            }
        }

        Item {
            id: swipeView
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            property int currentIndex: tabBar.currentIndex

            // Tabs
            PomodoroTimer {}
            PomodoroSettings {}
        }
    }
}
