import QtQuick
import org.kde.plasma.workspace.dbus as DBus
import ".."

// Clipboard history from Klipper (which runs inside plasmashell); click to browse it
Tile {
    id: tile

    property int itemCount: 0

    available: klipper.registered
    iconName: "klipper-symbolic"
    label: i18n("Clipboard")
    status: itemCount > 0 ? i18ncp("Number of clipboard history entries", "%1 item", "%1 items", itemCount) : i18n("Empty")

    onActivated: root.pageRequested("clipboard")

    DBus.DBusServiceWatcher {
        id: klipper
        busType: DBus.BusType.Session
        watchedService: "org.kde.klipper"
    }

    function refresh() {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.klipper",
            "path": "/klipper",
            "iface": "org.kde.klipper.klipper",
            "member": "getClipboardHistoryMenu"
        }, (reply) => {
            tile.itemCount = Array.from(reply.value || []).length;
        }, () => {
            tile.itemCount = 0;
        });
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                tile.refresh();
            }
        }
    }

    Component.onCompleted: refresh()
}
