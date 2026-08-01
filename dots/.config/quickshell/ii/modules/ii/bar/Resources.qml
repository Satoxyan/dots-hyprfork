import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    property int loadIndex: 0
    property int ramIndex: 0
    readonly property int loadCount: GpuInfo.gpus.length + 1
    readonly property bool canCycleLoad: GpuInfo.gpus.length > 0 && !gpuResource.shown
    readonly property bool canCycleRam: ResourceUsage.swapTotal > 0 && !swapResource.shown
    readonly property bool noMediaPlaying: MprisController.activePlayer?.trackTitle == null
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onWheel: (wheel) => {
        const up = wheel.angleDelta.y > 0
        if (ramResource.hovered && root.canCycleRam) {
            ramResource.scrollPulse(up)
        } else if (cpuResource.hovered && root.canCycleLoad) {
            cpuResource.scrollPulse(up)
        }
    }

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

    function cycleRam(up) {
        if (ResourceUsage.swapTotal <= 0) {
            root.ramIndex = 0
            return
        }
        root.ramIndex = root.ramIndex === 0 ? 1 : 0
        ramResource.animateValue = true
        ramAnimationResetTimer.restart()
    }

    function currentRamLoad() {
        if (root.ramIndex === 0) return ResourceUsage.memoryUsedPercentage
        return ResourceUsage.swapUsedPercentage
    }

    function currentRamIcon() {
        return root.ramIndex === 0 ? "memory" : "swap_horiz"
    }

    Timer {
        id: cpuAnimationResetTimer
        interval: 500
        onTriggered: cpuResource.animateValue = false
    }

    Timer {
        id: ramAnimationResetTimer
        interval: 500
        onTriggered: ramResource.animateValue = false
    }

    Binding {
        target: root
        property: "loadIndex"
        value: 0
        when: GpuInfo.gpus.length === 0
    }

    Binding {
        target: root
        property: "ramIndex"
        value: 0
        when: ResourceUsage.swapTotal <= 0
    }

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            id: ramResource
            iconName: root.currentRamIcon()
            percentage: root.currentRamLoad()
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            onScrollMidpoint: (up) => {
                root.cycleRam(up)
            }
        }

        Resource {
            id: swapResource
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                root.noMediaPlaying ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            id: cpuResource
            iconName: root.currentIcon()
            percentage: root.currentLoad()
            shown: Config.options.bar.resources.alwaysShowCpu || 
                root.noMediaPlaying ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            onScrollMidpoint: (up) => {
                root.cycleLoad(up)
            }
        }

        Resource {
            id: gpuResource
            iconName: "developer_board"
            percentage: GpuInfo.gpus.length > 0
                ? (GpuInfo.gpus[0].load >= 0 ? GpuInfo.gpus[0].load / 100 : 0)
                : 0
            shown: GpuInfo.gpus.length > 0 &&
                (Config.options.bar.resources.alwaysShowGpu || root.alwaysShowAllResources) &&
                root.noMediaPlaying
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
