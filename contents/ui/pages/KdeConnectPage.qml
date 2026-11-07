import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.kdeconnect as KDEConnect
import ".."

// Connected phones, like the KDE Connect applet: battery, quick actions, the remote keyboard
// and the phone's notifications (dismiss or reply).
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("KDE Connect")
    readonly property string subtitle: reachable.count === 0 ? i18n("No connected devices")
        : i18ncp("Number of connected devices", "%1 device connected", "%1 devices connected", reachable.count)
    readonly property bool hasSwitch: false
    readonly property bool switchChecked: false
    readonly property bool switchEnabled: false
    readonly property bool available: true
    function toggleSwitch() {
    }

    spacing: Kirigami.Units.largeSpacing

    KDEConnect.DevicesModel {
        id: reachable
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    PC3.ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true

        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: Kirigami.Units.gridUnit

            Repeater {
                model: reachable
                delegate: deviceSection
            }

            PC3.Label {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 2
                visible: reachable.count === 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: i18n("Open KDE Connect on your phone, on the same network as this computer")
                opacity: 0.7
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "kdeconnect-tray-symbolic"
            text: i18n("Open KDE Connect")
            onClicked: root.runApp("org.kde.kdeconnect.app")
        }
        Item {
            Layout.fillWidth: true
        }
    }

    // ---- One connected device ----
    Component {
        id: deviceSection

        ColumnLayout {
            id: section

            required property var model
            readonly property KDEConnect.DeviceDbusInterface device: KDEConnect.DeviceDbusInterfaceFactory.create(model.deviceId)

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            // Plugin interfaces, created once KDE Connect says the plugin is enabled for this
            // device (the same pattern the KDE Connect applet uses)
            KDEConnect.PluginChecker {
                id: batteryPlugin
                pluginName: "battery"
                device: section.device
            }
            readonly property var battery: batteryPlugin.available ? KDEConnect.DeviceBatteryDbusInterfaceFactory.create(model.deviceId) : null

            KDEConnect.PluginChecker {
                id: findPlugin
                pluginName: "findmyphone"
                device: section.device
            }
            readonly property var findMyPhone: findPlugin.available ? KDEConnect.FindMyPhoneDbusInterfaceFactory.create(model.deviceId) : null

            KDEConnect.PluginChecker {
                id: sftpPlugin
                pluginName: "sftp"
                device: section.device
            }
            readonly property var sftp: sftpPlugin.available ? KDEConnect.SftpDbusInterfaceFactory.create(model.deviceId) : null

            KDEConnect.PluginChecker {
                id: clipboardPlugin
                pluginName: "clipboard"
                device: section.device
            }
            readonly property var clipboard: clipboardPlugin.available ? KDEConnect.ClipboardDbusInterfaceFactory.create(model.deviceId) : null

            // Name, battery and quick actions
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    source: section.model.iconName || "smartphone"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PC3.Label {
                        Layout.fillWidth: true
                        text: section.model.name
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        visible: section.battery !== null && (section.battery?.hasBattery ?? false) && (section.battery?.charge ?? -1) > -1

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            source: section.battery?.iconName ?? "battery-missing-symbolic"
                            opacity: 0.7
                        }
                        PC3.Label {
                            text: (section.battery?.isCharging ?? false)
                                ? i18n("%1% charging", section.battery?.charge ?? 0)
                                : i18nc("Battery charge percentage", "%1%", section.battery?.charge ?? 0)
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }
                    }
                }

                PC3.ToolButton {
                    visible: section.findMyPhone !== null
                    icon.name: "irc-voice"
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Ring my phone")
                    onClicked: section.findMyPhone.ring()
                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                PC3.ToolButton {
                    visible: section.sftp !== null
                    icon.name: "document-open-folder"
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Browse this device")
                    onClicked: {
                        section.sftp.startBrowsing();
                        root.expanded = false;
                    }
                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
                PC3.ToolButton {
                    visible: section.clipboard !== null
                    icon.name: "klipper-symbolic"
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Send Clipboard")
                    onClicked: section.clipboard.sendClipboard()
                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }

            // Remote keyboard: shown while a text field on the phone has this computer as its keyboard
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                visible: remoteKeyboard.remoteState

                PC3.Label {
                    Layout.leftMargin: Kirigami.Units.smallSpacing
                    text: i18n("Remote keyboard")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
                KDEConnect.RemoteKeyboard {
                    id: remoteKeyboard
                    Layout.fillWidth: true
                    device: section.device
                    placeholderText: i18n("Type here to type on %1", section.model.name)
                }
            }

            // The phone's notifications
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                visible: phoneNotifications.count > 0
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    Layout.fillWidth: true
                    text: i18n("Notifications")
                    font: Kirigami.Theme.smallFont
                    opacity: 0.7
                }
                PC3.ToolButton {
                    icon.name: "edit-clear-history-symbolic"
                    icon.width: Kirigami.Units.iconSizes.small
                    icon.height: Kirigami.Units.iconSizes.small
                    text: i18n("Dismiss all")
                    font: Kirigami.Theme.smallFont
                    onClicked: phoneNotifications.dismissAll()
                }
            }

            Repeater {
                model: KDEConnect.NotificationsModel {
                    id: phoneNotifications
                    deviceId: section.model.deviceId
                }

                delegate: Rectangle {
                    id: card

                    required property var model
                    property bool replying: false

                    Layout.fillWidth: true
                    implicitHeight: cardContent.implicitHeight + pad * 2
                    readonly property int pad: Kirigami.Units.largeSpacing

                    radius: Kirigami.Units.cornerRadius * 1.5
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

                    ColumnLayout {
                        id: cardContent
                        anchors.fill: parent
                        anchors.margins: card.pad
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                source: card.model.appIcon || "kdeconnect-tray-symbolic"
                            }
                            PC3.Label {
                                Layout.fillWidth: true
                                text: card.model.appName
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                            PC3.ToolButton {
                                visible: card.model.repliable
                                enabled: !card.replying
                                icon.name: "mail-reply-sender-symbolic"
                                icon.width: Kirigami.Units.iconSizes.small
                                icon.height: Kirigami.Units.iconSizes.small
                                display: PC3.AbstractButton.IconOnly
                                text: i18n("Reply")
                                onClicked: {
                                    card.replying = true;
                                    replyField.forceActiveFocus();
                                }
                                PC3.ToolTip.text: text
                                PC3.ToolTip.visible: hovered
                                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                            PC3.ToolButton {
                                visible: card.model.dismissable
                                icon.name: "window-close-symbolic"
                                icon.width: Kirigami.Units.iconSizes.small
                                icon.height: Kirigami.Units.iconSizes.small
                                display: PC3.AbstractButton.IconOnly
                                text: i18n("Dismiss")
                                onClicked: card.model.dbusInterface.dismiss()
                                PC3.ToolTip.text: text
                                PC3.ToolTip.visible: hovered
                                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                        }

                        PC3.Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.model.title
                            font.weight: Font.DemiBold
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: card.model.notitext
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        // Inline reply, like the KDE Connect applet's
                        RowLayout {
                            Layout.fillWidth: true
                            visible: card.replying
                            spacing: Kirigami.Units.smallSpacing

                            PC3.TextField {
                                id: replyField
                                Layout.fillWidth: true
                                placeholderText: i18nc("@info:placeholder", "Reply to %1…", card.model.appName)
                                Keys.onReturnPressed: sendButton.clicked()
                                Keys.onEnterPressed: sendButton.clicked()
                                Keys.onEscapePressed: (event) => {
                                    text = "";
                                    card.replying = false;
                                    event.accepted = true;
                                }
                            }
                            PC3.ToolButton {
                                id: sendButton
                                icon.name: Qt.application.layoutDirection === Qt.RightToLeft ? "document-send-rtl" : "document-send"
                                display: PC3.AbstractButton.IconOnly
                                text: i18n("Send")
                                enabled: replyField.text !== ""
                                onClicked: {
                                    card.model.dbusInterface.sendReply(replyField.text);
                                    replyField.text = "";
                                    card.replying = false;
                                }
                                PC3.ToolTip.text: text
                                PC3.ToolTip.visible: hovered
                                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                            }
                        }
                    }
                }
            }
        }
    }
}
