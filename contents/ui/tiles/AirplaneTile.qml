import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

Tile {
    id: tile

    available: devices.modemDeviceAvailable || devices.wirelessDeviceAvailable
    checked: PlasmaNM.Configuration.airplaneModeEnabled
    iconName: checked ? "network-flightmode-on" : "network-flightmode-off"
    label: i18n("Airplane Mode")
    status: checked ? i18n("On") : i18n("Off")

    // Same as the Networks applet
    onActivated: {
        const enable = !checked;
        handler.enableAirplaneMode(enable);
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    PlasmaNM.AvailableDevices {
        id: devices
    }

    PlasmaNM.Handler {
        id: handler
    }
}
