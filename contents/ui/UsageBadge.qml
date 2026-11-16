import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.ksysguard.sensors as Sensors

// Desktops (or anyone who'd rather see it): CPU usage with the memory in use, or GPU usage
// with the video memory in use. Read from ksystemstats, like the System Monitor widgets.
HeaderBadge {
    id: badge

    // "cpu" or "gpu", set once (CpuBadge.qml, GpuBadge.qml)
    property string kind: "cpu"
    readonly property bool gpu: kind === "gpu"

    available: usage.status === Sensors.Sensor.Status.Ready
    percent: Number(usage.value) || 0
    title: gpu ? i18n("GPU usage") : i18n("CPU usage")
    subtitle: {
        const used = Number(memoryUsed.value);
        const total = Number(memoryTotal.value);
        if (!(total > 0)) {
            return "";
        }
        // ksystemstats reports memory in bytes; VRAM too
        const usedText = KCoreAddons.Format.formatByteSize(used, 1);
        const totalText = KCoreAddons.Format.formatByteSize(total, 1);
        return gpu ? i18nc("Video memory in use, e.g. 4.1 GiB of 16.0 GiB", "VRAM %1 of %2", usedText, totalText)
                   : i18nc("Memory in use, e.g. 9.3 GiB of 31.2 GiB", "RAM %1 of %2", usedText, totalText);
    }

    // Only while the popup is open
    readonly property bool live: root.expanded

    Sensors.Sensor {
        id: usage
        sensorId: badge.gpu ? "gpu/all/usage" : "cpu/all/usage"
        enabled: badge.live
        updateRateLimit: 1000
    }
    Sensors.Sensor {
        id: memoryUsed
        sensorId: badge.gpu ? "gpu/all/usedVram" : "memory/physical/used"
        enabled: badge.live
        updateRateLimit: 1000
    }
    Sensors.Sensor {
        id: memoryTotal
        sensorId: badge.gpu ? "gpu/all/totalVram" : "memory/physical/total"
        updateRateLimit: 10000
    }
}
