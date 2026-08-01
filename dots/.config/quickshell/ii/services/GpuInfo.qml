pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

/**
 * Auto-detects dedicated GPUs (Intel/AMD/NVIDIA) and polls their load
 * and temperature. Integrated GPUs are ignored.
 */
Singleton {
    id: root

    property var gpus: []

    Timer {
        interval: Config.options.resources.updateInterval
        running: Config.ready
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuProc.running = true
        }
    }

    Process {
        id: gpuProc
        running: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", `
            shorten_nvidia() { echo "$1" | sed -E 's/^NVIDIA //; s/GeForce |Quadro |GRID |Arc //; s/ (Laptop|Mobile|Desktop|OEM|Family|Series)//g; s/ GPU$//'; }
            shorten_intel() { local n="$1"; local b="$(echo "$n" | sed -n 's/.*\\[\\([^]]*\\)\\].*/\\1/p')"; [ -n "$b" ] && n="$b"; n="$(echo "$n" | sed -E 's/^(Intel Corporation )?//; s/ (Laptop|Mobile|Desktop)//g')"; echo "Intel $n"; }
            shorten_amd() { local n="$1"; local b="$(echo "$n" | sed -n 's/.*\\[\\([^]]*\\)\\].*/\\1/p')"; [ -n "$b" ] && n="$b"; n="$(echo "$n" | sed -E 's/^(Advanced Micro Devices, Inc. |AMD\\/ATI )?//; s/Radeon \\(TM\\) //; s/ (Laptop|Mobile|Desktop|Gfx|GFX)//g')"; echo "$n"; }
            nvidia_lines="$(nvidia-smi --query-gpu=name,utilization.gpu,temperature.gpu,pci.bus_id --format=csv,noheader,nounits 2>/dev/null)"
            lspci_data="$(lspci -nnmm 2>/dev/null)"
            for card in /sys/class/drm/card[0-9]*; do
                [ -r "$card/device/uevent" ] || continue
                drv="$(sed -n "s/^DRIVER=//p" "$card/device/uevent")"
                [ -n "$drv" ] || continue
                pci="$(sed -n "s/^PCI_ID=//p" "$card/device/uevent" | tr "[:upper:]" "[:lower:]")"
                case "$pci" in
                    8086:*) vendor=intel;; 10de:*) vendor=nvidia;; 1002:*|1022:*) vendor=amd;; *) vendor=other;;
                esac
                cardn="$(basename "$card")"
                devpath="$(readlink -f "$card/device")"
                bus="$(echo "$devpath" | grep -oE "[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\\.[0-9]" | tail -1)"
                bus8="$(echo "$bus" | sed "s/^0000://")"
                case "$bus" in 0000:00:*) kind=integrated;; *) kind=dedicated;; esac
                [ "$vendor" = "nvidia" ] && kind=dedicated
                [ "$kind" = "integrated" ] && continue
                name="$(echo "$lspci_data" | awk -F"\\"" -v b="$bus8" "\\$1 ~ b && \\$2 ~ /VGA|3D|Display/ {print \\$6; exit}")"
                name="$(echo "$name" | sed "s/ \\[[0-9a-f]*\\]$//")"
                [ -z "$name" ] && name="$vendor GPU ($cardn)"
                load=-1; temp=-1
                case "$vendor" in
                    nvidia)
                        if [ -n "$nvidia_lines" ]; then
                            line="$(echo "$nvidia_lines" | grep "$bus8")"
                            if [ -n "$line" ]; then
                                name="$(echo "$line" | cut -d, -f1)"
                                load="$(echo "$line" | cut -d, -f2 | tr -d " ")"
                                temp="$(echo "$line" | cut -d, -f3 | tr -d " ")"
                            fi
                        fi;;
                    amd)
                        l="$(cat "$card/device/gpu_busy_percent" 2>/dev/null)"; [ -n "$l" ] && load="$l"
                        for h in "$card/device/hwmon/hwmon"*/; do
                            t="$(cat "$h"temp1_input 2>/dev/null)"
                            [ -n "$t" ] && temp=$((t/1000)) && break
                        done;;
                    intel)
                        cur="$(cat "$card/device/gt/gt0/rps_cur_freq_mhz" 2>/dev/null)"
                        mx="$(cat "$card/device/gt/gt0/rps_max_freq_mhz" 2>/dev/null)"
                        if [ -n "$cur" ] && [ -n "$mx" ] && [ "$mx" -gt 0 ] 2>/dev/null; then
                            load=$((cur*100/mx))
                        fi
                        for h in "$card/device/hwmon/hwmon"*/; do
                            t="$(cat "$h"temp1_input 2>/dev/null)"
                            [ -n "$t" ] && temp=$((t/1000)) && break
                        done;;
                esac
                case "$vendor" in
                    nvidia) name="$(shorten_nvidia "$name")";;
                    intel) name="$(shorten_intel "$name")";;
                    amd) name="$(shorten_amd "$name")";;
                esac
                printf "%s|%s|%s|%s|%s|%s\\n" "$vendor" "$kind" "$name" "$cardn" "$load" "$temp"
            done
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                if (!text) {
                    root.gpus = []
                    return
                }

                const list = []
                for (const line of text.split('\n')) {
                    if (!line.trim()) continue
                    const [vendor, kind, name, card, load, temp] = line.split('|')
                    const parsedLoad = parseInt(load)
                    const parsedTemp = parseFloat(temp)
                    list.push({
                        vendor: vendor,
                        kind: kind,
                        name: name || vendor,
                        card: card,
                        load: isNaN(parsedLoad) ? -1 : parsedLoad,
                        temperature: isNaN(parsedTemp) ? -1 : parsedTemp
                    })
                }
                root.gpus = list
            }
        }
    }
}
