import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

// The header's identity, where Laetum Launcher shows your avatar: a ring filled to a
// percentage, with two lines of text next to it. Filled in by BatteryBadge and UsageBadge.
RowLayout {
    id: badge

    property bool available: true
    property real percent: 0
    property string title
    property string subtitle
    // The thin header: a smaller ring and smaller text
    property bool thin: false

    readonly property real ringSize: thin ? Kirigami.Units.gridUnit * 1.6 : Kirigami.Units.gridUnit * 2.5

    spacing: thin ? Kirigami.Units.smallSpacing * 2 : Kirigami.Units.largeSpacing

    Item {
        Layout.preferredWidth: badge.ringSize
        Layout.preferredHeight: badge.ringSize

        Shape {
            id: ring
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            readonly property real stroke: badge.thin ? 2 : 3
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

        // The percentage, inside the ring
        PC3.Label {
            anchors.centerIn: parent
            width: parent.width - ring.stroke * 4
            horizontalAlignment: Text.AlignHCenter
            text: i18nc("A percentage, in the header's ring", "%1%", Math.round(badge.percent))
            font.pointSize: Kirigami.Theme.smallFont.pointSize * (badge.thin ? 0.85 : 1)
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
            fontSizeMode: Text.HorizontalFit
            minimumPointSize: Kirigami.Theme.smallFont.pointSize * 0.6
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        PC3.Label {
            Layout.fillWidth: true
            text: badge.title
            font.pointSize: badge.thin ? Kirigami.Theme.smallFont.pointSize : Kirigami.Theme.defaultFont.pointSize
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
        PC3.Label {
            Layout.fillWidth: true
            text: badge.subtitle
            visible: text !== ""
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
