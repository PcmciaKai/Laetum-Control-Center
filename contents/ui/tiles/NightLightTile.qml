import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.plasma.workspace.dbus as DBus
import ".."

Tile {
    id: tile

    available: nightLight.available
    checked: nightLight.enabled && !nightLight.inhibited
    iconName: checked ? "redshift-status-on" : "redshift-status-off"
    label: i18n("Night Light")
    status: {
        if (!nightLight.enabled) {
            return i18n("Off");
        }
        if (nightLight.inhibited) {
            return nightLight.inhibitedFromApplet ? i18n("Paused") : i18n("Paused by an app");
        }
        if (nightLight.daylight && nightLight.hasSwitchingTimes && nightLight.scheduledTransitionStartTime > 0) {
            return i18nc("Night Light starts at a time", "From %1",
                Qt.formatTime(new Date(nightLight.scheduledTransitionStartTime), Qt.locale().timeFormat(Locale.ShortFormat)));
        }
        return i18nc("Colour temperature", "On · %1 K", nightLight.currentTemperature);
    }
    hasDetails: true
    detailsTooltip: i18n("Night Light settings")

    // Night Light is switched on and off in its settings; the tile pauses and resumes it,
    // like the Brightness and Color applet does
    onActivated: {
        if (!nightLight.enabled) {
            root.openKcm("kcm_nightlight");
        } else if (nightLight.togglable) {
            NightLightInhibitor.toggleInhibition();
        }
    }
    onDetailsRequested: root.openKcm("kcm_nightlight")

    DBus.Properties {
        id: nightLight
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"

        readonly property bool available: Boolean(properties.available)
        readonly property bool enabled: Boolean(properties.enabled)
        readonly property bool inhibited: Boolean(properties.inhibited)
        readonly property bool inhibitedFromApplet: NightLightInhibitor.inhibited
        readonly property int mode: Number(properties.mode)
        readonly property bool daylight: Boolean(properties.daylight)
        readonly property int currentTemperature: Number(properties.currentTemperature)
        readonly property double scheduledTransitionStartTime: Number(properties.scheduledTransitionDateTime) * 1000
        readonly property bool hasSwitchingTimes: mode !== 3
        readonly property bool togglable: !inhibited || inhibitedFromApplet
    }
}
