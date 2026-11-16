import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

// Two tiles that run your own commands. Idea from Kontrol Center by ItsNotMeBro87
// (https://github.com/ItsNotMeBro87/plasma6-kontrol-center).
KCM.SimpleKCM {
    id: page

    property alias cfg_custom1Name: name1.text
    property string cfg_custom1Icon
    property alias cfg_custom1OnCommand: on1.text
    property alias cfg_custom1OffCommand: off1.text
    property alias cfg_custom1StatusCommand: status1.text
    property alias cfg_custom2Name: name2.text
    property string cfg_custom2Icon
    property alias cfg_custom2OnCommand: on2.text
    property alias cfg_custom2OffCommand: off2.text
    property alias cfg_custom2StatusCommand: status2.text

    property string cfg_custom1NameDefault
    property string cfg_custom1IconDefault
    property string cfg_custom1OnCommandDefault
    property string cfg_custom1OffCommandDefault
    property string cfg_custom1StatusCommandDefault
    property string cfg_custom2NameDefault
    property string cfg_custom2IconDefault
    property string cfg_custom2OnCommandDefault
    property string cfg_custom2OffCommandDefault
    property string cfg_custom2StatusCommandDefault

    // The other settings and the ones Plasma adds: kept as they are (only the page on
    // screen is saved)
    property bool cfg_expanding
    property int cfg_length
    property var cfg_icon
    property var cfg_iconDefault
    property var cfg_showNetworkIndicator
    property var cfg_showNetworkIndicatorDefault
    property var cfg_showVolumeIndicator
    property var cfg_showVolumeIndicatorDefault
    property var cfg_showBatteryIndicator
    property var cfg_showBatteryIndicatorDefault
    property var cfg_showNotificationIndicator
    property var cfg_showNotificationIndicatorDefault
    property var cfg_tiles
    property var cfg_tilesDefault
    property var cfg_showSliders
    property var cfg_showSlidersDefault
    property var cfg_showMedia
    property var cfg_showMediaDefault
    property var cfg_showDevices
    property var cfg_showDevicesDefault
    property var cfg_showPrintQueue
    property var cfg_showPrintQueueDefault
    property var cfg_showNotificationsTab
    property var cfg_showNotificationsTabDefault
    property var cfg_headerIconSize
    property var cfg_headerIconSizeDefault
    property var cfg_headerHeight
    property var cfg_headerHeightDefault
    property var cfg_headerBadge
    property var cfg_headerBadgeDefault
    property var cfg_colorHistory
    property var cfg_colorHistoryDefault
    property var cfg_lightColorScheme
    property var cfg_lightColorSchemeDefault
    property var cfg_darkColorScheme
    property var cfg_darkColorSchemeDefault
    property var cfg_lightPlasmaStyle
    property var cfg_lightPlasmaStyleDefault
    property var cfg_darkPlasmaStyle
    property var cfg_darkPlasmaStyleDefault
    property var cfg_lightIconTheme
    property var cfg_lightIconThemeDefault
    property var cfg_darkIconTheme
    property var cfg_darkIconThemeDefault
    property var cfg_animateClick
    property var cfg_animateClickDefault
    property var cfg_custom1On
    property var cfg_custom1OnDefault
    property var cfg_custom2On
    property var cfg_custom2OnDefault

    // One tile's fields
    component CommandField: QQC2.TextField {
        Layout.fillWidth: true
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        font.family: "monospace"
    }

    component IconPicker: QQC2.Button {
        id: picker
        property string iconName
        signal picked(string name)
        icon.name: iconName || "system-run-symbolic"
        icon.width: Kirigami.Units.iconSizes.medium
        icon.height: Kirigami.Units.iconSizes.medium
        display: QQC2.AbstractButton.IconOnly
        text: i18n("Choose an icon")
        onClicked: dialog.open()
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

        KIconThemes.IconDialog {
            id: dialog
            onIconNameChanged: {
                if (iconName) {
                    picker.picked(iconName);
                }
            }
        }
    }

    Kirigami.FormLayout {
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            text: i18n("Each custom tile runs your own commands. Give it an ON and an OFF command to make it a toggle, or only an ON command to make it a button. Add the tiles to the popup on the General page.")
            wrapMode: Text.WordWrap
        }

        // ---- Tile 1 ----
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Custom tile 1")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Name and icon:")
            IconPicker {
                iconName: page.cfg_custom1Icon
                onPicked: name => page.cfg_custom1Icon = name
            }
            QQC2.TextField {
                id: name1
                Layout.fillWidth: true
                placeholderText: i18n("Custom 1")
                maximumLength: 24
            }
        }
        CommandField {
            id: on1
            Kirigami.FormData.label: i18n("ON command:")
            placeholderText: i18nc("Example command", "e.g. systemctl --user start syncthing")
        }
        CommandField {
            id: off1
            Kirigami.FormData.label: i18n("OFF command:")
            placeholderText: i18nc("Example command", "e.g. systemctl --user stop syncthing")
        }
        CommandField {
            id: status1
            Kirigami.FormData.label: i18n("Status command:")
            placeholderText: i18nc("Example command", "Optional, e.g. systemctl --user is-active syncthing")
        }

        // ---- Tile 2 ----
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Custom tile 2")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Name and icon:")
            IconPicker {
                iconName: page.cfg_custom2Icon
                onPicked: name => page.cfg_custom2Icon = name
            }
            QQC2.TextField {
                id: name2
                Layout.fillWidth: true
                placeholderText: i18n("Custom 2")
                maximumLength: 24
            }
        }
        CommandField {
            id: on2
            Kirigami.FormData.label: i18n("ON command:")
        }
        CommandField {
            id: off2
            Kirigami.FormData.label: i18n("OFF command:")
        }
        CommandField {
            id: status2
            Kirigami.FormData.label: i18n("Status command:")
            placeholderText: i18n("Optional")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            text: i18n("Commands run with sh, so pipes and && work. A status command tells the tile whether it is on: exit code 0 means on. Without one, the tile remembers the state you last set. Commands that keep running (a server, a program) should be started with something that returns, like systemctl --user start or setsid -f.")
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.8
        }

        Kirigami.InlineMessage {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Warning
            text: i18n("The commands run as you, with your permissions. Only use commands you understand and trust.")
        }
    }
}
