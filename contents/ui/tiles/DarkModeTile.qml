import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import ".."

// Switches between light and dark.
// With default light and dark global themes set in System Settings (Plasma 6.5+) it applies
// those. Otherwise it switches the three things that make up "light" or "dark": the colour
// scheme, the Plasma style (some, like Nobara or Breeze Dark, are always dark) and the icon
// theme. It remembers the ones it switched away from, so custom choices come back.
Tile {
    id: tile

    // What's applied right now, read from the config files
    property var current: ({})
    readonly property bool useLookAndFeel: (current.lightLookAndFeel ?? "") !== "" && (current.darkLookAndFeel ?? "") !== ""

    // From the applied window colours, not this popup's: the Plasma style can stay dark
    // under a light colour scheme
    readonly property bool isDark: {
        const parts = String(current.windowColor ?? "").split(",").map(Number);
        if (parts.length >= 3 && parts.every(n => !isNaN(n))) {
            return (0.299 * parts[0] + 0.587 * parts[1] + 0.114 * parts[2]) / 255 < 0.5;
        }
        return Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Dark;
    }

    checked: isDark
    iconName: checked ? "weather-clear-night-symbolic" : "contrast-symbolic"
    label: i18n("Dark Mode")
    status: checked ? i18n("On") : i18n("Off")

    readonly property string readCommand: "sh -c '"
        + "kreadconfig6 --group General --key ColorScheme; "
        + "kreadconfig6 --file plasmarc --group Theme --key name; "
        + "kreadconfig6 --group Icons --key Theme; "
        + "kreadconfig6 --group Colors:Window --key BackgroundNormal; "
        + "kreadconfig6 --group KDE --key DefaultLightLookAndFeel; "
        + "kreadconfig6 --group KDE --key DefaultDarkLookAndFeel'"

    function quoted(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    onActivated: {
        const toLight = isDark;
        if (useLookAndFeel) {
            root.run("plasma-apply-lookandfeel -a " + quoted(toLight ? current.lightLookAndFeel : current.darkLookAndFeel));
        } else {
            const config = Plasmoid.configuration;
            const leaving = toLight ? "dark" : "light";
            const going = toLight ? "light" : "dark";
            const remember = (key, value) => {
                // Don't remember a value the other side uses: after a half-done switch the
                // style or icons can still be the other side's
                if (value && value !== config[going + key]) {
                    config[leaving + key] = value;
                }
            };
            remember("ColorScheme", current.colorScheme);
            remember("PlasmaStyle", current.plasmaStyle);
            remember("IconTheme", current.iconTheme);

            const scheme = config[going + "ColorScheme"];
            const style = config[going + "PlasmaStyle"];
            const icons = config[going + "IconTheme"];
            let command = "plasma-apply-colorscheme " + quoted(scheme);
            if (style && style !== current.plasmaStyle) {
                command += "; plasma-apply-desktoptheme " + quoted(style);
            }
            if (icons && icons !== current.iconTheme) {
                // plasma-changeicons isn't on PATH; it lives in the libexec directory
                command += "; for d in /usr/libexec /usr/lib/libexec /usr/lib64/libexec /usr/lib/*/libexec; do "
                    + "[ -x \"$d/plasma-changeicons\" ] && exec \"$d/plasma-changeicons\" " + quoted(icons) + "; done";
            }
            root.run("sh -c " + quoted(command));
        }
        refreshDelay.restart();
    }

    P5Support.DataSource {
        id: reader
        engine: "executable"
        onNewData: (source, data) => {
            const lines = (data.stdout || "").split("\n").map(l => l.trim());
            tile.current = {
                "colorScheme": lines[0] || "",
                // An empty value means the default
                "plasmaStyle": lines[1] || "default",
                "iconTheme": lines[2] || "breeze",
                "windowColor": lines[3] || "",
                "lightLookAndFeel": lines[4] || "",
                "darkLookAndFeel": lines[5] || ""
            };
            disconnectSource(source);
        }
    }

    function refresh() {
        reader.connectSource(readCommand + " # " + Date.now());
    }

    // Applying takes a moment; read the result back afterwards so the tile follows
    Timer {
        id: refreshDelay
        interval: 1500
        onTriggered: tile.refresh()
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                tile.refresh();
            }
        }
    }

    Component.onCompleted: refresh()
}
