import QtQuick
import org.kde.notificationmanager as NotificationManager
import org.kde.plasma.workspace.dbus as DBus
import ".."

Tile {
    id: tile

    // The notification server lives in plasmashell, so this is the same state the
    // Notifications applet shows
    available: NotificationManager.Server.valid
    checked: NotificationManager.Server.inhibited
    iconName: checked ? "notifications-disabled-symbolic" : "notification-inactive-symbolic"
    label: i18nc("Short for Do Not Disturb", "DND")
    fullLabel: i18n("Do Not Disturb")
    status: checked ? i18n("On") : i18n("Off")
    hasDetails: true
    detailsTooltip: i18n("Notification settings")

    // Trigger the Notifications applet's own "Toggle do not disturb" shortcut, so it keeps
    // its bookkeeping (and shows its OSD) exactly as if the keyboard shortcut was pressed
    onActivated: DBus.SessionBus.asyncCall({
        "service": "org.kde.kglobalaccel",
        "path": "/component/plasmashell",
        "iface": "org.kde.kglobalaccel.Component",
        "member": "invokeShortcut",
        "signature": "s",
        "arguments": [new DBus.string("toggle do not disturb")]
    })
    onDetailsRequested: root.openKcm("kcm_notifications")
}
