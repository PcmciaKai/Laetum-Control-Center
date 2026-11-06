import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.sessions as Sessions
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

// The popup: opaque header band, then tiles, sliders and media over the translucent body,
// with a settings search bar at the bottom, all in Laetum Launcher's design language
FocusScope {
    id: panel

    readonly property int pad: Kirigami.Units.gridUnit
    readonly property bool searching: root.searchText.length > 0
    readonly property color hairline: Qt.alpha(Kirigami.Theme.textColor, 0.12)
    readonly property color headerColor: Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.08)
    readonly property int headerIconSize: Math.round(Kirigami.Units.iconSizes.smallMedium * [1, 1.3, 1.6][Math.max(0, Math.min(2, Plasmoid.configuration.headerIconSize))])

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

    Layout.preferredWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.preferredHeight: column.implicitHeight
    Layout.minimumHeight: column.implicitHeight
    Layout.maximumHeight: column.implicitHeight

    function reset() {
        searchField.text = "";
        results.reset();
        if (Plasmoid.configuration.showSearch) {
            searchField.forceActiveFocus();
        }
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                panel.reset();
            }
        }
    }

    Component.onCompleted: reset()

    Sessions.SessionManagement {
        id: session
    }

    // Clock for the header on computers without a battery
    property date now: new Date()
    Timer {
        interval: 10000
        repeat: true
        running: root.expanded
        triggeredOnStart: true
        onTriggered: panel.now = new Date()
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 0

        // ---- Header: opaque band that reaches the popup's edges ----
        Item {
            id: header
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Math.round(panel.pad * 1.5)

            Kirigami.ShadowedRectangle {
                readonly property real cornerRadius: Plasmoid.location === PlasmaCore.Types.TopEdge ? 0 : Kirigami.Units.cornerRadius
                x: -panel.Kirigami.ScenePosition.x
                y: -panel.Kirigami.ScenePosition.y
                width: panel.Window.window ? panel.Window.width : header.width
                height: header.height - y
                color: panel.headerColor
                corners.topLeftRadius: cornerRadius
                corners.topRightRadius: cornerRadius
                corners.bottomLeftRadius: 0
                corners.bottomRightRadius: 0
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.leftMargin: panel.pad
                anchors.rightMargin: panel.pad
                spacing: Kirigami.Units.largeSpacing

                Loader {
                    id: batteryBadge
                    readonly property bool shown: status === Loader.Ready && item.available
                    Layout.fillWidth: true
                    visible: shown
                    source: "BatteryBadge.qml"
                }

                // Without a battery: today's date where the charge ring would be
                RowLayout {
                    Layout.fillWidth: true
                    visible: !batteryBadge.shown
                    spacing: Kirigami.Units.largeSpacing

                    Rectangle {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.5
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: "transparent"
                        border.width: 3
                        border.color: root.accentColor

                        PC3.Label {
                            anchors.centerIn: parent
                            text: panel.now.getDate()
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        PC3.Label {
                            Layout.fillWidth: true
                            text: panel.now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.25
                            elide: Text.ElideRight
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: panel.now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    spacing: Math.round(panel.headerIconSize * 0.5)

                    HeaderButton {
                        iconSize: panel.headerIconSize
                        iconName: "document-edit-symbolic"
                        tooltip: i18n("Edit tiles")
                        onClicked: root.openConfiguration()
                    }
                    HeaderButton {
                        iconSize: panel.headerIconSize
                        iconName: "configure-symbolic"
                        tooltip: i18n("System Settings")
                        onClicked: {
                            KCMUtils.KCMLauncher.openSystemSettings("");
                            root.expanded = false;
                        }
                    }
                    HeaderButton {
                        id: powerButton
                        iconSize: panel.headerIconSize
                        iconName: "system-shutdown-symbolic"
                        tooltip: i18n("Power")
                        onClicked: powerMenu.openRelative()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: panel.hairline
        }

        // ---- Body: controls, or settings search results while typing ----
        StackLayout {
            Layout.fillWidth: true
            Layout.leftMargin: panel.pad
            Layout.rightMargin: panel.pad
            Layout.topMargin: panel.pad
            currentIndex: panel.searching ? 1 : 0

            ColumnLayout {
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
                            source: panel.tileFiles[modelData] ? "tiles/" + panel.tileFiles[modelData] : ""
                            Layout.fillWidth: true
                            // Equal preferred widths + fillWidth = three equal columns
                            Layout.preferredWidth: Kirigami.Units.gridUnit
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.8
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    visible: Plasmoid.configuration.showSliders && (volumeRow.shown || brightnessRows.shown)

                    Loader {
                        id: volumeRow
                        readonly property bool shown: status === Loader.Ready && item.available
                        Layout.fillWidth: true
                        visible: shown
                        active: Plasmoid.configuration.showSliders
                        source: "rows/VolumeRow.qml"
                    }
                    Loader {
                        id: brightnessRows
                        readonly property bool shown: status === Loader.Ready && item.available
                        Layout.fillWidth: true
                        visible: shown
                        active: Plasmoid.configuration.showSliders
                        source: "rows/BrightnessRows.qml"
                    }
                }

                Loader {
                    id: media
                    readonly property bool shown: status === Loader.Ready && item.available
                    Layout.fillWidth: true
                    visible: shown
                    active: Plasmoid.configuration.showMedia
                    source: "rows/MediaCard.qml"
                }
            }

            SettingsResults {
                id: results
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // ---- Search bar, the same as Laetum Launcher's ----
        Rectangle {
            id: searchBar
            visible: Plasmoid.configuration.showSearch
            Layout.fillWidth: true
            Layout.margins: panel.pad
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.6
            radius: Kirigami.Units.cornerRadius * 1.5
            color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
            border.width: 1
            border.color: searchField.activeFocus ? Qt.alpha(root.accentColor, 0.5) : panel.hairline

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.leftMargin: parent.radius / 2
                anchors.rightMargin: parent.radius / 2
                height: 3
                radius: 1.5
                color: root.accentColor
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.smallSpacing

                PC3.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    focus: true
                    background: null
                    placeholderText: i18n("Search settings")
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    onTextChanged: root.searchText = text

                    Keys.onPressed: (event) => {
                        switch (event.key) {
                        case Qt.Key_Up:
                        case Qt.Key_Down:
                            if (panel.searching) {
                                results.moveKey(event.key);
                                event.accepted = true;
                            }
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            if (panel.searching) {
                                results.activate();
                                event.accepted = true;
                            }
                            break;
                        case Qt.Key_Escape:
                            if (text !== "") {
                                text = "";
                            } else {
                                root.expanded = false;
                            }
                            event.accepted = true;
                            break;
                        }
                    }
                }

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    source: "search-symbolic"
                    opacity: 0.7
                }
            }
        }

        // Bottom padding when the search bar is hidden
        Item {
            visible: !searchBar.visible
            Layout.preferredHeight: panel.pad
        }
    }

    PlasmaExtras.Menu {
        id: powerMenu
        visualParent: powerButton

        PlasmaExtras.MenuItem { text: i18n("Lock"); icon: "system-lock-screen"; visible: session.canLock; onClicked: { root.expanded = false; session.lock(); } }
        PlasmaExtras.MenuItem { text: i18n("Sleep"); icon: "system-suspend"; visible: session.canSuspend; onClicked: { root.expanded = false; session.suspend(); } }
        PlasmaExtras.MenuItem { text: i18n("Hibernate"); icon: "system-suspend-hibernate"; visible: session.canHibernate; onClicked: { root.expanded = false; session.hibernate(); } }
        PlasmaExtras.MenuItem { text: i18n("Restart"); icon: "system-reboot"; visible: session.canReboot; onClicked: { root.expanded = false; session.requestReboot(); } }
        PlasmaExtras.MenuItem { text: i18n("Shut Down"); icon: "system-shutdown"; visible: session.canShutdown; onClicked: { root.expanded = false; session.requestShutdown(); } }
        PlasmaExtras.MenuItem { separator: true }
        PlasmaExtras.MenuItem { text: i18n("Switch User"); icon: "system-switch-user"; visible: session.canSwitchUser; onClicked: { root.expanded = false; session.switchUser(); } }
        PlasmaExtras.MenuItem { text: i18n("Log Out"); icon: "system-log-out"; visible: session.canLogout; onClicked: { root.expanded = false; session.requestLogout(); } }
    }
}
