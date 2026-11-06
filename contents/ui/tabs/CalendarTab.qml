import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.workspace.calendar as PlasmaCalendar

// Month view from Plasma's own calendar component (the one the Digital Clock uses)
Item {
    id: calendarTab

    // Set by the panel while this tab is showing
    property bool current: false

    onCurrentChanged: {
        if (current) {
            monthView.today = new Date();
            monthView.resetToToday();
        }
    }

    // Keep "today" right if the popup stays open over midnight
    Timer {
        interval: 60000
        repeat: true
        running: calendarTab.current && root.expanded
        onTriggered: {
            const now = new Date();
            if (now.getDate() !== monthView.today.getDate()) {
                monthView.today = now;
            }
        }
    }

    PlasmaCalendar.MonthView {
        id: monthView
        anchors.fill: parent

        borderOpacity: 0.25
        today: new Date()
        firstDayOfWeek: Qt.locale().firstDayOfWeek
        showWeekNumbers: false
    }
}
