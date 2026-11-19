import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.brightnesscontrolplugin
import ".."

// One brightness slider per display that supports it (laptop panel, DDC monitors)
ColumnLayout {
    id: rows

    readonly property bool available: control.isBrightnessAvailable && repeater.count > 0

    // Papirus has no brightness-high, so Plasma falls back to Papirus's colourful
    // "brightness" app icon, which is grey-blue. Its panel icon is white like the volume icon.
    // Kirigami can't tell whether a theme has an icon, so this goes by the theme's name.
    property string iconTheme
    readonly property string iconName: /^e?Papirus/.test(iconTheme) ? "xfpm-brightness-lcd" : "brightness-high"

    function readIconTheme() {
        themeReader.connectSource("kreadconfig6 --group Icons --key Theme --default breeze # " + Date.now());
    }

    // Again on every open: the Dark Mode tile can switch icon themes
    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                rows.readIconTheme();
            }
        }
    }
    Component.onCompleted: readIconTheme()

    P5Support.DataSource {
        id: themeReader
        engine: "executable"
        onNewData: (source, data) => {
            rows.iconTheme = (data.stdout || "").trim();
            disconnectSource(source);
        }
    }

    spacing: Kirigami.Units.largeSpacing

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
            Layout.minimumHeight: Kirigami.Units.gridUnit * 2
            spacing: Kirigami.Units.largeSpacing

            PC3.ToolButton {
                icon.name: rows.iconName
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

            // Invisible twin of the volume row's chevron, so both sliders are the same length
            PC3.ToolButton {
                icon.name: "go-next-symbolic"
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                display: PC3.AbstractButton.IconOnly
                opacity: 0
                enabled: false
                Accessible.ignored: true
            }
        }
    }
}
