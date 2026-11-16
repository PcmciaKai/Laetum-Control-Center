import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.battery

// Laptops: the charge in the ring, whether it's plugged in and charging, and the time left
HeaderBadge {
    id: badge

    readonly property int remaining: battery.smoothedRemainingMsec

    available: battery.hasInternalBatteries
    percent: battery.percent
    title: {
        switch (battery.state) {
        case BatteryControlModel.Charging:
            return i18n("Plugged in, charging");
        case BatteryControlModel.FullyCharged:
            return i18n("Plugged in, fully charged");
        default:
            return battery.pluggedIn ? i18n("Plugged in, not charging") : i18n("On battery");
        }
    }
    subtitle: {
        if (remaining <= 0) {
            return "";
        }
        const time = KCoreAddons.Format.formatDuration(remaining, KCoreAddons.FormatTypes.HideSeconds);
        switch (battery.state) {
        case BatteryControlModel.Charging:
            return i18nc("Time until the battery is full", "%1 until full", time);
        case BatteryControlModel.Discharging:
            return i18nc("Battery time left", "%1 remaining", time);
        default:
            return "";
        }
    }

    BatteryControlModel {
        id: battery
    }
}
