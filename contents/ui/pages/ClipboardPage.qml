import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.clipboard as Klipper
import ".."

// Klipper's history, from the same model as the Clipboard applet, so pictures come with a
// thumbnail. Click an entry to put it back on the clipboard.
// Only opened from the Clipboard tile, which only shows while Klipper is running: the model
// needs Klipper's instance inside plasmashell.
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Clipboard")
    readonly property string subtitle: history.count > 0
        ? i18ncp("Number of clipboard history entries", "%1 item", "%1 items", history.count)
        : i18n("Empty")
    readonly property bool hasSwitch: false
    readonly property bool switchChecked: false
    readonly property bool switchEnabled: false
    readonly property bool available: true
    function toggleSwitch() {
    }

    spacing: Kirigami.Units.largeSpacing

    Klipper.HistoryModel {
        id: history
    }

    PC3.ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true

        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 2

            Repeater {
                model: history

                delegate: T.AbstractButton {
                    id: entry

                    required property int index
                    required property var model
                    // Not a required "display" property: AbstractButton already has one
                    readonly property string entryText: model.display ?? ""
                    required property var decoration
                    required property size imageSize
                    required property var uuid

                    readonly property bool isImage: imageSize.width > 0 && imageSize.height > 0
                    readonly property bool current: index === 0
                    readonly property color accent: root.accentColor

                    Layout.fillWidth: true
                    implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.8, contentItem.implicitHeight + topPadding + bottomPadding)
                    padding: Kirigami.Units.largeSpacing
                    hoverEnabled: true

                    Accessible.role: Accessible.Button
                    Accessible.name: isImage ? i18n("Image, %1 × %2", imageSize.width, imageSize.height) : entryText

                    onClicked: history.moveToTop(uuid)

                    // The same look as the rows on the other pages; the current entry gets the accent tint
                    background: Rectangle {
                        radius: Kirigami.Units.cornerRadius * 1.5
                        color: entry.current ? Qt.alpha(entry.accent, 0.22)
                             : Qt.alpha(Kirigami.Theme.textColor, entry.pressed ? 0.12 : (entry.hovered || entry.visualFocus ? 0.07 : 0))
                        border.width: entry.current || entry.visualFocus ? 1 : 0
                        border.color: entry.visualFocus ? entry.accent : Qt.alpha(entry.accent, 0.55)
                        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
                    }

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            Layout.alignment: Qt.AlignTop
                            visible: !entry.isImage
                            source: (entry.model.starred ?? false) ? "starred-symbolic" : "edit-paste-symbolic"
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            // Thumbnail, the same size the Clipboard applet uses
                            Image {
                                Layout.maximumWidth: parent.width
                                visible: entry.isImage
                                source: entry.isImage ? entry.decoration : ""
                                cache: false
                                asynchronous: true
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize.height: Math.min(entry.imageSize.height, Kirigami.Units.gridUnit * 4 + Kirigami.Units.smallSpacing * 2)
                            }

                            PC3.Label {
                                Layout.fillWidth: true
                                text: entry.isImage
                                    ? i18nc("Image dimensions", "%1 × %2", entry.imageSize.width, entry.imageSize.height)
                                    // Two lines at most; the start of the text is the useful part
                                    : entry.entryText.slice(0, 300).replace(/\s+/g, " ").trim()
                                font.pointSize: entry.isImage ? Kirigami.Theme.smallFont.pointSize : Kirigami.Theme.defaultFont.pointSize
                                opacity: entry.isImage ? 0.7 : 1
                                font.weight: entry.current && !entry.isImage ? Font.DemiBold : Font.Normal
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                        }

                        PC3.ToolButton {
                            Layout.alignment: Qt.AlignTop
                            icon.name: "edit-delete-remove-symbolic"
                            icon.width: Kirigami.Units.iconSizes.small
                            icon.height: Kirigami.Units.iconSizes.small
                            display: PC3.AbstractButton.IconOnly
                            text: i18n("Remove from history")
                            opacity: entry.hovered || hovered || visualFocus ? 1 : 0
                            onClicked: history.remove(entry.uuid)

                            PC3.ToolTip.text: text
                            PC3.ToolTip.visible: hovered
                            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                        }
                    }
                }
            }

            PC3.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                visible: history.count === 0
                horizontalAlignment: Text.AlignHCenter
                text: i18n("Nothing copied yet")
                opacity: 0.7
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear history")
            enabled: history.count > 0
            onClicked: history.clearHistory()
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
