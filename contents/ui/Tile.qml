import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

// One quick-settings tile. The files in tiles/ wrap this with a Plasma backend.
// Click the tile to toggle; the optional chevron opens more options.
Item {
    id: tile

    property string iconName
    property string label
    property string status
    property bool checked: false
    property bool available: true
    property bool hasDetails: false
    property string detailsTooltip: i18n("More options")

    signal activated()
    signal detailsRequested()

    readonly property color accent: root.accentColor
    readonly property color fg: checked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
    readonly property alias detailsButton: more

    implicitHeight: Kirigami.Units.gridUnit * 4.8
    opacity: enabled ? 1 : 0.5

    Item {
        id: body
        anchors.fill: parent

        scale: Plasmoid.configuration.animateClick && main.pressed ? 0.95 : 1
        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: main.pressed ? Easing.OutCubic : Easing.OutBack
                easing.overshoot: 2
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius * 1.5
            color: tile.checked ? tile.accent : Qt.alpha(Kirigami.Theme.textColor, main.hovered || more.hovered ? 0.11 : 0.06)
            border.width: tile.checked ? 0 : 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

            // A light wash over the accent fill on hover
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "white"
                opacity: tile.checked && (main.hovered || more.hovered) ? 0.08 : 0
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            }

            // Keyboard focus ring
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.width: 2
                border.color: tile.accent
                visible: main.visualFocus
            }
        }

        T.AbstractButton {
            id: main
            anchors.fill: parent
            padding: Math.round(Kirigami.Units.largeSpacing * 1.5)
            hoverEnabled: true
            background: null

            Accessible.role: Accessible.Button
            Accessible.name: tile.label
            Accessible.description: tile.status
            Accessible.checkable: true
            Accessible.checked: tile.checked

            onClicked: tile.activated()

            contentItem: ColumnLayout {
                spacing: 0

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    source: tile.iconName
                    color: tile.fg
                    isMask: true
                }

                Item {
                    Layout.fillHeight: true
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: tile.label
                    color: tile.fg
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                PC3.Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: tile.status
                    color: tile.fg
                    opacity: tile.checked ? 0.86 : 0.7
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
        }

        T.AbstractButton {
            id: more
            visible: tile.hasDetails
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 3
            width: Kirigami.Units.gridUnit * 1.9
            height: width
            hoverEnabled: true

            Accessible.role: Accessible.Button
            Accessible.name: tile.detailsTooltip

            onClicked: tile.detailsRequested()

            background: Rectangle {
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(tile.fg, more.pressed ? 0.22 : 0.14)
                opacity: more.hovered || more.visualFocus ? 1 : 0
                border.width: more.visualFocus ? 2 : 0
                border.color: tile.checked ? tile.fg : tile.accent
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            }

            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: "go-next-symbolic"
                    color: tile.fg
                    isMask: true
                }
            }

            PC3.ToolTip.text: tile.detailsTooltip
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
