import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import ".."

// A tile that runs your own shell commands (set up in Configure → Custom Tiles):
//  - ON and OFF commands: a toggle. With a status command (exit code 0 = on) it shows the
//    real state; without one it remembers the state it last set.
//  - Only an ON command: a button that runs it on every click.
// Idea from Kontrol Center by ItsNotMeBro87 (https://github.com/ItsNotMeBro87/plasma6-kontrol-center).
Tile {
    id: tile

    // 1 or 2; set by Custom1Tile.qml / Custom2Tile.qml
    property int slot: 1

    readonly property string key: "custom" + slot
    readonly property string name: Plasmoid.configuration[key + "Name"] ?? ""
    readonly property string onCommand: (Plasmoid.configuration[key + "OnCommand"] ?? "").trim()
    readonly property string offCommand: (Plasmoid.configuration[key + "OffCommand"] ?? "").trim()
    readonly property string statusCommand: (Plasmoid.configuration[key + "StatusCommand"] ?? "").trim()

    readonly property bool configured: onCommand !== "" || offCommand !== ""
    readonly property bool hasStatus: statusCommand !== ""
    // Just an ON command: a button, not a toggle
    readonly property bool isButton: onCommand !== "" && offCommand === "" && !hasStatus
    readonly property bool rememberedOn: Plasmoid.configuration[key + "On"] ?? false

    // From the status command; -1 until it has answered
    property int reportedState: -1
    property bool running: false

    available: true
    checked: !isButton && (hasStatus ? reportedState === 1 : rememberedOn)
    iconName: Plasmoid.configuration[key + "Icon"] || "system-run-symbolic"
    label: name || i18n("Custom %1", slot)
    status: {
        if (!configured) {
            return i18n("Not set up");
        }
        if (running) {
            return i18n("Running…");
        }
        if (isButton) {
            return i18nc("A custom tile that runs a command when clicked", "Run");
        }
        return checked ? i18n("On") : i18n("Off");
    }
    hasDetails: true
    detailsTooltip: i18n("Edit this tile")

    onActivated: {
        if (!configured) {
            openSettings();
        } else if (isButton) {
            execute(onCommand);
        } else {
            const turnOn = !checked;
            if (hasStatus) {
                reportedState = turnOn ? 1 : 0;
            } else {
                Plasmoid.configuration[key + "On"] = turnOn;
            }
            execute(turnOn ? onCommand : offCommand);
        }
    }
    onDetailsRequested: openSettings()

    function openSettings() {
        root.expanded = false;
        Plasmoid.internalAction("configure").trigger();
    }

    // Through sh, so pipes, && and ~ work; the timestamp keeps each run a separate source
    function shell(command) {
        return "sh -c '" + command.replace(/'/g, "'\\''") + "' # " + Date.now();
    }

    function execute(command) {
        if (command === "") {
            refreshStatus();
            return;
        }
        running = true;
        commandRunner.connectSource(shell(command));
    }

    function refreshStatus() {
        if (hasStatus) {
            statusRunner.connectSource(shell(statusCommand));
        }
    }

    // Asks again when the popup opens and every few seconds while it's open, so a state changed
    // elsewhere shows up
    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                tile.refreshStatus();
            }
        }
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.expanded && tile.hasStatus
        onTriggered: tile.refreshStatus()
    }
    Component.onCompleted: refreshStatus()
    onStatusCommandChanged: {
        reportedState = -1;
        refreshStatus();
    }

    P5Support.DataSource {
        id: commandRunner
        engine: "executable"
        onNewData: source => {
            disconnectSource(source);
            tile.running = false;
            tile.refreshStatus();
        }
    }

    P5Support.DataSource {
        id: statusRunner
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            tile.reportedState = data["exit code"] === 0 ? 1 : 0;
        }
    }
}
