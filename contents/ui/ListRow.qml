import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

// A row in the drill-in pages (networks, Bluetooth devices, audio devices).
// The active row gets the accent tint from the concept's Wi-Fi page.
T.AbstractButton {
    id: row

    property string iconName
    property string title
    property string subtitle
    property bool active: false
    property bool busy: false
    // Extra items on the right (lock icon, Disconnect button, ...)
    default property alias trailing: trailingRow.data

    readonly property color accent: root.accentColor

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.8, contentItem.implicitHeight + topPadding + bottomPadding)
    padding: Kirigami.Units.largeSpacing
    hoverEnabled: true

    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius * 1.5
        color: row.active ? Qt.alpha(row.accent, 0.22)
             : Qt.alpha(Kirigami.Theme.textColor, row.pressed ? 0.12 : (row.hovered || row.visualFocus ? 0.07 : 0))
        border.width: row.active || row.visualFocus ? 1 : 0
        border.color: row.visualFocus ? row.accent : Qt.alpha(row.accent, 0.55)
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }

    contentItem: RowLayout {
        spacing: Kirigami.Units.largeSpacing

        Item {
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

            Kirigami.Icon {
                anchors.fill: parent
                source: row.iconName
                visible: !row.busy
            }
            PC3.BusyIndicator {
                anchors.fill: parent
                running: row.busy
                visible: row.busy
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: row.title
                font.weight: row.active ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            PC3.Label {
                Layout.fillWidth: true
                visible: text !== ""
                text: row.subtitle
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }

        RowLayout {
            id: trailingRow
            spacing: Kirigami.Units.smallSpacing
        }
    }
}
