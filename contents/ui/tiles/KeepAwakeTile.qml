import QtQuick
import org.kde.plasma.private.batterymonitor
import ".."

Tile {
    id: tile

    checked: inhibition.isManuallyInhibited
    iconName: checked ? "system-suspend-inhibited" : "system-suspend-uninhibited"
    label: i18n("Keep awake")
    status: checked ? i18n("Sleep and lock blocked") : i18n("Off")

    // The same manual inhibition the Power and Battery applet offers
    onActivated: {
        if (checked) {
            inhibition.uninhibit();
        } else {
            inhibition.inhibit(i18n("Laetum Control Center is keeping the computer awake"));
        }
    }

    InhibitionControl {
        id: inhibition
        isSilent: true
    }
}
