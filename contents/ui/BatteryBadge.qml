import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.battery

// Header identity for laptops: a charge ring where Laetum Launcher shows your avatar
RowLayout {
    id: badge

    readonly property bool available: battery.hasInternalBatteries
    readonly property int percent: battery.percent
    readonly property bool charging: battery.pluggedIn && battery.state === BatteryControlModel.Charging
    readonly property int remaining: battery.smoothedRemainingMsec

    spacing: Kirigami.Units.largeSpacing

    BatteryControlModel {
        id: battery
    }

    Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
        Layout.preferredHeight: Layout.preferredWidth

        Shape {
            id: ring
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            readonly property real stroke: 3
            readonly property real r: width / 2 - stroke / 2

            ShapePath {
                strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.12)
                strokeWidth: ring.stroke
                fillColor: "transparent"
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            ShapePath {
                strokeColor: root.accentColor
                strokeWidth: ring.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: -90
                    sweepAngle: 360 * Math.max(0, Math.min(100, badge.percent)) / 100
                }
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: {
                const level = Math.max(0, Math.min(100, Math.round(badge.percent / 10) * 10));
                return "battery-" + String(level).padStart(3, "0") + (badge.charging ? "-charging" : "") + "-symbolic";
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        PC3.Label {
            Layout.fillWidth: true
            text: i18nc("Battery charge percentage", "%1%", badge.percent)
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
            elide: Text.ElideRight
        }
        PC3.Label {
            Layout.fillWidth: true
            text: {
                const time = badge.remaining > 0 ? KCoreAddons.Format.formatDuration(badge.remaining, KCoreAddons.FormatTypes.HideSeconds) : "";
                switch (battery.state) {
                case BatteryControlModel.Charging:
                    return time ? i18nc("Time until the battery is full", "%1 until full", time) : i18n("Charging");
                case BatteryControlModel.Discharging:
                    return time ? i18nc("Battery time left", "%1 remaining", time) : i18n("On battery");
                case BatteryControlModel.FullyCharged:
                    return i18n("Fully charged");
                default:
                    return battery.pluggedIn ? i18n("Plugged in, not charging") : "";
                }
            }
            visible: text !== ""
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            elide: Text.ElideRight
        }
    }
}
