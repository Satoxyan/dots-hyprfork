pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    // Safety truncation for long GPU names
    function shortenName(name) {
        const maxLength = 24;
        return name.length > maxLength ? name.slice(0, maxLength - 1) + "…" : name;
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                spacing: 4
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                }
                StyledPopupValueRow {
                    visible: ResourceUsage.cpuTemperature >= 0
                    icon: "device_thermostat"
                    label: Translation.tr("Temperature:")
                    value: `${Math.round(ResourceUsage.cpuTemperature)}°C`
                }
            }
        }

        Column {
            visible: GpuInfo.gpus.length > 0
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "developer_board"
                label: "GPU"
            }
            Row {
                spacing: 12
                Repeater {
                    model: GpuInfo.gpus
                    delegate: Column {
                        required property var modelData
                        spacing: 4

                        StyledPopupValueRow {
                            icon: "developer_board"
                            label: root.shortenName(modelData.name)
                            value: ""
                        }
                        StyledPopupValueRow {
                            icon: "bolt"
                            label: Translation.tr("Load:")
                            value: modelData.load >= 0 ? `${modelData.load}%` : "--"
                        }
                        StyledPopupValueRow {
                            icon: "device_thermostat"
                            label: Translation.tr("Temperature:")
                            value: modelData.temperature >= 0 ? `${Math.round(modelData.temperature)}°C` : "--"
                        }
                    }
                }
            }
        }
    }
}
