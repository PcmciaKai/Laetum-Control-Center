import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kitemmodels as KItemModels
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

// Wi-Fi networks, using the same models and connect logic as the Networks applet
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Wi-Fi")
    readonly property string subtitle: {
        if (PlasmaNM.Configuration.airplaneModeEnabled) {
            return i18n("Airplane mode is on");
        }
        if (!enabledConnections.wirelessEnabled) {
            return i18n("Off");
        }
        return wirelessStatus.wifiSSID ? i18n("Connected to %1", wirelessStatus.wifiSSID) : i18n("Not connected");
    }
    readonly property bool hasSwitch: true
    readonly property bool switchChecked: enabledConnections.wirelessEnabled
    readonly property bool switchEnabled: enabledConnections.wirelessHwEnabled && !PlasmaNM.Configuration.airplaneModeEnabled
    readonly property bool available: devices.wirelessDeviceAvailable
    function toggleSwitch() {
        handler.enableWireless(!enabledConnections.wirelessEnabled);
    }

    readonly property bool wifiOn: enabledConnections.wirelessEnabled && switchEnabled

    spacing: Kirigami.Units.largeSpacing

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
    PlasmaNM.NetworkModel {
        id: networkModel
    }
    // Sorted like the Networks applet: connected first, then saved, then by signal
    PlasmaNM.AppletProxyModel {
        id: appletModel
        sourceModel: networkModel
    }
    KItemModels.KSortFilterProxyModel {
        id: wifiModel
        sourceModel: appletModel
        filterRowCallback: (sourceRow, sourceParent) =>
            appletModel.data(appletModel.index(sourceRow, 0, sourceParent), PlasmaNM.NetworkModel.TypeRole) === PlasmaNM.Enums.Wireless
    }

    Timer {
        interval: 10200
        repeat: true
        triggeredOnStart: true
        running: root.expanded && page.visible && page.wifiOn
        onTriggered: handler.requestScan()
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: page.wifiOn ? wifiModel : null
        // Keep keyboard focus inside the list
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
            iconName: page.wifiOn ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic"
            text: page.wifiOn ? i18n("Looking for networks…") : page.subtitle
        }

        delegate: ColumnLayout {
            id: entry

            required property int index
            required property var model

            readonly property int connState: model.ConnectionState
            readonly property bool connected: connState === PlasmaNM.Enums.Activated
            readonly property bool busy: connState === PlasmaNM.Enums.Activating || connState === PlasmaNM.Enums.Deactivating
            readonly property bool secured: model.SecurityType !== PlasmaNM.Enums.NoneSecurity
                && model.SecurityType !== PlasmaNM.Enums.UnknownSecurity
            readonly property bool passwordIsStatic: [PlasmaNM.Enums.StaticWep, PlasmaNM.Enums.WpaPsk,
                PlasmaNM.Enums.Wpa2Psk, PlasmaNM.Enums.SAE].includes(model.SecurityType)
            // A new network whose password we can ask for right here; anything else
            // (enterprise Wi-Fi etc.) goes through Plasma's usual secrets dialog
            readonly property bool askInline: !model.Uuid && passwordIsStatic
            property bool askingPassword: false

            width: list.width - (vbar.size < 1 ? vbar.width + Kirigami.Units.smallSpacing : 0)
            spacing: Kirigami.Units.smallSpacing

            // Stop the list re-sorting under the user while they type a password
            function setDelayModelUpdates(delay) {
                wifiModel.setData(wifiModel.index(index, 0), delay, PlasmaNM.NetworkModel.DelayModelUpdatesRole);
            }

            function toggle() {
                if (connected || busy) {
                    handler.deactivateConnection(model.ConnectionPath, model.DevicePath);
                } else if (model.Uuid) {
                    handler.activateConnection(model.ConnectionPath, model.DevicePath, model.SpecificPath);
                } else if (askInline) {
                    askingPassword = true;
                    setDelayModelUpdates(true);
                    passwordField.forceActiveFocus();
                } else {
                    handler.addAndActivateConnection(model.DevicePath, model.SpecificPath);
                }
            }

            function submitPassword() {
                if (passwordField.text === "") {
                    return;
                }
                handler.addAndActivateConnection(model.DevicePath, model.SpecificPath, passwordField.text);
                cancelPassword();
            }

            function cancelPassword() {
                passwordField.text = "";
                askingPassword = false;
                setDelayModelUpdates(false);
            }

            ListRow {
                Layout.fillWidth: true
                iconName: entry.model.ConnectionIcon
                title: entry.model.ItemUniqueName
                subtitle: {
                    if (entry.busy) {
                        return entry.model.DeviceState;
                    }
                    const security = entry.secured ? entry.model.SecurityTypeString : i18n("Open");
                    if (entry.connected) {
                        return i18n("Connected · %1", security);
                    }
                    return entry.model.Uuid ? i18n("Saved · %1", security) : security;
                }
                active: entry.connected
                busy: entry.busy
                onClicked: {
                    if (!entry.connected) {
                        entry.toggle();
                    }
                }

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    visible: entry.secured && !entry.connected
                    source: "object-locked-symbolic"
                    opacity: 0.7
                }

                PC3.Button {
                    visible: entry.connected || entry.busy
                    text: entry.busy ? i18n("Cancel") : i18n("Disconnect")
                    onClicked: entry.toggle()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.largeSpacing
                Layout.rightMargin: Kirigami.Units.largeSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                visible: entry.askingPassword
                spacing: Kirigami.Units.smallSpacing

                PC3.TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    echoMode: TextInput.Password
                    placeholderText: i18n("Password")
                    onAccepted: entry.submitPassword()
                    Keys.onEscapePressed: (event) => {
                        entry.cancelPassword();
                        event.accepted = true;
                    }
                }
                PC3.Button {
                    text: i18n("Connect")
                    enabled: passwordField.text !== ""
                    onClicked: entry.submitPassword()
                }
                PC3.ToolButton {
                    icon.name: "dialog-cancel-symbolic"
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Cancel")
                    onClicked: entry.cancelPassword()
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "configure-symbolic"
            text: i18n("Network settings")
            onClicked: root.openKcm("kcm_networkmanagement")
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
