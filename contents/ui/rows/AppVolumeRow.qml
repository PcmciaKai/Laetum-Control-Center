import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume
import ".."

// One app playing sound: its icon (click to mute), name and what it plays, and its volume
ColumnLayout {
    id: row

    // A PulseAudio sink input (an app's audio stream)
    required property var stream

    readonly property var client: stream ? stream.client : null
    readonly property var props: stream ? stream.properties : ({})
    readonly property string appName: (client && client.name) || props["application.name"] || (stream ? stream.name : "")
    // What it plays (a song, a video title); left out when it's just the app's name again
    readonly property string mediaName: {
        const media = props["media.name"] || (stream ? stream.name : "");
        return media && media !== appName && !media.startsWith("/") ? media : "";
    }
    readonly property string iconName: (stream && stream.iconName) || (client && client.iconName)
        || props["application.icon_name"] || props["application.process.binary"] || ""
    readonly property int percent: stream ? Math.round(stream.volume / PulseAudio.NormalVolume * 100) : 0
    readonly property bool muted: stream ? stream.muted : false

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.largeSpacing

        // The app's icon is the mute button
        PC3.ToolButton {
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium + Kirigami.Units.smallSpacing * 2
            Layout.preferredHeight: Layout.preferredWidth
            enabled: row.stream ? row.stream.volumeWritable : false
            text: row.muted ? i18n("Unmute %1", row.appName) : i18n("Mute %1", row.appName)
            display: PC3.AbstractButton.IconOnly
            onClicked: row.stream.muted = !row.stream.muted

            contentItem: Item {
                Kirigami.Icon {
                    id: appIcon
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    source: row.iconName
                    fallback: "audio-volume-high-symbolic"
                    opacity: row.muted ? 0.4 : 1
                }
                Kirigami.Icon {
                    anchors.right: appIcon.right
                    anchors.bottom: appIcon.bottom
                    anchors.margins: -Kirigami.Units.smallSpacing
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    visible: row.muted
                    source: "audio-volume-muted-symbolic"
                }
            }

            PC3.ToolTip.text: text
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    Layout.fillWidth: true
                    text: row.mediaName ? i18nc("App name: what it plays", "%1: %2", row.appName, row.mediaName) : row.appName
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font: Kirigami.Theme.smallFont
                    opacity: 0.85
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                AccentSlider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    stepSize: 1
                    value: row.percent
                    enabled: row.stream ? row.stream.volumeWritable : false
                    opacity: row.muted ? 0.5 : 1
                    Accessible.name: i18n("Volume of %1", row.appName)
                    onMoved: {
                        if (row.stream.muted && value > 0) {
                            row.stream.muted = false;
                        }
                        row.stream.volume = Math.round(value / 100 * PulseAudio.NormalVolume);
                    }
                }

                PC3.Label {
                    Layout.preferredWidth: valueMetrics.width + Kirigami.Units.smallSpacing
                    horizontalAlignment: Text.AlignRight
                    text: row.percent
                    opacity: 0.7
                    font.features: ({ "tnum": 1 })

                    TextMetrics {
                        id: valueMetrics
                        text: "100"
                    }
                }
            }
        }
    }
}
