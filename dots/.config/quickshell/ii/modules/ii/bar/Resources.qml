import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    property int loadIndex: 0
    readonly property int loadCount: GpuInfo.gpus.length + 1
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    function cycleLoad(up) {
        if (GpuInfo.gpus.length === 0) {
            root.loadIndex = 0
            return
        }
        const count = root.loadCount
        let next = root.loadIndex + (up ? 1 : -1)
        if (next < 0) next = count - 1
        if (next >= count) next = 0
        root.loadIndex = next
        cpuResource.animateValue = true
        cpuAnimationResetTimer.restart()
    }

    function currentLoad() {
        if (root.loadIndex === 0) return ResourceUsage.cpuUsage
        const gpu = GpuInfo.gpus[root.loadIndex - 1]
        if (!gpu || gpu.load < 0) return 0
        return gpu.load / 100
    }

    function currentIcon() {
        if (root.loadIndex === 0 || root.loadIndex > GpuInfo.gpus.length) return "planner_review"
        return "developer_board"
    }

    Timer {
        id: cpuAnimationResetTimer
        interval: 500
        onTriggered: cpuResource.animateValue = false
    }

    Binding {
        target: root
        property: "loadIndex"
        value: 0
        when: GpuInfo.gpus.length === 0
    }

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            id: cpuResource
            iconName: root.currentIcon()
            percentage: root.currentLoad()
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            cycleOnScroll: GpuInfo.gpus.length > 0
            onScrollCycled: (up) => {
                cpuResource.scrollPulse(up)
            }
            onScrollMidpoint: (up) => {
                root.cycleLoad(up)
            }
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
