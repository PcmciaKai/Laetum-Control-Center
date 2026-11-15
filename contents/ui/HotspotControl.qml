import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

// Wi-Fi hotspot through plasma-nm, the same one the Networks applet's hotspot button starts.
// Name and password are plasma-nm's own settings, shared with that applet.
Item {
    id: control

    // plasma-nm only reports hotspot support while Wi-Fi is on, so offer it whenever there is
    // a Wi-Fi card; start() turns Wi-Fi on first if needed
    readonly property bool supported: handler.hotspotSupported || devices.wirelessDeviceAvailable
    readonly property bool starting: pendingStart.running
    readonly property bool active: handler.hotspotActive
    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled
    // While running. (Configuration.hotspotName has no change signal, so it can't be bound to.)
    readonly property string ssid: wirelessStatus.hotspotSSID

    // WPA needs at least 8 characters; plasma-nm would otherwise start an open network
    readonly property int minimumPasswordLength: 8

    function randomPassword() {
        // No look-alike characters (0/O, 1/l/I), so it's easy to type on a phone
        const alphabet = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        let password = "";
        for (let i = 0; i < 12; ++i) {
            password += alphabet[Math.floor(Math.random() * alphabet.length)];
        }
        return password;
    }

    function start() {
        if (PlasmaNM.Configuration.hotspotPassword.length < minimumPasswordLength) {
            PlasmaNM.Configuration.hotspotPassword = randomPassword();
        }
        if (handler.hotspotSupported) {
            handler.createHotspot();
        } else if (!enabledConnections.wirelessEnabled) {
            handler.enableWireless(true);
            pendingStart.restart();
        }
    }

    function stop() {
        pendingStart.stop();
        handler.stopHotspot();
    }

    // Waiting for plasma-nm to see the Wi-Fi card after turning Wi-Fi on; gives up after a while
    Timer {
        id: pendingStart
        interval: 10000
    }

    Connections {
        target: handler
        function onHotspotSupportedChanged() {
            if (handler.hotspotSupported && pendingStart.running) {
                pendingStart.stop();
                handler.createHotspot();
            }
        }
    }

    function toggle() {
        if (active) {
            stop();
        } else {
            start();
        }
    }

    PlasmaNM.Handler {
        id: handler
    }

    PlasmaNM.WirelessStatus {
        id: wirelessStatus
    }

    PlasmaNM.EnabledConnections {
        id: enabledConnections
    }

    PlasmaNM.AvailableDevices {
        id: devices
    }
}
