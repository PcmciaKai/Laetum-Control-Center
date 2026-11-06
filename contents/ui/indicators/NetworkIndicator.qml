import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM

Kirigami.Icon {
    readonly property bool available: connectionIcon.connectionIcon !== ""

    source: connectionIcon.connectionIcon + "-symbolic"

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIcon
        connectivity: networkStatus.connectivity
    }
}
