import QtQuick
import org.kde.kdeconnect as KDEConnect
import ".."

Tile {
    id: tile

    readonly property int reachableCount: reachable.count

    // Shown once KDE Connect is installed, even before a device is paired
    available: true
    checked: reachableCount > 0
    iconName: "kdeconnect-tray-symbolic"
    label: i18n("KDE Connect")
    status: {
        if (paired.count === 0) {
            return i18n("No paired devices");
        }
        if (reachableCount === 0) {
            return i18n("Not connected");
        }
        if (reachableCount === 1) {
            return firstName.first ? firstName.first.name : i18n("Connected");
        }
        return i18ncp("Number of connected devices", "%1 connected", "%1 connected", reachableCount);
    }
    // Battery, notifications and the remote keyboard, in a page like the KDE Connect applet;
    // the page has a button to open the KDE Connect app
    onActivated: root.pageRequested("kdeconnect")

    KDEConnect.DevicesModel {
        id: paired
        displayFilter: KDEConnect.DevicesModel.Paired
    }

    KDEConnect.DevicesModel {
        id: reachable
        displayFilter: KDEConnect.DevicesModel.Paired | KDEConnect.DevicesModel.Reachable
    }

    // The name of the first connected device
    Instantiator {
        id: firstName
        readonly property QtObject first: count > 0 ? objectAt(0) : null
        model: reachable
        delegate: QtObject {
            required property string name
        }
    }
}
