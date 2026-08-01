import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    property bool shown: true
    clip: true
    visible: width > 0 && height > 0
    implicitWidth: resourceRowLayout.x < 0 ? 0 : resourceRowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    property bool warning: percentage * 100 >= warningThreshold
    readonly property bool hovered: mouseArea.containsMouse
    signal scrollMidpoint(bool up)
    property int scrollDirection: 1
    property bool animateValue: false
    property double displayValue: root.percentage

    onPercentageChanged: root.displayValue = root.percentage

    Behavior on displayValue {
        enabled: root.animateValue
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    function scrollPulse(up) {
        root.scrollDirection = up ? 1 : -1
        const shift = Math.max(4, percentageText.implicitHeight * 0.9)
        const iconShift = Math.max(4, iconContainer.height * 0.7)
        textSlideOut.to = up ? -shift : shift
        textSlideIn.from = up ? shift : -shift
        iconSlideOut.to = up ? -iconShift : iconShift
        iconSlideIn.from = up ? iconShift : -iconShift
        cycleScrollAnim.restart()
    }

    SequentialAnimation {
        id: cycleScrollAnim
        ParallelAnimation {
            NumberAnimation {
                id: textSlideOut
                target: textSlide
                property: "y"
                from: 0
                duration: 90
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                id: textFadeOut
                target: percentageText
                property: "opacity"
                from: 1
                to: 0
                duration: 90
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                id: iconSlideOut
                target: iconSlide
                property: "y"
                from: 0
                duration: 90
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                id: iconFadeOut
                target: iconMaterial
                property: "opacity"
                from: 1
                to: 0
                duration: 90
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: root.scrollMidpoint(root.scrollDirection === 1)
        }
        ParallelAnimation {
            NumberAnimation {
                id: textSlideIn
                target: textSlide
                property: "y"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                id: textFadeIn
                target: percentageText
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                id: iconSlideIn
                target: iconSlide
                property: "y"
                to: 0
                duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                id: iconFadeIn
                target: iconMaterial
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }

    RowLayout {
        id: resourceRowLayout
        spacing: 2
        x: shown ? 0 : -resourceRowLayout.width
        anchors {
            verticalCenter: parent.verticalCenter
        }

        ClippedFilledCircularProgress {
            id: resourceCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: root.displayValue
            implicitSize: 20
            colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
            accountForLightBleeding: !root.warning
            enableAnimation: false

            Item {
                id: iconContainer
                anchors.centerIn: parent
                width: resourceCircProg.implicitSize
                height: resourceCircProg.implicitSize
                clip: true

                MaterialSymbol {
                    id: iconMaterial
                    anchors.centerIn: parent
                    font.weight: Font.DemiBold
                    fill: 1
                    text: iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                    transform: Translate {
                        id: iconSlide
                        y: 0
                    }
                }
            }
        }

        Item {
            id: textContainer
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: fullPercentageTextMetrics.width
            implicitHeight: percentageText.implicitHeight
            clip: true

            TextMetrics {
                id: fullPercentageTextMetrics
                text: "100"
                font.pixelSize: Appearance.font.pixelSize.small
            }

            StyledText {
                id: percentageText
                anchors.centerIn: parent
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: `${Math.round(root.percentage * 100).toString()}`
                transform: Translate {
                    id: textSlide
                    y: 0
                }
            }
        }

        Behavior on x {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: resourceRowLayout.x >= 0 && root.width > 0 && root.visible
    }

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }
}
