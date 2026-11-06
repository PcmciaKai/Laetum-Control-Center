import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: page

    property string cfg_icon
    property alias cfg_showNetworkIndicator: networkCheck.checked
    property alias cfg_showVolumeIndicator: volumeCheck.checked
    property alias cfg_showBatteryIndicator: batteryCheck.checked
    property var cfg_tiles: []
    property alias cfg_showSliders: slidersCheck.checked
    property alias cfg_showMedia: mediaCheck.checked
    property alias cfg_showSearch: searchCheck.checked
    property alias cfg_showNotificationsTab: notificationsTabCheck.checked
    property alias cfg_showCalendarTab: calendarTabCheck.checked
    property alias cfg_headerIconSize: iconSizeCombo.currentIndex
    property alias cfg_animateClick: clickCheck.checked

    // Defaults Plasma passes in alongside the values
    property string cfg_iconDefault
    property bool cfg_showNetworkIndicatorDefault
    property bool cfg_showVolumeIndicatorDefault
    property bool cfg_showBatteryIndicatorDefault
    property var cfg_tilesDefault
    property bool cfg_showSlidersDefault
    property bool cfg_showMediaDefault
    property bool cfg_showSearchDefault
    property bool cfg_showNotificationsTabDefault
    property bool cfg_showCalendarTabDefault
    property int cfg_headerIconSizeDefault
    property bool cfg_animateClickDefault

    readonly property var allTiles: [
        { id: "wifi", name: i18n("Wi-Fi"), icon: "network-wireless-symbolic" },
        { id: "bluetooth", name: i18n("Bluetooth"), icon: "network-bluetooth" },
        { id: "nightlight", name: i18n("Night Light"), icon: "redshift-status-on" },
        { id: "dnd", name: i18n("Do Not Disturb"), icon: "notifications-disabled-symbolic" },
        { id: "airplane", name: i18n("Airplane mode"), icon: "network-flightmode-on" },
        { id: "powerprofile", name: i18n("Power profile"), icon: "speedometer" },
        { id: "microphone", name: i18n("Microphone"), icon: "microphone-sensitivity-high" },
        { id: "kdeconnect", name: i18n("KDE Connect"), icon: "kdeconnect-tray-symbolic" },
        { id: "keepawake", name: i18n("Keep awake"), icon: "system-suspend-inhibited" }
    ]
    readonly property var enabledTiles: Array.from(cfg_tiles).filter(id => allTiles.some(t => t.id === id))
    // Shown tiles first, in their order, then the hidden ones
    readonly property var order: enabledTiles.concat(allTiles.map(t => t.id).filter(id => !enabledTiles.includes(id)))

    function tileInfo(id) {
        return allTiles.find(t => t.id === id);
    }

    function setShown(id, shown) {
        const set = enabledTiles.filter(x => x !== id);
        if (shown) {
            set.push(id);
        }
        cfg_tiles = set;
    }

    function move(id, delta) {
        const list = enabledTiles.slice();
        const i = list.indexOf(id);
        const j = i + delta;
        if (i < 0 || j < 0 || j >= list.length) {
            return;
        }
        list[i] = list[j];
        list[j] = id;
        cfg_tiles = list;
    }

    Kirigami.FormLayout {
        QQC2.Button {
            Kirigami.FormData.label: i18n("Panel icon:")
            icon.name: cfg_icon
            icon.width: Kirigami.Units.iconSizes.large
            icon.height: Kirigami.Units.iconSizes.large
            onClicked: iconDialog.open()

            QQC2.ToolTip.text: i18n("Shown when all panel indicators are hidden or unavailable")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: cfg_icon = iconName || "preferences-system-symbolic"
            }
        }

        QQC2.CheckBox {
            id: networkCheck
            Kirigami.FormData.label: i18n("Panel indicators:")
            text: i18n("Network")
        }
        QQC2.CheckBox {
            id: volumeCheck
            text: i18n("Volume (scroll to change it)")
        }
        QQC2.CheckBox {
            id: batteryCheck
            text: i18n("Battery")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Tiles:")
            Kirigami.FormData.labelAlignment: Qt.AlignTop
            spacing: 0

            Repeater {
                model: page.order

                delegate: RowLayout {
                    id: tileRow

                    required property string modelData
                    required property int index
                    readonly property var info: page.tileInfo(modelData)
                    readonly property bool shown: page.enabledTiles.includes(modelData)
                    readonly property int position: page.enabledTiles.indexOf(modelData)

                    spacing: Kirigami.Units.smallSpacing

                    QQC2.CheckBox {
                        checked: tileRow.shown
                        onToggled: page.setShown(tileRow.modelData, checked)
                        Accessible.name: tileRow.info.name
                    }
                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        source: tileRow.info.icon
                        opacity: tileRow.shown ? 1 : 0.5
                    }
                    QQC2.Label {
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
                        text: tileRow.info.name
                        opacity: tileRow.shown ? 1 : 0.6
                    }
                    QQC2.ToolButton {
                        icon.name: "arrow-up"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Move up")
                        enabled: tileRow.shown && tileRow.position > 0
                        onClicked: page.move(tileRow.modelData, -1)
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                    QQC2.ToolButton {
                        icon.name: "arrow-down"
                        display: QQC2.AbstractButton.IconOnly
                        text: i18n("Move down")
                        enabled: tileRow.shown && tileRow.position < page.enabledTiles.length - 1
                        onClicked: page.move(tileRow.modelData, 1)
                        QQC2.ToolTip.text: text
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }

            QQC2.Label {
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.maximumWidth: Kirigami.Units.gridUnit * 18
                text: i18n("Tiles for hardware this computer doesn't have (for example Wi-Fi on a desktop) hide themselves.")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                wrapMode: Text.WordWrap
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: slidersCheck
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("Volume and brightness sliders")
        }
        QQC2.CheckBox {
            id: mediaCheck
            text: i18n("Media player")
        }
        QQC2.CheckBox {
            id: searchCheck
            text: i18n("Settings search bar")
        }

        QQC2.CheckBox {
            id: notificationsTabCheck
            Kirigami.FormData.label: i18n("Tabs:")
            text: i18n("Notifications")
        }
        QQC2.CheckBox {
            id: calendarTabCheck
            text: i18n("Calendar")
        }

        QQC2.ComboBox {
            id: iconSizeCombo
            Kirigami.FormData.label: i18n("Header buttons:")
            model: [i18n("Small"), i18n("Medium"), i18n("Large")]
        }

        QQC2.CheckBox {
            id: clickCheck
            Kirigami.FormData.label: i18n("Animations:")
            text: i18n("Squeeze tiles when clicked")
        }
    }
}
