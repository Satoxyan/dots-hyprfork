import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property int panelWidth: 520
    property int panelHeight: 420
    property int selectedIndex: -1

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.projectorMenuOpen

        function hide() {
            GlobalStates.projectorMenuOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: panelWidth
        implicitHeight: panelHeight
        WlrLayershell.namespace: "quickshell:projectorMenu"
        WlrLayershell.keyboardFocus: GlobalStates.projectorMenuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            right: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        StyledRectangularShadow {
            target: sidebarBackground
        }
        Rectangle {
            id: sidebarBackground
            anchors {
                fill: parent
                margins: Appearance.sizes.hyprlandGapsOut
                leftMargin: Appearance.sizes.elevationMargin
            }
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
            focus: GlobalStates.projectorMenuOpen

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 12

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer0
                    text: "Projector"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer1

                    GridLayout {
                        anchors {
                            fill: parent
                            margins: 8
                        }
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                { icon1: "connected_tv", icon2: "tv", label: "PC only", flip: false },
                                { icon1: "connected_tv", icon2: "connected_tv", label: "Mirror", flip: false },
                                { icon1: "connected_tv", icon2: "connected_tv", label: "Extend", flip: true },
                                { icon1: "tv", icon2: "connected_tv", label: "Second screen only", flip: false }
                            ]

                            Rectangle {
                                id: btn
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Appearance.rounding.normal
                                color: index === root.selectedIndex ? Appearance.colors.colPrimary : (btn.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2)
                                border.width: 1
                                border.color: "transparent"

                                property bool containsMouse: false

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 4

                                        MaterialSymbol {
                                            iconSize: 70
                                            color: index === root.selectedIndex ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                            fill: btn.containsMouse ? 1 : 0
                                            text: modelData.icon1
                                            transform: [
                                                Scale {
                                                    xScale: modelData.flip ? -1 : 1
                                                    origin.x: 35
                                                    origin.y: 35
                                                }
                                            ]
                                        }
                                        MaterialSymbol {
                                            iconSize: 70
                                            color: index === root.selectedIndex ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                            fill: btn.containsMouse ? 1 : 0
                                            text: modelData.icon2
                                        }
                                    }
                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: index === root.selectedIndex ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                                        text: modelData.label
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: btn.containsMouse = true
                                    onExited: btn.containsMouse = false
                                    onClicked: root.selectedIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "projectorMenu"

        function toggle(): void {
            GlobalStates.projectorMenuOpen = !GlobalStates.projectorMenuOpen;
        }

        function close(): void {
            GlobalStates.projectorMenuOpen = false;
        }

        function open(): void {
            GlobalStates.projectorMenuOpen = true;
        }
    }

    GlobalShortcut {
        name: "projectorMenuToggle"
        description: "Toggles duplicated right sidebar on press"

        onPressed: {
            GlobalStates.projectorMenuOpen = !GlobalStates.projectorMenuOpen;
        }
    }
    GlobalShortcut {
        name: "projectorMenuOpen"
        description: "Opens duplicated right sidebar on press"

        onPressed: {
            GlobalStates.projectorMenuOpen = true;
        }
    }
    GlobalShortcut {
        name: "projectorMenuClose"
        description: "Closes duplicated right sidebar on press"

        onPressed: {
            GlobalStates.projectorMenuOpen = false;
        }
    }
}
