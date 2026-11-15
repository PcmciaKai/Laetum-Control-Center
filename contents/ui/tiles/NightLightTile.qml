import QtQuick
import ".."

Tile {
    id: tile

    readonly property var nightLight: root.nightLight

    available: nightLight !== null && nightLight.available
    checked: nightLight !== null && nightLight.active
    iconName: checked ? "redshift-status-on" : "redshift-status-off"
    label: i18n("Night Light")
    status: {
        if (!nightLight || !nightLight.enabled) {
            return i18n("Off");
        }
        if (nightLight.inhibited) {
            if (!nightLight.pausedHere) {
                return i18n("Paused by an app");
            }
            return nightLight.resumeAt > 0
                ? i18nc("Night Light is paused until a time", "Paused until %1", Qt.formatTime(new Date(nightLight.resumeAt), Qt.locale().timeFormat(Locale.ShortFormat)))
                : i18n("Paused");
        }
        if (nightLight.daylight && nightLight.hasSwitchingTimes && nightLight.scheduledTransition > 0) {
            return i18nc("Night Light starts at a time", "From %1",
                Qt.formatTime(new Date(nightLight.scheduledTransition), Qt.locale().timeFormat(Locale.ShortFormat)));
        }
        return i18nc("Colour temperature", "On · %1 K", nightLight.currentTemperature);
    }
    hasDetails: true
    detailsTooltip: i18n("Pause, temperature and more")

    // Switched off: switch it on. Otherwise pause and resume, like the Brightness and Color
    // applet does; › has the timed pauses and the temperature
    onActivated: {
        if (!nightLight.enabled) {
            nightLight.setEnabled(true);
        } else {
            nightLight.togglePause();
        }
    }
    onDetailsRequested: root.pageRequested("nightlight")
}
