import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.bluezqt as BluezQt
import org.kde.plasma.private.bluetooth as PlasmaBt
import ".."

// Paired Bluetooth devices, using the same models and connect calls as the Bluetooth applet
ColumnLayout {
    id: page

    readonly property var connected: BluezQt.Manager.connectedDevices

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Bluetooth")
    readonly property string subtitle: {
        if (!BluezQt.Manager.bluetoothOperational) {
            return i18n("Off");
        }
        if (connected.length === 0) {
            return i18n("No devices connected");
        }
        if (connected.length === 1) {
            return i18n("Connected to %1", connected[0].name);
        }
        return i18ncp("Number of connected devices", "%1 device connected", "%1 devices connected", connected.length);
    }
    readonly property bool hasSwitch: true
    readonly property bool switchChecked: BluezQt.Manager.bluetoothOperational
    readonly property bool switchEnabled: true
    readonly property bool available: BluezQt.Manager.bluetoothBlocked || BluezQt.Manager.adapters.length > 0
    function toggleSwitch() {
        const enable = !BluezQt.Manager.bluetoothOperational;
        BluezQt.Manager.bluetoothBlocked = !enable;
        BluezQt.Manager.adapters.forEach(adapter => {
            adapter.powered = enable;
        });
    }

    spacing: Kirigami.Units.largeSpacing

    // Paired and connected devices, sorted like the applet does
    PlasmaBt.DevicesProxyModel {
        id: devicesModel
        hideBlockedDevices: true
        sourceModel: PlasmaBt.SharedDevicesStateProxyModel
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: BluezQt.Manager.bluetoothOperational ? devicesModel : null
        keyNavigationEnabled: true

        PC3.ScrollBar.vertical: PC3.ScrollBar {
            id: vbar
        }

        Kirigami.WheelHandler {
            target: list
            filterMouseEvents: true
        }

        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: list.count === 0
            iconName: "network-bluetooth"
            text: BluezQt.Manager.bluetoothOperational ? i18n("No paired devices") : i18n("Bluetooth is off")
        }

        delegate: ListRow {
            id: device

            required property var model

            width: list.width - (vbar.size < 1 ? vbar.width + Kirigami.Units.smallSpacing : 0)
            iconName: model.Icon
            title: model.Name
            subtitle: {
                if (model.Connecting) {
                    return i18n("Connecting…");
                }
                if (model.Disconnecting) {
                    return i18n("Disconnecting…");
                }
                if (model.Connected) {
                    return model.Battery ? i18n("Connected · %1% battery", model.Battery.percentage) : i18n("Connected");
                }
                return i18n("Not connected");
            }
            active: model.Connected
            busy: model.Connecting || model.Disconnecting
            enabled: !busy

            // Same calls as the Bluetooth applet, registered with its shared state model so
            // both show "Connecting…" while it happens
            onClicked: {
                if (model.Connected) {
                    const call = model.Device.disconnectFromDevice();
                    PlasmaBt.SharedDevicesStateProxyModel.registerDisconnectingCallForDeviceUbi(call, model.Ubi);
                } else {
                    const call = model.Device.connectToDevice();
                    PlasmaBt.SharedDevicesStateProxyModel.registerConnectingCallForDeviceUbi(call, model.Ubi);
                }
            }

            PC3.Label {
                visible: device.model.Connected
                text: i18n("Disconnect")
                opacity: device.hovered ? 0.85 : 0
                font: Kirigami.Theme.smallFont
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "list-add-symbolic"
            text: i18n("Pair device…")
            enabled: !BluezQt.Manager.bluetoothBlocked
            onClicked: {
                PlasmaBt.LaunchApp.launchWizard();
                root.expanded = false;
            }
        }
        Item {
            Layout.fillWidth: true
        }
        PC3.ToolButton {
            icon.name: "configure-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: i18n("Bluetooth settings")
            onClicked: root.openKcm("kcm_bluetooth")
            PC3.ToolTip.text: text
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
