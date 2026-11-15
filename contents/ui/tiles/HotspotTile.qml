import QtQuick
import ".."

// Shares this computer's connection over Wi-Fi; › shows the network name and password
Tile {
    id: tile

    // Needs a Wi-Fi card that can be an access point
    available: hotspot.supported
    toggleEnabled: !hotspot.airplane
    checked: hotspot.active
    iconName: "network-wireless-hotspot-symbolic"
    label: i18n("Hotspot")
    status: checked ? hotspot.ssid : (hotspot.starting ? i18n("Starting…") : i18n("Off"))
    hasDetails: true
    detailsTooltip: i18n("Network name and password")

    onActivated: hotspot.toggle()
    onDetailsRequested: root.pageRequested("hotspot")

    HotspotControl {
        id: hotspot
    }
}
