import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import ".."

// Night Light: timed pauses and the night colour temperature, with on/off in the header.
// The state and the pause timer live in root.nightLight, so a pause outlasts the page.
ColumnLayout {
    id: page

    readonly property var nightLight: root.nightLight

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Night Light")
    readonly property string subtitle: {
        if (!nightLight || !nightLight.enabled) {
            return i18n("Off");
        }
        if (nightLight.inhibited) {
            if (!nightLight.pausedHere) {
                return i18n("Paused by an app");
            }
            return nightLight.resumeAt > 0 ? i18n("Paused until %1", page.timeText(nightLight.resumeAt)) : i18n("Paused");
        }
        if (nightLight.daylight && nightLight.hasSwitchingTimes && nightLight.scheduledTransition > 0) {
            return i18n("Starts at %1", page.timeText(nightLight.scheduledTransition));
        }
        return i18nc("Colour temperature", "On · %1 K", nightLight.currentTemperature);
    }
    readonly property bool hasSwitch: true
    readonly property bool switchChecked: nightLight !== null && nightLight.enabled
    readonly property bool switchEnabled: nightLight !== null && nightLight.available
    readonly property bool available: nightLight !== null && nightLight.available
    function toggleSwitch() {
        nightLight.setEnabled(!nightLight.enabled);
    }

    // "21:30", or "07:42 tomorrow" for a time on another day
    function timeText(ms) {
        const time = new Date(ms);
        const text = Qt.formatTime(time, Qt.locale().timeFormat(Locale.ShortFormat));
        return time.toDateString() === new Date().toDateString() ? text : i18nc("A time tomorrow", "%1 tomorrow", text);
    }

    // Refreshes the "until" times while the page is open
    property double now: Date.now()
    Timer {
        interval: 30000
        repeat: true
        running: root.expanded && page.visible
        onTriggered: page.now = Date.now()
    }

    readonly property bool canPause: nightLight !== null && nightLight.enabled && nightLight.togglable

    spacing: Kirigami.Units.largeSpacing

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        PC3.Label {
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            text: i18n("Pause")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        ListRow {
            Layout.fillWidth: true
            visible: page.nightLight !== null && page.nightLight.pausedHere
            iconName: "media-playback-start-symbolic"
            title: i18n("Resume now")
            subtitle: page.nightLight && page.nightLight.resumeAt > 0
                ? i18n("Otherwise it resumes at %1", page.timeText(page.nightLight.resumeAt)) : ""
            active: true
            onClicked: page.nightLight.resume()
        }

        ListRow {
            Layout.fillWidth: true
            enabled: page.canPause
            iconName: "chronometer-pause"
            title: i18n("Pause for an hour")
            subtitle: i18n("Until %1", page.timeText(page.now + 3600 * 1000))
            onClicked: page.nightLight.pause(Date.now() + 3600 * 1000)
        }

        ListRow {
            Layout.fillWidth: true
            enabled: page.canPause
            iconName: "weather-clear-night-symbolic"
            title: i18n("Pause until tomorrow morning")
            subtitle: {
                page.now; // re-evaluate as time passes
                return page.nightLight ? i18n("Until %1", page.timeText(page.nightLight.nextMorning())) : "";
            }
            onClicked: page.nightLight.pause(page.nightLight.nextMorning())
        }
    }

    // ---- Night colour temperature ----
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        enabled: page.nightLight !== null && page.nightLight.enabled

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing

            PC3.Label {
                Layout.fillWidth: true
                text: i18n("Night colour temperature")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
            PC3.Label {
                text: i18nc("Colour temperature in kelvin", "%1 K", Math.round(temperatureSlider.value))
                // Not "font:" together with font.features: QML rejects assigning both
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.features: ({ "tnum": 1 })
                opacity: 0.7
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.largeSpacing

            PC3.Label {
                text: i18nc("Night Light colour temperature, the warm end", "Warmer")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            // Shows the colour on screen while dragging; saved on release
            AccentSlider {
                id: temperatureSlider
                Layout.fillWidth: true
                from: page.nightLight ? page.nightLight.minimumTemperature : 1000
                to: page.nightLight ? page.nightLight.maximumTemperature : 6500
                stepSize: 100
                value: page.nightLight ? page.nightLight.nightTemperature : 4500
                Accessible.name: i18n("Night colour temperature")
                onMoved: {
                    if (pressed) {
                        page.nightLight.preview(value);
                    } else {
                        // Arrow keys or the mouse wheel: save once they stop
                        saveDelay.restart();
                    }
                }
                onPressedChanged: {
                    if (!pressed) {
                        page.nightLight.stopPreview();
                        page.nightLight.setNightTemperature(value);
                    }
                }

                Timer {
                    id: saveDelay
                    interval: 600
                    onTriggered: page.nightLight.setNightTemperature(temperatureSlider.value)
                }
            }

            PC3.Label {
                text: i18nc("Night Light colour temperature, the cool end", "Cooler")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "configure-symbolic"
            text: i18n("Night Light settings")
            onClicked: root.openKcm("kcm_nightlight")
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
