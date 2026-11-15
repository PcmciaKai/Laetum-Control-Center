import QtQuick
import ".."

// VPN connections set up in the network settings. With one, the tile connects and
// disconnects it; with several, › (or a click while none is connected) lists them.
Tile {
    id: tile

    available: true
    toggleEnabled: !vpn.airplane
    checked: vpn.connected.length > 0
    iconName: "network-vpn-symbolic"
    label: i18n("VPN")
    status: {
        if (vpn.connected.length === 1) {
            return vpn.connected[0];
        }
        if (vpn.connected.length > 1) {
            return i18ncp("Number of connected VPNs", "%1 connected", "%1 connected", vpn.connected.length);
        }
        if (vpn.connecting) {
            return i18n("Connecting…");
        }
        return vpn.count === 0 ? i18n("Not set up") : i18n("Off");
    }
    hasDetails: true
    detailsTooltip: i18n("VPN connections")

    onActivated: {
        if (!vpn.quickToggle()) {
            root.pageRequested("vpn");
        }
    }
    onDetailsRequested: root.pageRequested("vpn")

    VpnControl {
        id: vpn
    }
}
