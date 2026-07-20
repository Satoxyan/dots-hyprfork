pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string apiBaseUrl: "https://lrclib.net/api"

    property string currentArtist: ""
    property string currentTitle: ""
    property string currentAlbum: ""

    property var syncedLyrics: []
    property string plainLyrics: ""

    property bool fetching: false
    property bool available: false
    property string lastError: ""

    // Cache dir
    readonly property string cacheDir: FileUtils.trimFileProtocol(`${Directories.cache}/media/lyrics`)

    // Pending track for debounce
    property string pendingArtist: ""
    property string pendingTitle: ""
    property string pendingAlbum: ""

    // ── Public API ─────────────────────────────────────────────────────────────

    function lookup(artist, title, album) {
        root.available = false
        root.syncedLyrics = []
        root.plainLyrics = ""
        root.lastError = ""

        if (!artist || !title) return

        root.pendingArtist = artist
        root.pendingTitle = title
        root.pendingAlbum = album || ""
        fetchDebounce.restart()
    }

    function getCurrentLineIndex(position) {
        var lyrics = root.syncedLyrics
        if (!lyrics || lyrics.length === 0) return -1
        for (var i = lyrics.length - 1; i >= 0; i--) {
            if (position >= lyrics[i].time) return i
        }
        return -1
    }

    // ── Debounce ───────────────────────────────────────────────────────────────

    Timer {
        id: fetchDebounce
        interval: 300
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["mkdir", "-p", root.cacheDir])
            doFetch(root.pendingArtist, root.pendingTitle, root.pendingAlbum)
        }
    }

    // ── Fetch from LRCLIB ──────────────────────────────────────────────────────

    function doFetch(artist, title, album) {
        root.fetching = true

        var url = root.apiBaseUrl + "/get"
            + "?artist_name=" + encodeURIComponent(artist)
            + "&track_name=" + encodeURIComponent(title)
        if (album) url += "&album_name=" + encodeURIComponent(album)

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return

            root.fetching = false
            if (artist !== root.pendingArtist || title !== root.pendingTitle) return

            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText)
                    root.currentArtist = response.artistName || artist
                    root.currentTitle = response.trackName || title
                    root.currentAlbum = response.albumName || album

                    if (response.syncedLyrics) {
                        root.syncedLyrics = parseLRC(response.syncedLyrics)
                    }
                    root.plainLyrics = response.plainLyrics || ""
                    root.available = true
                } catch (e) {
                    root.lastError = "Parse error: " + e.toString()
                }
            } else if (xhr.status === 404) {
                // Search fallback: try without album
                if (album && root.pendingAlbum) {
                    root.pendingAlbum = ""
                    fetchDebounce.restart()
                    return
                }
                root.lastError = "Not found"
            } else {
                root.lastError = "HTTP " + xhr.status
            }
        }

        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "IllogicalImpulseShell/1.0")
        xhr.send()
    }

    // ── LRC Parser ─────────────────────────────────────────────────────────────

    function parseLRC(lrcText) {
        if (!lrcText) return []
        var lines = lrcText.split("\n")
        var result = []
        var regex = /\[(\d+):(\d+(?:\.\d+)?)\](.*)/
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].match(regex)
            if (match) {
                var minutes = parseInt(match[1])
                var seconds = parseFloat(match[2])
                var text = match[3].trim()
                if (text) {
                    result.push({ time: minutes * 60 + seconds, text: text })
                }
            }
        }
        result.sort(function(a, b) { return a.time - b.time })
        return result
    }
}
