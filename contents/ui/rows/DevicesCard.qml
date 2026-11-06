import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import ".."

// Removable drives (USB sticks, SD cards, external disks, discs), from the same hotplug and
// Solid data the Disks & Devices applet uses. Only shown while one is plugged in.
Rectangle {
    id: card

    // Hotplug lists every mountable volume, internal ones included; keep the removable ones
    readonly property var devices: hotplug.sources.filter(udi => {
        const info = solid.data[udi];
        return info && (info["Removable"] || info["Hotpluggable"]);
    })
    readonly property bool available: devices.length > 0

    // udi → "busy" while removing, or an error message
    property var states: ({})

    implicitHeight: content.implicitHeight + pad * 2
    readonly property int pad: Math.round(Kirigami.Units.largeSpacing * 1.5)

    radius: Kirigami.Units.cornerRadius * 1.5
    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

    P5Support.DataSource {
        id: hotplug
        engine: "hotplug"
        connectedSources: sources
    }

    P5Support.DataSource {
        id: solid
        engine: "soliddevice"
        connectedSources: hotplug.sources
    }

    // Runs the safe-remove commands; reports failures (usually "target is busy") per device
    P5Support.DataSource {
        id: remover
        engine: "executable"
        onNewData: (source, data) => {
            const udi = source.split(" # ")[1];
            const next = Object.assign({}, card.states);
            if (data["exit code"] !== 0) {
                next[udi] = i18n("Still in use, close any open files first");
            } else {
                delete next[udi];
            }
            card.states = next;
            disconnectSource(source);
        }
    }

    function quoted(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    // Unmounts every partition of the drive, then powers it off so it can be pulled out.
    // Discs are ejected instead.
    function safelyRemove(udi) {
        const info = solid.data[udi] || {};
        const types = info["Device Types"] || [];
        let command;
        if (types.includes("Optical Disc")) {
            command = "eject " + quoted(info["Device"]);
        } else {
            command = "sh -c 'disk=$(lsblk -ndpo PKNAME \"$0\"); [ -n \"$disk\" ] || disk=\"$0\"; "
                + "for p in $(lsblk -nrpo NAME \"$disk\"); do mountpoint=$(lsblk -ndro MOUNTPOINT \"$p\"); "
                + "[ -n \"$mountpoint\" ] && { udisksctl unmount -b \"$p\" || exit 1; }; done; "
                + "udisksctl power-off -b \"$disk\"' " + quoted(info["Device"]);
        }
        const next = Object.assign({}, states);
        next[udi] = "busy";
        states = next;
        remover.connectSource(command + " # " + udi);
    }

    // Opens the drive in the file manager, mounting it first if needed
    function open(udi) {
        const info = solid.data[udi] || {};
        if (info["Accessible"] && info["File Path"]) {
            root.run("xdg-open " + quoted(info["File Path"]));
        } else {
            root.run("sh -c 'p=$(udisksctl mount -b \"$0\" | sed -n \"s/^Mounted .* at //p\"); [ -n \"$p\" ] && xdg-open \"$p\"' " + quoted(info["Device"]));
        }
        root.expanded = false;
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: Kirigami.Units.smallSpacing

        PC3.Label {
            text: i18n("Removable devices")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Repeater {
            model: card.devices

            delegate: ListRow {
                id: deviceRow
                required property string modelData
                readonly property var info: solid.data[modelData] || {}
                readonly property var hot: hotplug.data[modelData] || {}
                readonly property string removeState: card.states[modelData] ?? ""

                Layout.fillWidth: true
                // Inside the card, so less padding than on a page
                leftPadding: Kirigami.Units.smallSpacing
                iconName: hot["icon"] || info["Icon"] || "drive-removable-media"
                title: hot["text"] || info["Description"] || info["Label"] || i18n("Removable device")
                subtitle: {
                    if (removeState === "busy") {
                        return i18n("Removing…");
                    }
                    if (removeState !== "") {
                        return removeState;
                    }
                    if (!info["Accessible"]) {
                        return i18n("Not mounted");
                    }
                    if (info["Free Space Text"] && info["Size Text"]) {
                        return i18nc("Free space on a drive, e.g. 12 GiB free of 32 GiB", "%1 free of %2", info["Free Space Text"], info["Size Text"]);
                    }
                    return info["File Path"] || "";
                }
                busy: removeState === "busy"
                onClicked: card.open(modelData)

                PC3.ToolButton {
                    icon.name: "media-eject-symbolic"
                    icon.width: Kirigami.Units.iconSizes.small
                    icon.height: Kirigami.Units.iconSizes.small
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Safely remove")
                    enabled: deviceRow.removeState !== "busy"
                    onClicked: card.safelyRemove(deviceRow.modelData)

                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
