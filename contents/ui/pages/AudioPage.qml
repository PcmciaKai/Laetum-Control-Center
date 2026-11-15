import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume
import ".."
import "../rows"

// Choose the default output and input device, and each app's volume, like the Audio Volume
// applet's Devices and Applications tabs
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Sound")
    readonly property string subtitle: PreferredDevice.sink ? deviceName(PreferredDevice.sink) : i18n("No output device")
    readonly property bool hasSwitch: false
    readonly property bool switchChecked: false
    readonly property bool switchEnabled: false
    readonly property bool available: true
    function toggleSwitch() {
    }

    function deviceName(pulseObject) {
        return pulseObject.description || pulseObject.name || i18n("Unknown device");
    }

    spacing: Kirigami.Units.largeSpacing

    PulseObjectFilterModel {
        id: outputs
        filterOutInactiveDevices: true
        filterVirtualDevices: true
        sourceModel: SinkModel {}
    }

    // Apps playing sound; virtual streams (e.g. event sounds) are left out, like the applet does
    PulseObjectFilterModel {
        id: apps
        filters: [{ role: "VirtualStream", value: false }]
        sourceModel: SinkInputModel {}
    }

    PulseObjectFilterModel {
        id: inputs
        filterOutInactiveDevices: true
        filterVirtualDevices: true
        sourceModel: SourceModel {}
    }

    PC3.ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true

        contentWidth: availableWidth
        // Wrapped text reports its unwrapped width; never scroll sideways
        PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 2

            PC3.Label {
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                text: i18n("Output")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            Repeater {
                model: outputs

                delegate: ListRow {
                    id: outputRow
                    required property var model
                    readonly property var device: model.PulseObject

                    Layout.fillWidth: true
                    iconName: "audio-speakers-symbolic"
                    title: page.deviceName(device)
                    active: device.default
                    onClicked: device.default = true

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        visible: outputRow.active
                        source: "checkmark-symbolic"
                    }
                }
            }

            PC3.Label {
                Layout.topMargin: Kirigami.Units.largeSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                text: i18n("Apps")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            // Always shown, so the per-app volume can be found before anything plays
            PC3.Label {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                Layout.preferredWidth: 0
                visible: apps.count === 0
                text: i18n("No apps are playing sound. Apps appear here with their own volume while they play.")
                wrapMode: Text.WordWrap
                font: Kirigami.Theme.smallFont
                opacity: 0.5
            }

            Repeater {
                model: apps

                delegate: AppVolumeRow {
                    required property var model
                    Layout.fillWidth: true
                    Layout.bottomMargin: Kirigami.Units.smallSpacing
                    stream: model.PulseObject
                }
            }

            PC3.Label {
                Layout.topMargin: Kirigami.Units.largeSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                visible: inputs.count > 0
                text: i18n("Input")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
            }

            Repeater {
                model: inputs

                delegate: ListRow {
                    required property var model
                    readonly property var device: model.PulseObject

                    Layout.fillWidth: true
                    iconName: "audio-input-microphone-symbolic"
                    title: page.deviceName(device)
                    subtitle: device.muted ? i18n("Muted") : ""
                    active: device.default
                    onClicked: device.default = true
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "configure-symbolic"
            text: i18n("Sound settings")
            onClicked: root.openKcm("kcm_pulseaudio")
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
