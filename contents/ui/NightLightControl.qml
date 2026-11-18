import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.plasma.workspace.dbus as DBus

// KWin's Night Light, shared by the tile and the Night Light page (one instance in main.qml,
// so a timed pause keeps running while the page is closed).
// Pausing goes through the same inhibitor as the Brightness and Color applet; switching it on
// and off and the night temperature are KWin's own settings (kwinrc), like System Settings.
Item {
    id: control

    // ---- State, from KWin ----
    readonly property bool available: Boolean(nightLight.properties.available)
    // Switched on in the settings. Not called "enabled": that would shadow Item.enabled
    readonly property bool switchedOn: Boolean(nightLight.properties.enabled)
    readonly property bool inhibited: Boolean(nightLight.properties.inhibited)
    // Paused by us (or the Brightness and Color applet), rather than by another app
    readonly property bool pausedHere: NightLightInhibitor.inhibited
    readonly property bool togglable: !inhibited || pausedHere
    readonly property bool active: switchedOn && !inhibited
    readonly property int mode: Number(nightLight.properties.mode)
    readonly property bool daylight: Boolean(nightLight.properties.daylight)
    readonly property int currentTemperature: Number(nightLight.properties.currentTemperature)
    readonly property double scheduledTransition: Number(nightLight.properties.scheduledTransitionDateTime) * 1000
    readonly property double previousTransition: Number(nightLight.properties.previousTransitionDateTime) * 1000
    // Mode 3 is "Always on": no sunset or sunrise
    readonly property bool hasSwitchingTimes: mode !== 3

    // The night colour temperature from kwinrc (KWin's default is 4500 K)
    property int nightTemperature: 4500
    readonly property int minimumTemperature: 1000
    readonly property int maximumTemperature: 6500

    // ---- Timed pause ----
    // When a pause from "Pause for an hour" or "until tomorrow" ends (ms since the epoch); 0 = none
    property double resumeAt: 0

    // The next morning: the coming sunrise at night, or tomorrow's (this morning's + a day) by
    // day. "Always on" has no sunrise, so 6:00 tomorrow.
    function nextMorning() {
        if (hasSwitchingTimes && !daylight && scheduledTransition > Date.now()) {
            return scheduledTransition;
        }
        if (hasSwitchingTimes && daylight && previousTransition > 0) {
            let morning = previousTransition + 24 * 3600 * 1000;
            while (morning <= Date.now()) {
                morning += 24 * 3600 * 1000;
            }
            return morning;
        }
        const morning = new Date();
        morning.setDate(morning.getDate() + 1);
        morning.setHours(6, 0, 0, 0);
        return morning.getTime();
    }

    function pause(until) {
        if (!pausedHere && togglable) {
            NightLightInhibitor.toggleInhibition();
        }
        resumeAt = until;
    }

    function resume() {
        resumeAt = 0;
        if (pausedHere) {
            NightLightInhibitor.toggleInhibition();
        }
    }

    // Pause or resume (the tile)
    function togglePause() {
        if (pausedHere) {
            resume();
        } else if (togglable) {
            NightLightInhibitor.toggleInhibition();
        }
    }

    // Resumed elsewhere (the tile, the Brightness and Color applet): forget the timer
    Connections {
        target: NightLightInhibitor
        function onInhibitedChanged() {
            if (!NightLightInhibitor.inhibited) {
                control.resumeAt = 0;
            }
        }
    }

    Timer {
        interval: 20000
        repeat: true
        running: control.resumeAt > 0
        onTriggered: {
            if (Date.now() >= control.resumeAt) {
                control.resume();
            }
        }
    }

    // ---- Settings (kwinrc) ----
    function setEnabled(on) {
        writeSetting("Active", on ? "true" : "false");
    }

    function setNightTemperature(kelvin) {
        nightTemperature = kelvin;
        writeSetting("NightTemperature", String(Math.round(kelvin)));
    }

    // --notify tells KWin about the change, the way System Settings does (KWin's general
    // "reconfigure" doesn't reload Night Light)
    function writeSetting(key, value) {
        settingWriter.connectSource("kwriteconfig6 --notify --file kwinrc --group NightColor --key " + key + " " + value
            + " # " + Date.now());
    }

    // Shows a temperature right away while the slider is dragged, without saving it
    function preview(kelvin) {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin.NightLight",
            "path": "/org/kde/KWin/NightLight",
            "iface": "org.kde.KWin.NightLight",
            "member": "preview",
            "arguments": [new DBus.uint32(Math.round(kelvin))]
        }, () => {}, () => {});
    }

    function stopPreview() {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin.NightLight",
            "path": "/org/kde/KWin/NightLight",
            "iface": "org.kde.KWin.NightLight",
            "member": "stopPreview"
        }, () => {}, () => {});
    }

    function readNightTemperature() {
        temperatureReader.connectSource("kreadconfig6 --file kwinrc --group NightColor --key NightTemperature --default 4500");
    }

    Component.onCompleted: readNightTemperature()

    P5Support.DataSource {
        id: settingWriter
        engine: "executable"
        onNewData: source => disconnectSource(source)
    }

    P5Support.DataSource {
        id: temperatureReader
        engine: "executable"
        onNewData: (source, data) => {
            const kelvin = parseInt((data.stdout || "").trim());
            if (!isNaN(kelvin)) {
                control.nightTemperature = kelvin;
            }
            disconnectSource(source);
        }
    }

    DBus.Properties {
        id: nightLight
        busType: DBus.BusType.Session
        service: "org.kde.KWin.NightLight"
        path: "/org/kde/KWin/NightLight"
        iface: "org.kde.KWin.NightLight"
    }
}
