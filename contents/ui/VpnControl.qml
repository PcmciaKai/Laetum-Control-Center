import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.networkmanagement as PlasmaNM

// Saved VPN connections (OpenVPN, WireGuard, …) from NetworkManager, through plasma-nm like the
// Networks applet. Shared by the VPN tile and page.
Item {
    id: control

    readonly property alias model: vpnModel
    readonly property int count: vpnModel.count
    readonly property bool airplane: PlasmaNM.Configuration.airplaneModeEnabled

    // Connected and connecting ones (re-evaluated when a connection's state changes)
    readonly property var connected: {
        const list = [];
        for (let i = 0; i < connections.count; ++i) {
            const c = connections.objectAt(i);
            if (c && c.connected) {
                list.push(c.name);
            }
        }
        return list;
    }
    readonly property bool connecting: {
        for (let i = 0; i < connections.count; ++i) {
            const c = connections.objectAt(i);
            if (c && c.busy) {
                return true;
            }
        }
        return false;
    }

    // ---- IPv6 leak check ----
    // Many VPN configurations (OpenVPN files especially) only tunnel IPv4. If the normal
    // connection has IPv6, that traffic still goes out directly and websites see the real
    // address. Checked by asking which interface IPv6 internet traffic would use: a leak when
    // it isn't a tunnel (tun, WireGuard, tap or ppp).
    property bool ipv6Leak: false
    property string ipv6LeakDevice: ""

    function checkIpv6() {
        if (connected.length === 0) {
            ipv6Leak = false;
            return;
        }
        leakChecker.connectSource("sh -c 'ip -6 route get 2001:4860:4860::8888 2>/dev/null | grep -o \"dev [^ ]*\" | head -1 | cut -d\" \" -f2; "
            + "echo ---; nmcli -t -f DEVICE,TYPE connection show --active' # " + Date.now());
    }

    onConnectedChanged: Qt.callLater(checkIpv6)

    Timer {
        interval: 30000
        repeat: true
        running: control.connected.length > 0 && root.expanded
        triggeredOnStart: true
        onTriggered: control.checkIpv6()
    }

    P5Support.DataSource {
        id: leakChecker
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            const [routePart, activePart] = (data.stdout || "").split("---");
            const device = (routePart || "").trim();
            const tunnels = (activePart || "").trim().split("\n")
                .map(line => line.split(":"))
                .filter(([dev, type]) => dev && ["tun", "wireguard", "tap", "vpn-tun"].includes(type))
                .map(([dev]) => dev);
            const isTunnel = tunnels.includes(device) || /^(tun|tap|wg|ppp|ipsec)/.test(device);
            control.ipv6LeakDevice = device;
            control.ipv6Leak = control.connected.length > 0 && device !== "" && !isTunnel;
        }
    }

    function toggle(path, devicePath, specificPath, isActive) {
        if (isActive) {
            handler.deactivateConnection(path, devicePath);
        } else {
            handler.activateConnection(path, devicePath, specificPath);
        }
    }

    // One VPN: connect or disconnect it. Several: disconnect the connected ones, or return false
    // so the caller can show the list instead.
    function quickToggle() {
        if (count === 1) {
            const c = connections.objectAt(0);
            toggle(c.path, c.devicePath, c.specificPath, c.connected || c.busy);
            return true;
        }
        if (connected.length > 0) {
            for (let i = 0; i < connections.count; ++i) {
                const c = connections.objectAt(i);
                if (c.connected || c.busy) {
                    toggle(c.path, c.devicePath, c.specificPath, true);
                }
            }
            return true;
        }
        return false;
    }

    PlasmaNM.Handler {
        id: handler
    }

    PlasmaNM.NetworkModel {
        id: networkModel
    }

    // NetworkManager's WireGuard type isn't in plasma-nm's enum; its value in NetworkManagerQt
    readonly property int wireGuardType: 19

    KItemModels.KSortFilterProxyModel {
        id: vpnModel
        sourceModel: networkModel
        sortRoleName: "ItemUniqueName"
        filterRowCallback: (sourceRow, sourceParent) => {
            const type = networkModel.data(networkModel.index(sourceRow, 0, sourceParent), PlasmaNM.NetworkModel.TypeRole);
            return type === PlasmaNM.Enums.Vpn || type === control.wireGuardType;
        }
    }

    Instantiator {
        id: connections
        model: vpnModel
        delegate: QtObject {
            required property var model

            readonly property string name: model.ItemUniqueName ?? ""
            readonly property string path: model.ConnectionPath ?? ""
            readonly property string devicePath: model.DevicePath ?? ""
            readonly property string specificPath: model.SpecificPath ?? ""
            readonly property int state: model.ConnectionState ?? 0
            readonly property bool connected: state === PlasmaNM.Enums.Activated
            readonly property bool busy: state === PlasmaNM.Enums.Activating || state === PlasmaNM.Enums.Deactivating
        }
    }
}
