import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.notificationmanager as NotificationManager

// One notification in the history, in the same card style as the media card
Rectangle {
    id: card

    // Roles from NotificationManager.Notifications
    required property int index
    required property string summary
    required property string body
    required property string applicationName
    required property string applicationIconName
    required property string iconName
    required property var created
    required property var updated
    required property var actionNames
    required property var actionLabels
    required property bool hasDefaultAction
    required property bool expired
    required property bool resident
    required property bool configurable
    required property int urgency

    property date now: new Date()

    signal closeRequested()
    signal defaultActionRequested()
    signal actionRequested(string actionName)
    signal configureRequested()

    readonly property int pad: Math.round(Kirigami.Units.largeSpacing * 1.5)
    readonly property bool critical: urgency === NotificationManager.Notifications.CriticalUrgency

    // "Just now", "5 min ago", a time today, or a relative date, like the Notifications applet
    readonly property string ageText: {
        const time = (updated && !isNaN(updated.getTime())) ? updated : created;
        if (!time || isNaN(time.getTime())) {
            return "";
        }
        const minutes = Math.floor((now.getTime() - time.getTime()) / 60000);
        if (minutes < 1) {
            return i18nc("Notification was added less than a minute ago, keep short", "Just now");
        }
        if (minutes < 60) {
            return i18ncp("Notification was added minutes ago, keep short", "%1 min ago", "%1 min ago", minutes);
        }
        if (minutes < 60 * 22) {
            return Qt.formatTime(time, Qt.locale().timeFormat(Locale.ShortFormat).replace(/.ss?/i, ""));
        }
        return KCoreAddons.Format.formatRelativeDate(time, Locale.ShortFormat);
    }

    implicitHeight: content.implicitHeight + pad * 2
    radius: Kirigami.Units.cornerRadius * 1.5
    color: Qt.alpha(Kirigami.Theme.textColor, clickArea.containsMouse ? 0.09 : 0.06)
    border.width: 1
    border.color: critical ? Kirigami.Theme.negativeTextColor : Qt.alpha(Kirigami.Theme.textColor, 0.12)

    Accessible.name: summary
    Accessible.description: body

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.hasDefaultAction && !card.expired
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.defaultActionRequested()
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.pad
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: card.applicationIconName
                visible: source !== ""
            }

            PC3.Label {
                Layout.fillWidth: true
                text: [card.applicationName, card.ageText].filter(s => s !== "").join(" · ")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            PC3.ToolButton {
                visible: card.configurable
                icon.name: "configure-symbolic"
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                display: PC3.AbstractButton.IconOnly
                text: i18n("Notification settings")
                onClicked: card.configureRequested()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            PC3.ToolButton {
                icon.name: "window-close-symbolic"
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                display: PC3.AbstractButton.IconOnly
                text: i18n("Close")
                onClicked: card.closeRequested()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                PC3.Label {
                    Layout.fillWidth: true
                    text: card.summary
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                PC3.Label {
                    Layout.fillWidth: true
                    visible: text !== ""
                    // The notification server already reduces the body to safe markup
                    text: card.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    opacity: 0.85
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                Layout.alignment: Qt.AlignTop
                source: card.iconName
                visible: card.iconName !== "" && card.iconName !== card.applicationIconName
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: !card.expired && card.actionNames.length > 0

            Repeater {
                model: card.expired ? [] : card.actionNames

                delegate: PC3.Button {
                    required property string modelData
                    required property int index
                    text: card.actionLabels[index] ?? modelData
                    onClicked: card.actionRequested(modelData)
                }
            }
        }
    }
}
