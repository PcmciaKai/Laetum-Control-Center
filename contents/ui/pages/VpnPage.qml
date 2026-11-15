import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

// The VPN connections set up in the network settings; click one to connect or disconnect it
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("VPN")
    readonly property string subtitle: {
        if (vpn.connected.length === 1) {
            return i18n("Connected to %1", vpn.connected[0]);
        }
        if (vpn.connected.length > 1) {
            return i18ncp("Number of connected VPNs", "%1 connected", "%1 connected", vpn.connected.length);
        }
        if (vpn.airplane) {
            return i18n("Airplane mode is on");
        }
        return vpn.count === 0 ? i18n("No VPN set up") : i18n("Not connected");
    }
    readonly property bool hasSwitch: false
    readonly property bool switchChecked: false
    readonly property bool switchEnabled: false
    readonly property bool available: true
    function toggleSwitch() {
    }

    spacing: Kirigami.Units.largeSpacing

    VpnControl {
        id: vpn
    }

    // IPv6 going around the VPN: websites still see the real address
    Rectangle {
        Layout.fillWidth: true
        visible: vpn.ipv6Leak
        implicitHeight: warningRow.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius * 1.5
        color: Qt.alpha(Kirigami.Theme.neutralTextColor, 0.15)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.neutralTextColor, 0.6)

        RowLayout {
            id: warningRow
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                source: "dialog-warning-symbolic"
                color: Kirigami.Theme.neutralTextColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                PC3.Label {
                    Layout.fillWidth: true
                    text: i18n("IPv6 isn't going through the VPN")
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
                PC3.Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: i18n("This VPN only carries IPv4, so websites that use IPv6 can still see your real address (through %1). Turn off IPv6 for your normal connection in the network settings, or use a VPN configuration that includes IPv6, such as WireGuard.", vpn.ipv6LeakDevice)
                    wrapMode: Text.WordWrap
                    font: Kirigami.Theme.smallFont
                    opacity: 0.85
                }
            }
        }
    }

    PC3.ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: vpn.count > 0

        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 2

            Repeater {
                model: vpn.model

                delegate: ListRow {
                    id: vpnRow
                    required property var model
                    readonly property int connState: model.ConnectionState
                    readonly property bool connected: connState === PlasmaNM.Enums.Activated
                    readonly property bool working: connState === PlasmaNM.Enums.Activating || connState === PlasmaNM.Enums.Deactivating

                    Layout.fillWidth: true
                    enabled: !vpn.airplane
                    iconName: "network-vpn-symbolic"
                    title: model.ItemUniqueName
                    subtitle: {
                        if (connState === PlasmaNM.Enums.Activating) {
                            return i18n("Connecting…");
                        }
                        if (connState === PlasmaNM.Enums.Deactivating) {
                            return i18n("Disconnecting…");
                        }
                        // e.g. "Connected · openvpn"
                        return [connected ? i18n("Connected") : "", model.VpnType || ""].filter(s => s !== "").join(" · ");
                    }
                    active: connected
                    busy: working
                    onClicked: vpn.toggle(model.ConnectionPath, model.DevicePath, model.SpecificPath, connected || working)

                    PC3.Label {
                        visible: vpnRow.hovered
                        text: connected || working ? i18n("Disconnect") : i18n("Connect")
                        font: Kirigami.Theme.smallFont
                        opacity: 0.7
                    }
                }
            }
        }
    }

    PlasmaExtras.PlaceholderMessage {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Kirigami.Units.gridUnit * 2
        Layout.rightMargin: Kirigami.Units.gridUnit * 2
        visible: vpn.count === 0
        iconName: "network-vpn-symbolic"
        text: i18n("No VPN set up")
        explanation: i18n("VPN connections are added in the network settings, for example by importing a configuration file from your VPN provider.")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.Button {
            icon.name: "list-add-symbolic"
            text: i18n("Add a VPN…")
            onClicked: root.openKcm("kcm_networkmanagement")
        }
        Item {
            Layout.fillWidth: true
        }
    }
}
