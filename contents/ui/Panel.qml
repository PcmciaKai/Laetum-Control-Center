import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

// The popup, in Laetum Launcher's design language:
//   opaque header band (battery or date + buttons, or Back + page title on a drill-in page)
//   hairline with the sliding accent tab indicator: Controls · Notifications
//   body: the current tab or a drill-in page
// Tabs and pages are each loaded on their own, so a broken or missing Plasma component
// only affects that tab or page, never the whole popup.
FocusScope {
    id: panel

    readonly property int pad: Kirigami.Units.gridUnit
    readonly property color hairline: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    readonly property color headerColor: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.08)
    readonly property int headerIconSize: Math.round(Kirigami.Units.iconSizes.smallMedium * [1, 1.3, 1.6][Math.max(0, Math.min(2, Plasmoid.configuration.headerIconSize))])

    // ---- Tabs ----
    readonly property var tabs: {
        const t = [{ key: "controls", label: i18n("Controls") }];
        if (notificationsLoader.status === Loader.Ready && notificationsLoader.item.available) {
            t.push({ key: "notifications", label: i18n("Notifications") });
        }
        return t;
    }
    property string currentTab: "controls"
    // Falls back to Controls when the chosen tab is switched off or failed to load
    readonly property string effectiveTab: tabs.some(t => t.key === currentTab) ? currentTab : "controls"
    readonly property int currentTabIndex: Math.max(0, tabs.findIndex(t => t.key === effectiveTab))
    readonly property int unreadCount: notificationsLoader.status === Loader.Ready ? notificationsLoader.item.unreadCount : 0

    function selectTab(key) {
        currentTab = key;
        panel.forceActiveFocus();
    }

    function cycleTab(delta) {
        const n = tabs.length;
        selectTab(tabs[(currentTabIndex + delta + n) % n].key);
    }

    // ---- Drill-in pages ----
    property string page: ""
    readonly property var pageFiles: ({
        "wifi": "pages/WifiPage.qml",
        "bluetooth": "pages/BluetoothPage.qml",
        "audio": "pages/AudioPage.qml",
        "clipboard": "pages/ClipboardPage.qml",
        "colors": "pages/ColorsPage.qml",
        "kdeconnect": "pages/KdeConnectPage.qml"
    })
    // Where a tile's › goes if its page can't load (e.g. an older Plasma)
    readonly property var pageFallbackKcm: ({
        "wifi": "kcm_networkmanagement",
        "bluetooth": "kcm_bluetooth",
        "audio": "kcm_pulseaudio",
        "clipboard": "",
        "colors": "",
        "kdeconnect": ""
    })
    readonly property bool pageOpen: page !== "" && pageLoader.status === Loader.Ready
    readonly property var pageItem: pageOpen ? pageLoader.item : null

    function openPage(name) {
        if (!pageFiles[name]) {
            return;
        }
        page = name;
        if (pageLoader.status === Loader.Error) {
            page = "";
            if (pageFallbackKcm[name]) {
                root.openKcm(pageFallbackKcm[name]);
            }
            return;
        }
        pageLoader.forceActiveFocus();
    }

    function closePage() {
        page = "";
        panel.forceActiveFocus();
    }

    Connections {
        target: root
        function onPageRequested(name) {
            panel.openPage(name);
        }
        function onExpandedChanged() {
            if (root.expanded) {
                panel.reset();
            }
        }
    }

    // A page whose hardware went away (e.g. a USB Wi-Fi stick) closes itself
    Connections {
        target: panel.pageItem
        ignoreUnknownSignals: true
        function onAvailableChanged() {
            if (panel.pageItem && !panel.pageItem.available) {
                panel.closePage();
            }
        }
    }

    function reset() {
        page = "";
        currentTab = "controls";
        panel.forceActiveFocus();
    }

    Component.onCompleted: reset()

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (panel.pageOpen) {
                panel.closePage();
            } else {
                root.expanded = false;
            }
            event.accepted = true;
        } else if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) && (event.modifiers & Qt.ControlModifier) && !panel.pageOpen) {
            panel.cycleTab(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            event.accepted = true;
        }
    }

    // Stays the height of the Controls tab (but never too short for a page), so the popup
    // doesn't jump when switching tabs or opening a page
    readonly property real bodyHeight: Math.max(controlsLoader.implicitHeight, Kirigami.Units.gridUnit * 16)

    Layout.preferredWidth: Kirigami.Units.gridUnit * 25.5
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.preferredHeight: column.implicitHeight
    Layout.minimumHeight: column.implicitHeight
    Layout.maximumHeight: column.implicitHeight

    Sessions.SessionManagement {
        id: session
    }

    // Clock for the header on computers without a battery
    property date now: new Date()
    Timer {
        interval: 10000
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: panel.now = new Date()
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        // ---- Header: opaque band that reaches the popup's edges ----
        Item {
            id: header
            Layout.fillWidth: true
            // The same height on the home and page headers, so opening a page doesn't move things
            implicitHeight: Math.max(Kirigami.Units.gridUnit * 2.5, panel.pageOpen ? pageHeader.implicitHeight : homeHeader.implicitHeight)
                + Math.round(panel.pad * 1.5)

            Kirigami.ShadowedRectangle {
                readonly property real cornerRadius: Plasmoid.location === PlasmaCore.Types.TopEdge ? 0 : Kirigami.Units.cornerRadius
                x: -panel.Kirigami.ScenePosition.x
                y: -panel.Kirigami.ScenePosition.y
                width: panel.Window.window ? panel.Window.width : header.width
                height: header.height - y
                color: panel.headerColor
                corners.topLeftRadius: cornerRadius
                corners.topRightRadius: cornerRadius
                corners.bottomLeftRadius: 0
                corners.bottomRightRadius: 0
            }

            // Home: battery ring (laptops) or the date, plus Edit, System Settings and Power
            RowLayout {
                id: homeHeader
                anchors.fill: parent
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                spacing: Kirigami.Units.largeSpacing
                visible: !panel.pageOpen

                Loader {
                    id: batteryBadge
                    readonly property bool shown: status === Loader.Ready && item.available
                    Layout.fillWidth: true
                    visible: shown
                    source: "BatteryBadge.qml"
                }

                // Without a battery: today's date where the charge ring would be
                RowLayout {
                    Layout.fillWidth: true
                    visible: !batteryBadge.shown
                    spacing: Kirigami.Units.largeSpacing

                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: "transparent"
                        border.width: 3
                        border.color: root.accentColor

                        PC3.Label {
                            anchors.centerIn: parent
                            text: panel.now.getDate()
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        PC3.Label {
                            Layout.fillWidth: true
                            text: panel.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                            elide: Text.ElideRight
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: panel.now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    spacing: Math.round(panel.headerIconSize * 0.5)

                    HeaderButton {
                        iconSize: panel.headerIconSize
                        iconName: "document-edit-symbolic"
                        tooltip: i18n("Edit tiles")
                        onClicked: root.openConfiguration()
                    }
                    HeaderButton {
                        iconSize: panel.headerIconSize
                        iconName: "configure-symbolic"
                        tooltip: i18n("System Settings")
                        onClicked: {
                            KCMUtils.KCMLauncher.openSystemSettings("");
                            root.expanded = false;
                        }
                    }
                    HeaderButton {
                        id: powerButton
                        iconSize: panel.headerIconSize
                        iconName: "system-shutdown-symbolic"
                        tooltip: i18n("Power")
                        onClicked: powerMenu.openRelative()
                    }
                }
            }

            // Page: Back, the page's title and status, and its on/off switch
            RowLayout {
                id: pageHeader
                anchors.fill: parent
                anchors.leftMargin: panel.pad - Kirigami.Units.smallSpacing
                anchors.rightMargin: panel.pad
                spacing: Kirigami.Units.largeSpacing
                visible: panel.pageOpen

                HeaderButton {
                    iconSize: panel.headerIconSize
                    iconName: Qt.application.layoutDirection === Qt.RightToLeft ? "go-next-symbolic" : "go-previous-symbolic"
                    tooltip: i18n("Back")
                    onClicked: panel.closePage()
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PC3.Label {
                        id: pageTitle
                        Layout.fillWidth: true
                        text: panel.pageItem ? panel.pageItem.title : ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    PC3.Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: panel.pageItem ? panel.pageItem.subtitle : ""
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                PC3.Switch {
                    visible: panel.pageItem ? panel.pageItem.hasSwitch : false
                    enabled: panel.pageItem ? panel.pageItem.switchEnabled : false
                    checked: panel.pageItem ? panel.pageItem.switchChecked : false
                    Accessible.name: pageTitle.text
                    onToggled: {
                        panel.pageItem.toggleSwitch();
                        // Follow the real state, not the click
                        checked = Qt.binding(() => panel.pageItem ? panel.pageItem.switchChecked : false);
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: panel.hairline
        }

        // ---- Tabs with a sliding accent indicator sitting on the hairline ----
        ListView {
            id: tabList
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(panel.width - panel.pad * 2, contentWidth)
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.6
            visible: !panel.pageOpen && panel.tabs.length > 1
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            // Only clip when the tabs overflow, so the indicator can sit on the hairline above
            clip: interactive
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            model: panel.tabs
            currentIndex: panel.currentTabIndex
            highlightMoveDuration: Kirigami.Units.longDuration
            highlightResizeDuration: Kirigami.Units.longDuration
            highlightFollowsCurrentItem: true

            highlight: Item {
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Kirigami.Units.largeSpacing
                    // Centred on the 1px hairline directly above the tab row
                    y: -2
                    height: 3
                    radius: 1.5
                    color: root.accentColor
                }
            }

            delegate: MouseArea {
                id: tabItem
                required property int index
                required property var modelData
                readonly property bool current: panel.currentTabIndex === index
                readonly property int badge: modelData.key === "notifications" ? panel.unreadCount : 0

                width: tabRow.implicitWidth + Kirigami.Units.gridUnit * 2
                height: ListView.view.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: panel.selectTab(modelData.key)

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.label
                Accessible.onPressAction: panel.selectTab(modelData.key)

                RowLayout {
                    id: tabRow
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    PC3.Label {
                        text: tabItem.modelData.label
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                        font.weight: tabItem.current ? Font.DemiBold : Font.Normal
                        opacity: tabItem.current || tabItem.containsMouse ? 1 : 0.7
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    }

                    // Unread notifications
                    Rectangle {
                        visible: tabItem.badge > 0
                        Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.05)
                        Layout.preferredWidth: Math.max(height, badgeLabel.contentWidth + Kirigami.Units.smallSpacing * 2)
                        radius: height / 2
                        color: root.accentColor

                        // Fill + centred alignment rather than centerIn: the label's line
                        // height includes leading, which pushes a centred digit off-centre
                        PC3.Label {
                            id: badgeLabel
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            padding: 0
                            text: tabItem.badge > 99 ? "99+" : tabItem.badge
                            color: Kirigami.Theme.highlightedTextColor
                            font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }

        // ---- Body ----
        StackLayout {
            id: body
            Layout.fillWidth: true
            Layout.preferredHeight: panel.bodyHeight
            Layout.leftMargin: panel.pad
            Layout.rightMargin: panel.pad
            Layout.topMargin: tabList.visible ? Kirigami.Units.smallSpacing : panel.pad
            currentIndex: panel.pageOpen ? 1 : 0

            StackLayout {
                id: tabStack
                currentIndex: ["controls", "notifications"].indexOf(panel.effectiveTab)

                Loader {
                    id: controlsLoader
                    source: "tabs/ControlsTab.qml"
                }
                Loader {
                    id: notificationsLoader
                    active: Plasmoid.configuration.showNotificationsTab
                    source: "tabs/NotificationsTab.qml"
                }
            }

            Loader {
                id: pageLoader
                source: panel.page !== "" ? (panel.pageFiles[panel.page] ?? "") : ""
            }
        }

        // Tell the Notifications tab when it's on screen, to mark notifications read
        Binding {
            target: notificationsLoader.item
            property: "current"
            value: root.expanded && body.currentIndex === 0 && panel.effectiveTab === "notifications"
            when: notificationsLoader.status === Loader.Ready
        }

        Item {
            Layout.preferredHeight: panel.pad
        }
    }

    PlasmaExtras.Menu {
        id: powerMenu
        visualParent: powerButton

        PlasmaExtras.MenuItem { text: i18n("Lock"); icon: "system-lock-screen"; visible: session.canLock; onClicked: { root.expanded = false; session.lock(); } }
        PlasmaExtras.MenuItem { text: i18n("Sleep"); icon: "system-suspend"; visible: session.canSuspend; onClicked: { root.expanded = false; session.suspend(); } }
        PlasmaExtras.MenuItem { text: i18n("Hibernate"); icon: "system-suspend-hibernate"; visible: session.canHibernate; onClicked: { root.expanded = false; session.hibernate(); } }
        PlasmaExtras.MenuItem { text: i18n("Restart"); icon: "system-reboot"; visible: session.canReboot; onClicked: { root.expanded = false; session.requestReboot(); } }
        PlasmaExtras.MenuItem { text: i18n("Shut Down"); icon: "system-shutdown"; visible: session.canShutdown; onClicked: { root.expanded = false; session.requestShutdown(); } }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem { text: i18n("Switch User"); icon: "system-switch-user"; visible: session.canSwitchUser; onClicked: { root.expanded = false; session.switchUser(); } }
        PlasmaExtras.MenuItem { text: i18n("Log Out"); icon: "system-log-out"; visible: session.canLogout; onClicked: { root.expanded = false; session.requestLogout(); } }
    }
}
