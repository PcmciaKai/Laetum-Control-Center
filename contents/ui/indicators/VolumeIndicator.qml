import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.volume

Kirigami.Icon {
    id: indicator

    readonly property var sink: PreferredDevice.sink
    readonly property bool available: sink !== null
    readonly property int percent: sink ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : 0

    source: sink ? AudioIcon.forVolume(percent, sink.muted, "") : "audio-volume-muted"

    property real wheelRemainder: 0

    // Called by the panel button: one wheel notch (120) changes the volume by 5 %
    function step(delta) {
        if (!sink) {
            return;
        }
        wheelRemainder += delta;
        const notches = Math.trunc(wheelRemainder / 120);
        if (notches === 0) {
            return;
        }
        wheelRemainder -= notches * 120;
        const next = Math.max(0, Math.min(100, percent + notches * 5));
        sink.muted = false;
        sink.volume = Math.round(next / 100 * PulseAudio.NormalVolume);
    }
}
