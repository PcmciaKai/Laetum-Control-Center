import QtQuick
import org.kde.notificationmanager as NotificationManager

// Counts unread notifications in a Notifications model.
// Not the model's own unreadNotificationsCount: in Plasma 6.7 that stops counting as soon as
// any notification is still active (a resident one, or one whose popup is still showing),
// so it often stays at 0.
QtObject {
    id: counter

    required property NotificationManager.Notifications model
    property int count: 0

    function recount() {
        let unread = 0;
        for (let i = 0; i < model.count; ++i) {
            const idx = model.index(i, 0);
            if (!model.data(idx, NotificationManager.Notifications.ReadRole)
                    && !model.data(idx, NotificationManager.Notifications.DismissedRole)) {
                ++unread;
            }
        }
        count = unread;
    }

    readonly property Connections watcher: Connections {
        target: counter.model
        function onRowsInserted() { Qt.callLater(counter.recount); }
        function onRowsRemoved() { Qt.callLater(counter.recount); }
        function onDataChanged() { Qt.callLater(counter.recount); }
        function onModelReset() { Qt.callLater(counter.recount); }
        function onLayoutChanged() { Qt.callLater(counter.recount); }
    }

    Component.onCompleted: recount()
}
