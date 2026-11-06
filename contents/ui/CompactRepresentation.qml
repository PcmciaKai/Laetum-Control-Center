import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Panel button: network, volume and battery indicators side by side, like the system tray.
// Each indicator lives in its own file so a missing Plasma component only hides that icon.
MouseArea {
    id: compact

    property bool wasExpanded: false
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int iconSize: {
        const thickness = vertical ? width : height;
        // Same default as the system tray: small-medium icons, smaller only on thin panels
        return Math.min(Kirigami.Units.iconSizes.smallMedium, Kirigami.Units.iconSizes.roundedIconSize(thickness));
    }
    readonly property bool anyIndicator: network.shown || volume.shown || battery.shown || notifications.shown

    Layout.minimumWidth: vertical ? -1 : layout.implicitWidth + Kirigami.Units.smallSpacing * 2
    Layout.maximumWidth: vertical ? -1 : Layout.minimumWidth
    Layout.minimumHeight: vertical ? layout.implicitHeight + Kirigami.Units.smallSpacing * 2 : -1
    Layout.maximumHeight: vertical ? Layout.minimumHeight : -1

    hoverEnabled: true
    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded

    // Scroll anywhere on the button to change the volume
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (volume.item && volume.item.step) {
                volume.item.step(event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x);
            }
        }
    }

    GridLayout {
        id: layout
        anchors.centerIn: parent
        flow: compact.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        rowSpacing: Kirigami.Units.smallSpacing
        columnSpacing: Kirigami.Units.smallSpacing

        Loader {
            id: network
            readonly property bool shown: Plasmoid.configuration.showNetworkIndicator && status === Loader.Ready && item.available
            visible: shown
            active: Plasmoid.configuration.showNetworkIndicator
            source: "indicators/NetworkIndicator.qml"
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
        }
        Loader {
            id: volume
            readonly property bool shown: Plasmoid.configuration.showVolumeIndicator && status === Loader.Ready && item.available
            visible: shown
            source: "indicators/VolumeIndicator.qml"
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
        }
        Loader {
            id: battery
            readonly property bool shown: Plasmoid.configuration.showBatteryIndicator && status === Loader.Ready && item.available
            visible: shown
            active: Plasmoid.configuration.showBatteryIndicator
            source: "indicators/BatteryIndicator.qml"
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
        }
        Loader {
            id: notifications
            readonly property bool shown: Plasmoid.configuration.showNotificationIndicator && status === Loader.Ready && item.available
            visible: shown
            active: Plasmoid.configuration.showNotificationIndicator
            source: "indicators/NotificationIndicator.qml"
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
        }

        // Fallback when every indicator is hidden or unavailable
        Kirigami.Icon {
            visible: !compact.anyIndicator
            source: Plasmoid.icon
            active: compact.containsMouse
            Layout.preferredWidth: compact.iconSize
            Layout.preferredHeight: compact.iconSize
        }
    }
}
