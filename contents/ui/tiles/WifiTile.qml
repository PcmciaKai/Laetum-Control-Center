import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

Tile {
    id: tile

    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled

    available: devices.wirelessDeviceAvailable
    toggleEnabled: enabledConnections.wirelessHwEnabled && !airplane
    checked: enabledConnections.wirelessEnabled && toggleEnabled
    iconName: checked ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic"
    label: i18n("Wi-Fi")
    status: {
        if (airplane) {
            return i18n("Airplane mode");
        }
        if (!enabledConnections.wirelessHwEnabled) {
            return i18n("Hardware switch off");
        }
        if (!checked) {
            return i18n("Off");
        }
        return wirelessStatus.wifiSSID || i18n("Not connected");
    }
    hasDetails: true
    detailsTooltip: i18n("Network settings")

    onActivated: handler.enableWireless(!checked)
    onDetailsRequested: root.openKcm("kcm_networkmanagement")

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.WirelessStatus {
        id: wirelessStatus
    }

    PlasmaNM.AvailableDevices {
        id: devices
    }

    PlasmaNM.Handler {
        id: handler
    }
}
