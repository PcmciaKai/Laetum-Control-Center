import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.brightnesscontrolplugin
import ".."

// One brightness slider per display that supports it (laptop panel, DDC monitors)
ColumnLayout {
    id: rows

    readonly property bool available: control.isBrightnessAvailable && repeater.count > 0

    spacing: 0

    ScreenBrightnessControl {
        id: control
        isSilent: true
    }

    Repeater {
        id: repeater
        model: control.displays

        delegate: RowLayout {
            id: row

            required property string displayName
            required property string label
            required property int brightness
            required property int maxBrightness

            readonly property int percent: maxBrightness > 0 ? Math.round(brightness / maxBrightness * 100) : 0

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PC3.ToolButton {
                id: iconButton
                icon.name: "brightness-high"
                display: PC3.AbstractButton.IconOnly
                text: repeater.count > 1 ? i18n("%1: display settings", row.label) : i18n("Display settings")
                onClicked: root.openKcm("kcm_kscreen")

                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            AccentSlider {
                Layout.fillWidth: true
                // Never all the way to 0, which turns some panels off
                from: Math.max(1, Math.round(row.maxBrightness / 100))
                to: row.maxBrightness
                stepSize: Math.max(1, row.maxBrightness / 100)
                value: row.brightness
                Accessible.name: repeater.count > 1 ? i18n("Brightness of %1", row.label) : i18n("Screen brightness")
                onMoved: control.setBrightness(row.displayName, Math.round(value))
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

            // Keeps the slider the same length as the volume slider, which has a chevron here
            Item {
                Layout.preferredWidth: iconButton.implicitWidth
                Layout.preferredHeight: 1
            }
        }
    }
}
