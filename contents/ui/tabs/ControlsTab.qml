import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Tiles, sliders and the now-playing card. Every tile and row is its own Loader, so a
// missing Plasma component only hides that part.
Item {
    id: controls

    // Tile id (as stored in the "tiles" setting) → file in tiles/
    readonly property var tileFiles: ({
        "wifi": "WifiTile.qml",
        "bluetooth": "BluetoothTile.qml",
        "nightlight": "NightLightTile.qml",
        "dnd": "DndTile.qml",
        "airplane": "AirplaneTile.qml",
        "powerprofile": "PowerProfileTile.qml",
        "microphone": "MicrophoneTile.qml",
        "kdeconnect": "KdeConnectTile.qml",
        "keepawake": "KeepAwakeTile.qml"
    })

    // The tab area can be taller than this (it's sized for the calendar too); the content
    // stays at the top
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.largeSpacing * 2

        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 3
            rowSpacing: Kirigami.Units.smallSpacing * 2
            columnSpacing: rowSpacing

            Repeater {
                model: Plasmoid.configuration.tiles

                delegate: Loader {
                    required property string modelData
                    readonly property bool shown: status === Loader.Ready && item.available

                    visible: shown
                    source: controls.tileFiles[modelData] ? "../tiles/" + controls.tileFiles[modelData] : ""
                    Layout.fillWidth: true
                    // Equal preferred widths + fillWidth = three equal columns
                    Layout.preferredWidth: Kirigami.Units.gridUnit
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: Plasmoid.configuration.showSliders && (volumeRow.shown || brightnessRows.shown)

            Loader {
                id: volumeRow
                readonly property bool shown: status === Loader.Ready && item.available
                Layout.fillWidth: true
                visible: shown
                active: Plasmoid.configuration.showSliders
                source: "../rows/VolumeRow.qml"
            }
            Loader {
                id: brightnessRows
                readonly property bool shown: status === Loader.Ready && item.available
                Layout.fillWidth: true
                visible: shown
                active: Plasmoid.configuration.showSliders
                source: "../rows/BrightnessRows.qml"
            }
        }

        Loader {
            readonly property bool shown: status === Loader.Ready && item.available
            Layout.fillWidth: true
            visible: shown
            active: Plasmoid.configuration.showMedia
            source: "../rows/MediaCard.qml"
        }
    }
}
