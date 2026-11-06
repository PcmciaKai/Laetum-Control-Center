import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus
import ".."

// Notification history, from the same shared model the Notifications applet uses:
// closing or reading a notification here does the same over there
ColumnLayout {
    id: notificationsTab

    // Set by the panel while this tab is showing
    property bool current: false

    // For the badge on the tab
    readonly property int unreadCount: unread.count
    readonly property bool available: NotificationManager.Server.valid

    // Ticks once a minute so "5 min ago" stays right
    property date now: new Date()

    spacing: Kirigami.Units.largeSpacing

    onCurrentChanged: {
        if (current) {
            now = new Date();
            markAllRead();
        }
    }

    // ClearExpired only removes notifications that timed out. The rest (a popup still on
    // screen, resident or dismissed ones) are closed one by one, from the end so the rows
    // don't shift under the loop.
    function clearAll() {
        history.clear(NotificationManager.Notifications.ClearExpired);
        for (let i = history.count - 1; i >= 0; --i) {
            history.close(history.index(i, 0));
        }
    }

    function markAllRead() {
        for (let i = 0; i < history.count; ++i) {
            history.setData(history.index(i, 0), true, NotificationManager.Notifications.ReadRole);
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: notificationsTab.current && root.expanded
        onTriggered: notificationsTab.now = new Date()
    }

    // New notifications that arrive while the tab is open count as read
    Connections {
        target: history
        function onCountChanged() {
            if (notificationsTab.current && root.expanded) {
                Qt.callLater(notificationsTab.markAllRead);
            }
        }
    }

    NotificationManager.Settings {
        id: settings
    }

    UnreadCounter {
        id: unread
        model: history
    }

    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        showJobs: false
        sortMode: NotificationManager.Notifications.SortByDate
        groupMode: NotificationManager.Notifications.GroupDisabled
        ignoreBlacklistDuringInhibition: true
        blacklistedDesktopEntries: settings.historyBlacklistedApplications
        blacklistedNotifyRcNames: settings.historyBlacklistedServices
        urgencies: {
            let urgencies = NotificationManager.Notifications.CriticalUrgency | NotificationManager.Notifications.NormalUrgency;
            if (settings.lowPriorityHistory) {
                urgencies |= NotificationManager.Notifications.LowUrgency;
            }
            return urgencies;
        }
    }

    // ---- Do Not Disturb and Clear all ----
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Switch {
            id: dndSwitch
            text: i18n("Do Not Disturb")
            checked: NotificationManager.Server.inhibited
            // Same as the Do Not Disturb tile: let the Notifications applet do it
            onToggled: {
                checked = Qt.binding(() => NotificationManager.Server.inhibited);
                DBus.SessionBus.asyncCall({
                    "service": "org.kde.kglobalaccel",
                    "path": "/component/plasmashell",
                    "iface": "org.kde.kglobalaccel.Component",
                    "member": "invokeShortcut",
                    "signature": "s",
                    "arguments": [new DBus.string("toggle do not disturb")]
                });
            }
        }

        Item {
            Layout.fillWidth: true
        }

        PC3.ToolButton {
            icon.name: "edit-clear-history-symbolic"
            text: i18n("Clear all")
            enabled: history.count > 0
            onClicked: notificationsTab.clearAll()
        }
    }

    // ---- The list ----
    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Kirigami.Units.smallSpacing * 2
        boundsBehavior: Flickable.StopAtBounds
        model: history

        PC3.ScrollBar.vertical: PC3.ScrollBar {
            id: vbar
        }

        Kirigami.WheelHandler {
            target: list
            filterMouseEvents: true
        }

        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: list.count === 0
            iconName: "notifications-symbolic"
            text: i18n("No notifications")
        }

        delegate: NotificationCard {
            width: list.width - (vbar.size < 1 ? vbar.width + Kirigami.Units.smallSpacing : 0)
            now: notificationsTab.now
            onCloseRequested: history.close(history.index(index, 0))
            onDefaultActionRequested: {
                history.invokeDefaultAction(history.index(index, 0), resident ? NotificationManager.Notifications.None : NotificationManager.Notifications.Close);
                root.expanded = false;
            }
            onActionRequested: actionName => {
                history.invokeAction(history.index(index, 0), actionName, resident ? NotificationManager.Notifications.None : NotificationManager.Notifications.Close);
            }
            onConfigureRequested: {
                history.configure(history.index(index, 0));
                root.expanded = false;
            }
        }
    }
}
