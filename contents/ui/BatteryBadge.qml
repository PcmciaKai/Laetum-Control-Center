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

        // The charge, inside the ring
        PC3.Label {
            anchors.centerIn: parent
            width: parent.width - ring.stroke * 4
            horizontalAlignment: Text.AlignHCenter
            text: i18nc("Battery charge percentage", "%1%", badge.percent)
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.weight: Font.DemiBold
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: Kirigami.Theme.smallFont.pointSize * 0.7
        }
    }

    // Whether it's plugged in and charging, and the time left
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        PC3.Label {
            Layout.fillWidth: true
            text: {
                switch (battery.state) {
                case BatteryControlModel.Charging:
                    return i18n("Plugged in, charging");
                case BatteryControlModel.FullyCharged:
                    return i18n("Plugged in, fully charged");
                default:
                    return battery.pluggedIn ? i18n("Plugged in, not charging") : i18n("On battery");
                }
            }
            elide: Text.ElideRight
        }
        PC3.Label {
            Layout.fillWidth: true
            text: {
                if (badge.remaining <= 0) {
                    return "";
                }
                const time = KCoreAddons.Format.formatDuration(badge.remaining, KCoreAddons.FormatTypes.HideSeconds);
                switch (battery.state) {
                case BatteryControlModel.Charging:
                    return i18nc("Time until the battery is full", "%1 until full", time);
                case BatteryControlModel.Discharging:
                    return i18nc("Battery time left", "%1 remaining", time);
                default:
                    return "";
                }
            }
            visible: text !== ""
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            elide: Text.ElideRight
        }
    }
}
