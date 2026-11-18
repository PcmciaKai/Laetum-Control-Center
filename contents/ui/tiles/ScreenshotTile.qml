import QtQuick
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.workspace.dbus as DBus
import ".."

// Spectacle, through its own global shortcuts: the same as pressing Meta+Shift+Print etc., so
// Spectacle's settings (save, copy, open the editor) apply. Click for a region; › for the rest.
Tile {
    id: tile

    property string pendingShortcut: ""

    iconName: "camera-photo-symbolic"
    label: i18n("Screenshot")
    status: i18n("Select a region")
    hasDetails: true
    detailsTooltip: i18n("More capture modes")

    onActivated: capture("RectangularRegionScreenShot")
    onDetailsRequested: menu.open(tile.width / 2, tile.height / 2)

    // The popup closes first so it isn't in the picture
    function capture(shortcut) {
        pendingShortcut = shortcut;
        root.expanded = false;
        captureDelay.restart();
    }

    Timer {
        id: captureDelay
        interval: 500
        onTriggered: DBus.SessionBus.asyncCall({
            "service": "org.kde.kglobalaccel",
            "path": "/component/org_kde_spectacle_desktop",
            "iface": "org.kde.kglobalaccel.Component",
            "member": "invokeShortcut",
            "arguments": [new DBus.string(tile.pendingShortcut)]
        }, () => {}, () => {})
    }

    PlasmaExtras.Menu {
        id: menu
        visualParent: tile

        PlasmaExtras.MenuItem {
            text: i18n("Region")
            icon: "transform-crop-symbolic"
            onClicked: tile.capture("RectangularRegionScreenShot")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Full screen")
            icon: "view-fullscreen-symbolic"
            onClicked: tile.capture("FullScreenScreenShot")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Active window")
            icon: "window-symbolic"
            onClicked: tile.capture("ActiveWindowScreenShot")
        }
        PlasmaExtras.MenuItem {
            separator: true
        }
        PlasmaExtras.MenuItem {
            text: i18n("Record a region")
            icon: "media-record-symbolic"
            onClicked: tile.capture("RecordRegion")
        }
        PlasmaExtras.MenuItem {
            text: i18n("Record the screen")
            icon: "media-record-symbolic"
            onClicked: tile.capture("RecordScreen")
        }
        PlasmaExtras.MenuItem {
            separator: true
        }
        PlasmaExtras.MenuItem {
            text: i18n("Open Spectacle")
            icon: "camera-photo-symbolic"
            onClicked: tile.capture("OpenWithoutScreenshot")
        }
    }
}
