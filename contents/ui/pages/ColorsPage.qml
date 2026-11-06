import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import ".."

// Colours picked with the Color Picker tile, newest first. Click one to copy its hex code.
ColumnLayout {
    id: page

    readonly property var colors: Array.from(Plasmoid.configuration.colorHistory)
    property string copied: ""

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Color Picker")
    readonly property string subtitle: copied !== "" ? i18n("Copied %1", copied)
        : (colors.length > 0 ? i18n("Click a color to copy it") : "")
    readonly property bool hasSwitch: false
    readonly property bool switchChecked: false
    readonly property bool switchEnabled: false
    readonly property bool available: true
    function toggleSwitch() {
    }

    spacing: Kirigami.Units.largeSpacing

    Timer {
        id: copiedReset
        interval: 2000
        onTriggered: page.copied = ""
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 4
        rowSpacing: Kirigami.Units.largeSpacing
        columnSpacing: Kirigami.Units.largeSpacing
        visible: page.colors.length > 0

        Repeater {
            model: page.colors

            delegate: T.AbstractButton {
                id: swatch
                required property string modelData

                Layout.fillWidth: true
                // Equal preferred widths + fillWidth = four equal columns
                Layout.preferredWidth: Kirigami.Units.gridUnit
                implicitHeight: swatchColumn.implicitHeight
                hoverEnabled: true

                Accessible.role: Accessible.Button
                Accessible.name: i18n("Copy %1", modelData)

                onClicked: {
                    root.copyText(modelData);
                    page.copied = modelData;
                    copiedReset.restart();
                }

                contentItem: ColumnLayout {
                    id: swatchColumn
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                        radius: Kirigami.Units.cornerRadius * 1.5
                        color: swatch.modelData
                        border.width: swatch.hovered || swatch.visualFocus ? 2 : 1
                        border.color: swatch.hovered || swatch.visualFocus ? root.accentColor : Qt.alpha(Kirigami.Theme.textColor, 0.2)
                    }
                    PC3.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: swatch.modelData
                        font: Kirigami.Theme.smallFont
                        opacity: 0.8
                    }
                }
            }
        }
    }

    PC3.Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.gridUnit * 2
        visible: page.colors.length === 0
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: i18n("No colors picked yet")
        opacity: 0.7
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "color-picker-symbolic"
            text: i18n("Pick a color")
            onClicked: root.pickColor()
        }
        Item {
            Layout.fillWidth: true
        }
        PC3.Button {
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear")
            enabled: page.colors.length > 0
            onClicked: Plasmoid.configuration.colorHistory = []
        }
    }
}
