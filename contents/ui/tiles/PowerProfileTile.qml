import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.batterymonitor
import ".."

Tile {
    id: tile

    readonly property string profile: profiles.activeProfile
    readonly property var names: ({
        "power-saver": i18n("Power Save"),
        "balanced": i18n("Balanced"),
        "performance": i18n("Performance")
    })
    readonly property var icons: ({
        "power-saver": "battery-profile-powersave-symbolic",
        "balanced": "speedometer",
        "performance": "battery-profile-performance-symbolic"
    })

    available: profiles.isPowerProfileDaemonInstalled && profiles.profiles.length > 0
    // Highlighted whenever a non-default profile is active, like the battery applet's status
    checked: profile !== "" && profile !== (profiles.configuredProfile || "balanced")
    iconName: icons[profile] ?? "speedometer"
    label: i18n("Power Mode")
    status: names[profile] ?? profile
    hasDetails: true
    detailsTooltip: i18n("Power management settings")

    onActivated: menu.open(tile.width / 2, tile.height / 2)
    onDetailsRequested: root.openKcm("kcm_powerdevilprofilesconfig")

    PowerProfilesControl {
        id: profiles
        isSilent: true
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: tile
    }

    Instantiator {
        model: profiles.profiles
        delegate: PlasmaExtras.MenuItem {
            required property string modelData
            text: tile.names[modelData] ?? modelData
            icon: tile.icons[modelData] ?? ""
            checkable: true
            checked: modelData === tile.profile
            onClicked: profiles.setProfile(modelData)
        }
        onObjectAdded: (index, object) => menu.addMenuItem(object)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
