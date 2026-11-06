import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon
    preferredRepresentation: compactRepresentation
    hideOnWindowDeactivate: true
    toolTipMainText: Plasmoid.title
    toolTipSubText: i18n("Quick settings, volume, brightness and media")

    // Settings search, shared by the popup
    property string searchText: ""

    readonly property Kicker.RunnerModel runnerModel: Kicker.RunnerModel {
        appletInterface: root
        mergeResults: true
        runners: ["krunner_systemsettings"]
        query: root.searchText
    }

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
