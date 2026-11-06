import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.notificationmanager as NotificationManager
import ".."

// Bell while there are unread notifications, crossed out while Do Not Disturb is on.
// Reading them in the Notifications tab clears it (same shared model).
Kirigami.Icon {
    id: indicator

    readonly property int unreadCount: unread.count
    readonly property bool inhibited: NotificationManager.Server.inhibited
    readonly property bool available: NotificationManager.Server.valid && (unreadCount > 0 || inhibited)

    source: inhibited ? "notifications-disabled-symbolic" : "notification-active-symbolic"

    UnreadCounter {
        id: unread
        model: history
    }

    NotificationManager.Settings {
        id: settings
    }

    // The same filters as the Notifications tab, so the bell and the tab badge agree
    NotificationManager.Notifications {
        id: history
        showExpired: true
        showDismissed: true
        showJobs: false
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
}
