import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.battery

Kirigami.Icon {
    readonly property bool available: battery.hasInternalBatteries

    source: {
        const level = Math.max(0, Math.min(100, Math.round(battery.percent / 10) * 10));
        const charging = battery.pluggedIn && battery.state === BatteryControlModel.Charging;
        return "battery-" + String(level).padStart(3, "0") + (charging ? "-charging" : "") + "-symbolic";
    }

    BatteryControlModel {
        id: battery
    }
}
