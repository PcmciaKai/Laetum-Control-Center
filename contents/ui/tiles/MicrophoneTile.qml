import QtQuick
import org.kde.plasma.private.volume
import ".."

Tile {
    id: tile

    readonly property var source: PreferredDevice.source

    available: source !== null
    checked: source !== null && !source.muted
    iconName: checked ? "microphone-sensitivity-high" : "microphone-sensitivity-muted"
    label: i18n("Microphone")
    status: checked ? i18n("On") : i18n("Muted")
    hasDetails: true
    detailsTooltip: i18n("Audio devices")

    onActivated: {
        if (source) {
            source.muted = !source.muted;
        }
    }
    onDetailsRequested: root.pageRequested("audio")
}
