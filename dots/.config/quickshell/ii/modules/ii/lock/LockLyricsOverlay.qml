pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer

    property var artUrl: player?.trackArtUrl
    property string artFileName: Qt.md5(artUrl ?? "")
    property string artFilePath: `${Directories.coverArt}/${artFileName}`
    property string displayedArtFilePath: ""
    property string lastValidArtUrl: ""
    property string pendingArtUrl: ""

    property color artDominantColor: ColorUtils.mix(
        colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer, 0.8
    ) ?? Appearance.m3colors.m3secondaryContainer

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    implicitWidth: mainLayout.implicitWidth + 24
    implicitHeight: mainLayout.implicitHeight + 24

    // ── Cover art download ──────────────────────────────────────────────
    onArtUrlChanged: { artDebounce.restart() }

    Timer {
        id: artDebounce
        interval: 150
        onTriggered: {
            const url = root.artUrl
            if (!url || url.length === 0) return
            if (url === root.lastValidArtUrl) return
            root.pendingArtUrl = url
            coverArtDownloader.running = false
            coverArtDownloader.targetFile = url
            coverArtDownloader.artFilePath = root.artFilePath
            coverArtDownloader.running = true
        }
    }

    Process {
        id: coverArtDownloader
        property string targetFile: ""
        property string artFilePath: ""
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: {
            if (coverArtDownloader.targetFile !== root.pendingArtUrl) return
            root.lastValidArtUrl = root.pendingArtUrl
            root.displayedArtFilePath = Qt.resolvedUrl(coverArtDownloader.artFilePath)
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    // ── Main layout ─────────────────────────────────────────────────────
    RowLayout {
        id: mainLayout
        anchors.centerIn: parent
        spacing: 18

        // ── Left: cover art + controls ──────────────────────────────────
        ColumnLayout {
            id: leftPanel
            spacing: 8

            Rectangle {
                id: artBox
                Layout.preferredWidth: 140
                Layout.preferredHeight: 140
                Layout.alignment: Qt.AlignHCenter
                radius: Appearance.rounding.verysmall
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.3)

                StyledImage {
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: blendedColors.colSubtext
                text: root.player
                    ? `${StringUtils.friendlyTimeForSeconds(root.player.position)} / ${StringUtils.friendlyTimeForSeconds(root.player.length)}`
                    : "0:00 / 0:00"
                horizontalAlignment: Text.AlignHCenter
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                active: root.player?.canSeek ?? false
                sourceComponent: StyledSlider {
                    configuration: StyledSlider.Configuration.Wavy
                    highlightColor: blendedColors.colPrimary
                    trackColor: blendedColors.colSecondaryContainer
                    handleColor: blendedColors.colPrimary
                    value: root.player ? root.player.position / root.player.length : 0
                    onMoved: {
                        if (root.player)
                            root.player.position = value * root.player.length
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                active: !(root.player?.canSeek ?? false)
                sourceComponent: StyledProgressBar {
                    wavy: root.player?.isPlaying
                    highlightColor: blendedColors.colPrimary
                    trackColor: blendedColors.colSecondaryContainer
                    value: root.player ? root.player.position / root.player.length : 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                RippleButton {
                    implicitWidth: 36; implicitHeight: 36
                    buttonRadius: height / 2
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    onClicked: root.player?.previous()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 20; fill: 1
                        text: "skip_previous"
                        color: blendedColors.colOnSecondaryContainer
                    }
                }

                RippleButton {
                    implicitWidth: 44; implicitHeight: 44
                    buttonRadius: height / 2
                    colBackground: blendedColors.colSecondaryContainer
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    onClicked: root.player?.togglePlaying()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 24; fill: 1
                        text: (root.player?.playbackState === MprisPlaybackState.Playing) ? "pause" : "play_arrow"
                        color: blendedColors.colOnSecondaryContainer
                        Behavior on text { enabled: false }
                    }
                }

                RippleButton {
                    implicitWidth: 36; implicitHeight: 36
                    buttonRadius: height / 2
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    onClicked: root.player?.next()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: 20; fill: 1
                        text: "skip_next"
                        color: blendedColors.colOnSecondaryContainer
                    }
                }
            }
        }

        // ── Right: lyrics ───────────────────────────────────────────────
        Item {
            id: lyricsPanel
            Layout.preferredWidth: 380
            Layout.preferredHeight: 280
            clip: true

            property int currentIndex: -1

            onCurrentIndexChanged: {
                if (currentIndex < 0) return
                var item = lyricsRepeater.itemAt(currentIndex)
                if (item) {
                    var targetY = item.y - lyricsPanel.height / 2 + 16
                    targetY = Math.max(0, Math.min(targetY, lyricsFlickable.contentHeight - lyricsPanel.height))
                    lyricsFlickable.contentY = targetY
                }
            }

            Flickable {
                id: lyricsFlickable
                anchors.fill: parent
                contentHeight: lyricsColumn.height + 20
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                ScrollBar.vertical: StyledScrollBar {}

                Column {
                    id: lyricsColumn
                    width: parent.width
                    spacing: 2
                    topPadding: 10
                    bottomPadding: 10

                            Repeater {
                                id: lyricsRepeater
                                model: Lyrics.syncedLyrics

                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: parent.width
                            height: 32

                            StyledText {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                    margins: 8
                                }
                                font.pixelSize: Appearance.font.pixelSize.normal
                                    color: {
                                        if (!Lyrics.available) return "transparent"
                                        if (index === lyricsPanel.currentIndex)
                                            return blendedColors.colPrimary
                                        if (modelData.time < (Lyrics.syncedLyrics[lyricsPanel.currentIndex]?.time ?? 0))
                                            return ColorUtils.transparentize(blendedColors.colSubtext, 0.4)
                                        return blendedColors.colOnLayer0
                                    }
                                text: modelData.text
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.weight: index === lyricsPanel.currentIndex ? Font.Bold : Font.Normal

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: emptyText.implicitHeight
                        visible: !Lyrics.available && !Lyrics.fetching
                        StyledText {
                            id: emptyText
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: blendedColors.colSubtext
                            text: Lyrics.lastError.length > 0 ? Lyrics.lastError : "No lyrics"
                        }
                    }

                    Item {
                        width: parent.width
                        implicitHeight: loadingText.implicitHeight
                        visible: Lyrics.fetching
                        StyledText {
                            id: loadingText
                            anchors.centerIn: parent
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: blendedColors.colSubtext
                            text: "Loading lyrics..."
                        }
                    }
                }
            }
        }
    }

    // ── Close button ────────────────────────────────────────────────────
    RippleButton {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -4
        implicitWidth: 28
        implicitHeight: 28
        buttonRadius: height / 2
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive
        rippleEnabled: false
        onClicked: GlobalStates.lyricsActive = false
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            iconSize: 16; fill: 1
            text: "close"
            color: blendedColors.colOnSecondaryContainer
        }
    }

    // ── Lyrics sync timer ───────────────────────────────────────────────
    Timer {
        id: syncTimer
        interval: 250
        repeat: true
        running: GlobalStates.lyricsActive && root.player != null
        onTriggered: {
            if (root.player && Lyrics.syncedLyrics.length > 0) {
                lyricsPanel.currentIndex = Lyrics.getCurrentLineIndex(root.player.position)
            }
        }
    }

    // ── Auto-lookup on track change ─────────────────────────────────────
    property string _lastKey: ""

    onVisibleChanged: { if (visible) scheduleLookup() }

    onPlayerChanged: { scheduleLookup() }

    Connections {
        target: root.player
        function onTrackTitleChanged() { scheduleLookup() }
        function onTrackArtistChanged() { scheduleLookup() }
    }

    function scheduleLookup() {
        if (!root.player || !root.player.trackTitle) return
        var key = root.player.trackTitle + "||" + root.player.trackArtist
        if (key === root._lastKey) return
        root._lastKey = key
        lookupDebounce.restart()
    }

    Timer {
        id: lookupDebounce
        interval: 300
        onTriggered: {
            if (root.player) {
                Lyrics.lookup(
                    root.player.trackArtist || "",
                    root.player.trackTitle || ""
                )
            }
        }
    }
}
