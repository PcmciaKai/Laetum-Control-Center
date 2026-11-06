import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume
import ".."

RowLayout {
    id: row

    readonly property var sink: PreferredDevice.sink
    readonly property bool available: sink !== null
    readonly property int percent: sink ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0

    spacing: Kirigami.Units.smallSpacing

    PC3.ToolButton {
        icon.name: row.sink ? AudioIcon.forVolume(row.percent, row.sink.muted, "") : "audio-volume-muted"
        display: PC3.AbstractButton.IconOnly
        text: row.sink && row.sink.muted ? i18n("Unmute") : i18n("Mute")
        onClicked: row.sink.muted = !row.sink.muted

        PC3.ToolTip.text: text
        PC3.ToolTip.visible: hovered
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    AccentSlider {
        Layout.fillWidth: true
        from: 0
        to: 100
        stepSize: 1
        value: row.percent
        Accessible.name: i18n("Volume")
        onMoved: {
            if (row.sink.muted && value > 0) {
                row.sink.muted = false;
            }
            row.sink.volume = Math.round(value / 100 * PulseAudio.NormalVolume);
        }
    }

    PC3.Label {
        Layout.preferredWidth: valueMetrics.width
        horizontalAlignment: Text.AlignRight
        text: row.percent
        opacity: 0.7
        font.features: ({ "tnum": 1 })

        TextMetrics {
            id: valueMetrics
            text: "100"
        }
    }

    PC3.ToolButton {
        icon.name: "go-next-symbolic"
        display: PC3.AbstractButton.IconOnly
        text: i18n("Audio devices")
        onClicked: root.openKcm("kcm_pulseaudio")

        PC3.ToolTip.text: text
        PC3.ToolTip.visible: hovered
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
}
