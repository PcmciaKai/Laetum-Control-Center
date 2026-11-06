import QtQuick
import org.kde.bluezqt as BluezQt
import ".."

Tile {
    id: tile

    readonly property var connected: BluezQt.Manager.connectedDevices

    available: BluezQt.Manager.bluetoothBlocked || BluezQt.Manager.adapters.length > 0
    checked: BluezQt.Manager.bluetoothOperational
    iconName: checked ? "network-bluetooth-activated" : "network-bluetooth"
    label: i18n("Bluetooth")
    status: {
        if (!checked) {
            return i18n("Off");
        }
        if (connected.length === 0) {
            return i18n("On");
        }
        if (connected.length === 1) {
            return connected[0].name;
        }
        return i18ncp("Number of connected devices", "%1 connected", "%1 connected", connected.length);
    }
    hasDetails: true
    detailsTooltip: i18n("Bluetooth devices")

    // Same as the Bluetooth applet: unblock the radio and power every adapter
    onActivated: {
        const enable = !checked;
        BluezQt.Manager.bluetoothBlocked = !enable;
        BluezQt.Manager.adapters.forEach(adapter => {
            adapter.powered = enable;
        });
    }
    onDetailsRequested: root.pageRequested("bluetooth")
}
