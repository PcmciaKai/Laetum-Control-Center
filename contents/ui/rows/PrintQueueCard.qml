import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.printmanager as PrintManager
import ".."

// Active print jobs, from the same CUPS models as the Printers applet. Only shown while
// something is in the queue.
Rectangle {
    id: card

    readonly property bool available: activeJobs.activeCount > 0

    implicitHeight: content.implicitHeight + pad * 2
    readonly property int pad: Math.round(Kirigami.Units.largeSpacing * 1.5)

    radius: Kirigami.Units.cornerRadius * 1.5
    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

    PrintManager.JobSortFilterModel {
        id: activeJobs
        sourceModel: PrintManager.JobModel {
            id: jobs
        }
    }

    // CUPS doesn't always signal queue changes (the Printers applet works around it the
    // same way): reload while there are jobs
    Timer {
        interval: 10000
        repeat: true
        running: activeJobs.activeCount > 0
        onTriggered: jobs.getJobs()
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                jobs.getJobs();
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: Kirigami.Units.smallSpacing

        PC3.Label {
            text: i18n("Printing")
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Repeater {
            model: activeJobs

            delegate: ListRow {
                id: jobRow
                required property int index
                readonly property var modelIndex: activeJobs.index(index, 0)
                readonly property string jobName: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobName) ?? ""
                readonly property string printer: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobPrinter) ?? ""
                readonly property string stateMessage: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobStateMsg) ?? ""
                readonly property int jobId: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobId) ?? -1
                readonly property bool canCancel: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobCancelEnabled) ?? false

                Layout.fillWidth: true
                leftPadding: Kirigami.Units.smallSpacing
                iconName: activeJobs.data(modelIndex, PrintManager.JobModel.RoleJobIconName) || "document-print-symbolic"
                title: jobName || i18n("Untitled document")
                subtitle: stateMessage !== "" ? i18nc("Print job state on printer", "%1 · %2", stateMessage, printer) : printer
                onClicked: root.openKcm("kcm_printer_manager")

                PC3.ToolButton {
                    icon.name: "dialog-cancel-symbolic"
                    icon.width: Kirigami.Units.iconSizes.small
                    icon.height: Kirigami.Units.iconSizes.small
                    display: PC3.AbstractButton.IconOnly
                    text: i18n("Cancel print job")
                    visible: jobRow.canCancel
                    onClicked: jobs.cancel(jobRow.printer, jobRow.jobId)

                    PC3.ToolTip.text: text
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                }
            }
        }
    }
}
