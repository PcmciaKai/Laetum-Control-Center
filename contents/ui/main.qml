import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon
    preferredRepresentation: compactRepresentation
    hideOnWindowDeactivate: true
    toolTipMainText: Plasmoid.title
    toolTipSubText: i18n("Quick settings, volume, brightness and media")

    // Same accent handling as Laetum Launcher: the colour scheme's accent colour, even with
    // Plasma styles that ship their own highlight colour
    property color accentColor: Kirigami.Theme.highlightColor
    readonly property string accentCommand: "sh -c 'a=$(kreadconfig6 --group General --key AccentColor); "
        + "[ -n \"$a\" ] || a=$(kreadconfig6 --group Colors:Selection --key BackgroundNormal); echo \"$a\"'"

    function refreshAccent() {
        accentReader.connectSource(accentCommand);
    }

    P5Support.DataSource {
        id: accentReader
        engine: "executable"
        onNewData: (source, data) => {
            const parts = (data.stdout || "").trim().split(",").map(Number);
            if (parts.length >= 3 && parts.every(n => !isNaN(n))) {
                root.accentColor = Qt.rgba(parts[0] / 255, parts[1] / 255, parts[2] / 255, 1);
            }
            disconnectSource(source);
        }
    }

    // ---- Helpers used by the tiles and rows ----
    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }

    function run(command) {
        // The executable engine ignores a source that is still connected, so make each run unique
        executable.connectSource(command + " # " + Date.now());
    }

    // Launch by desktop file ID if one exists, otherwise as a command
    function runApp(id) {
        const quoted = "'" + String(id).replace(/'/g, "'\\''") + "'";
        run("sh -c 'for d in \"${XDG_DATA_HOME:-$HOME/.local/share}\" $(echo \"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}\" | tr : \" \"); do "
            + "[ -e \"$d/applications/$0.desktop\" ] && exec kstart --application \"$0\"; done; exec kstart -- \"$0\"' " + quoted);
        root.expanded = false;
    }

    function openKcm(name) {
        KCMUtils.KCMLauncher.openSystemSettings(name);
        root.expanded = false;
    }

    // Tiles ask the popup to slide in one of the pages in pages/ ("wifi", "bluetooth", "audio", ...)
    signal pageRequested(string page)

    // Through Klipper, so it works with the popup closed and lands in the clipboard history.
    // Without Klipper (the tray's Clipboard entry turned off) through Qt's clipboard instead.
    function copyText(text) {
        if (!klipper.registered) {
            copyHelper.text = text;
            copyHelper.selectAll();
            copyHelper.copy();
            return;
        }
        DBus.SessionBus.asyncCall({
            "service": "org.kde.klipper",
            "path": "/klipper",
            "iface": "org.kde.klipper.klipper",
            "member": "setClipboardContents",
            "signature": "s",
            "arguments": [new DBus.string(text)]
        });
    }

    DBus.DBusServiceWatcher {
        id: klipper
        busType: DBus.BusType.Session
        watchedService: "org.kde.klipper"
    }

    TextEdit {
        id: copyHelper
        visible: false
    }

    // ---- Colour picker ----
    readonly property int colorHistoryLength: 12

    function rememberColor(hex) {
        const history = Array.from(Plasmoid.configuration.colorHistory).filter(c => c !== hex);
        history.unshift(hex);
        Plasmoid.configuration.colorHistory = history.slice(0, colorHistoryLength);
    }

    // KWin's picker (the one the Color Picker applet uses): crosshair, click, ARGB back.
    // The popup closes first so it isn't in the way.
    function pickColor() {
        root.expanded = false;
        pickDelay.start();
    }

    Timer {
        id: pickDelay
        interval: Kirigami.Units.longDuration * 2
        onTriggered: DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin",
            "path": "/ColorPicker",
            "iface": "org.kde.kwin.ColorPicker",
            "member": "pick"
        }, (reply) => {
            let argb = reply.value;
            if (Array.isArray(argb)) {
                argb = argb[0];
            }
            argb = Number(argb);
            if (isNaN(argb)) {
                return;
            }
            const hex = "#" + (argb & 0xffffff).toString(16).padStart(6, "0").toUpperCase();
            root.rememberColor(hex);
            root.copyText(hex);
        }, () => {
            // Escape cancels the pick with an error reply
        })
    }

    function openConfiguration() {
        Plasmoid.internalAction("configure").trigger();
        root.expanded = false;
    }

    onExpandedChanged: {
        if (root.expanded) {
            refreshAccent();
        }
    }

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: Panel {}

    Component.onCompleted: refreshAccent()
}
