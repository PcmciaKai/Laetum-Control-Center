import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.notificationmanager as NotificationManager

// One notification or file job (copy, download…) in the history, in the same card style as
// the media card. Inside an app's group the app name is left out, since the group shows it.
Rectangle {
    id: card

    // The row's roles, from NotificationManager.Notifications
    required property var model

    readonly property string summary: model.summary ?? ""
    readonly property string body: model.body ?? ""
    readonly property string applicationName: model.applicationName ?? ""
    readonly property string applicationIconName: model.applicationIconName ?? ""
    readonly property string iconName: model.iconName ?? ""
    // A picture the app sent (an avatar, an album cover…), preferred over its icon name
    readonly property var image: model.image ?? null
    readonly property var created: model.created
    readonly property var updated: model.updated
    readonly property var actionNames: model.actionNames ?? []
    readonly property var actionLabels: model.actionLabels ?? []
    readonly property bool hasDefaultAction: model.hasDefaultAction ?? false
    readonly property bool expired: model.expired ?? false
    readonly property bool resident: model.resident ?? false
    readonly property bool configurable: model.configurable ?? false
    readonly property int urgency: model.urgency ?? NotificationManager.Notifications.NormalUrgency
    readonly property var urls: model.urls ?? []
    readonly property bool inGroup: model.isInGroup ?? false

    // ---- Jobs ----
    readonly property bool isJob: (model.type ?? 0) === NotificationManager.Notifications.JobType
    readonly property var job: isJob ? (model.jobDetails ?? null) : null
    readonly property int jobState: model.jobState ?? NotificationManager.Notifications.JobStateStopped
    readonly property bool jobRunning: isJob && jobState !== NotificationManager.Notifications.JobStateStopped
    readonly property int jobError: model.jobError ?? 0
    readonly property int percentage: model.percentage ?? 0

    property date now: new Date()

    signal closeRequested()
    signal defaultActionRequested()
    signal actionRequested(string actionName)
    signal configureRequested()
    signal suspendRequested()
    signal resumeRequested()
    signal killRequested()

    readonly property int pad: Math.round(Kirigami.Units.largeSpacing * 1.5)
    readonly property bool critical: urgency === NotificationManager.Notifications.CriticalUrgency || (isJob && !jobRunning && jobError !== 0)

    // "Just now", "5 min ago", a time today, or a relative date, like the Notifications applet
    readonly property string ageText: {
        if (jobRunning) {
            return "";
        }
        const time = (updated && !isNaN(updated.getTime())) ? updated : created;
        if (!time || isNaN(time.getTime())) {
            return "";
        }
        const minutes = Math.floor((now.getTime() - time.getTime()) / 60000);
        if (minutes < 1) {
            return i18nc("Notification was added less than a minute ago, keep short", "Just now");
        }
        if (minutes < 60) {
            return i18ncp("Notification was added minutes ago, keep short", "%1 min ago", "%1 min ago", minutes);
        }
        if (minutes < 60 * 22) {
            return Qt.formatTime(time, Qt.locale().timeFormat(Locale.ShortFormat).replace(/.ss?/i, ""));
        }
        return KCoreAddons.Format.formatRelativeDate(time, Locale.ShortFormat);
    }

    // What a job is doing: the file it's on, or its error
    readonly property string jobText: {
        if (!job) {
            return "";
        }
        if (!jobRunning && jobError !== 0) {
            return job.errorText || body;
        }
        return job.descriptionValue1 || job.text || body;
    }

    // "45% · 12.3 MiB/s" while it runs
    readonly property string jobProgressText: {
        if (!job) {
            return "";
        }
        if (jobState === NotificationManager.Notifications.JobStateSuspended) {
            return i18nc("Job is paused", "Paused · %1%", percentage);
        }
        const speed = job.speed > 0 ? i18nc("Bytes per second", "%1/s", KCoreAddons.Format.formatByteSize(job.speed)) : "";
        return [i18nc("Job progress", "%1%", percentage), speed].filter(s => s !== "").join(" · ");
    }

    // Where a finished job put its files
    readonly property url jobDestination: job && !jobRunning && jobError === 0 ? (job.effectiveDestUrl ?? "") : ""

    // Attached files: pictures get a thumbnail (e.g. a screenshot), anything else its name
    function isImageUrl(url) {
        return /\.(png|jpe?g|gif|webp|bmp|avif|jxl|svg)$/i.test(String(url));
    }
    function fileName(url) {
        const path = decodeURIComponent(String(url).replace(/\/+$/, ""));
        return path.slice(path.lastIndexOf("/") + 1);
    }

    implicitHeight: content.implicitHeight + pad * 2
    radius: Kirigami.Units.cornerRadius * 1.5
    color: Qt.alpha(Kirigami.Theme.textColor, clickArea.containsMouse ? 0.09 : 0.06)
    border.width: 1
    border.color: critical ? Kirigami.Theme.negativeTextColor : Qt.alpha(Kirigami.Theme.textColor, 0.12)

    Accessible.name: summary
    Accessible.description: isJob ? jobText : body

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.hasDefaultAction && !card.expired
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: card.defaultActionRequested()
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.pad
        spacing: Kirigami.Units.smallSpacing

        // App and time, plus settings and close. Left out when all of it is empty: a running
        // job inside its app's group.
        RowLayout {
            readonly property string caption: [card.inGroup ? "" : card.applicationName, card.ageText].filter(s => s !== "").join(" · ")

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            visible: caption !== "" || card.configurable || !card.jobRunning

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: card.applicationIconName
                visible: !card.inGroup && source !== ""
            }

            PC3.Label {
                Layout.fillWidth: true
                text: parent.caption
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            PC3.ToolButton {
                visible: card.configurable
                icon.name: "configure-symbolic"
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                display: PC3.AbstractButton.IconOnly
                text: i18n("Notification settings")
                onClicked: card.configureRequested()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            // A running job is cancelled with its own button instead
            PC3.ToolButton {
                visible: !card.jobRunning
                icon.name: "window-close-symbolic"
                icon.width: Kirigami.Units.iconSizes.small
                icon.height: Kirigami.Units.iconSizes.small
                display: PC3.AbstractButton.IconOnly
                text: i18n("Close")
                onClicked: card.closeRequested()
                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing / 2

                PC3.Label {
                    Layout.fillWidth: true
                    text: card.summary
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                PC3.Label {
                    Layout.fillWidth: true
                    visible: !card.isJob && text !== ""
                    // The notification server already reduces the body to safe markup
                    text: card.isJob ? "" : card.body
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    opacity: 0.85
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                PC3.Label {
                    Layout.fillWidth: true
                    visible: card.isJob && text !== ""
                    text: card.jobText
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideMiddle
                    color: card.critical ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                    opacity: card.critical ? 1 : 0.85
                }
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                Layout.alignment: Qt.AlignTop
                source: card.image ? card.image : card.iconName
                visible: !!card.image || (card.iconName !== "" && card.iconName !== card.applicationIconName)
            }
        }

        // ---- Job progress ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing / 2
            visible: card.jobRunning

            // In the accent colour, like the sliders
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                implicitHeight: Math.max(4, Math.round(Kirigami.Units.smallSpacing * 1.2))
                radius: height / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                Accessible.role: Accessible.ProgressBar
                Accessible.name: card.jobProgressText

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, card.percentage)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: card.jobState === NotificationManager.Notifications.JobStateSuspended
                        ? Qt.alpha(root.accentColor, 0.5) : root.accentColor
                    Behavior on width {
                        NumberAnimation { duration: Kirigami.Units.longDuration }
                    }
                }
            }
            PC3.Label {
                Layout.fillWidth: true
                text: card.jobProgressText
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        // ---- Attached files ----
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: card.urls.length > 0 && !card.jobRunning

            Repeater {
                model: card.urls.slice(0, 4)

                delegate: PC3.AbstractButton {
                    id: file

                    required property var modelData
                    readonly property bool isImage: card.isImageUrl(modelData)

                    hoverEnabled: true
                    padding: isImage ? 0 : Kirigami.Units.smallSpacing
                    text: card.fileName(modelData)
                    onClicked: {
                        Qt.openUrlExternally(modelData);
                        root.expanded = false;
                    }

                    PC3.ToolTip.text: i18n("Open %1", text)
                    PC3.ToolTip.visible: hovered
                    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay

                    background: Rectangle {
                        radius: Kirigami.Units.cornerRadius
                        color: Qt.alpha(Kirigami.Theme.textColor, file.hovered ? 0.12 : 0.06)
                        border.width: file.visualFocus ? 1 : 0
                        border.color: root.accentColor
                    }

                    contentItem: Item {
                        implicitWidth: file.isImage ? thumbnail.width : fileRow.implicitWidth
                        implicitHeight: file.isImage ? thumbnail.height : fileRow.implicitHeight

                        // The same size as the Clipboard page's thumbnails
                        Image {
                            id: thumbnail
                            visible: file.isImage
                            source: file.isImage ? file.modelData : ""
                            asynchronous: true
                            cache: false
                            smooth: true
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: Kirigami.Units.gridUnit * 4
                            width: Math.min(implicitWidth, content.width)
                            height: implicitWidth > content.width ? implicitHeight * content.width / implicitWidth : implicitHeight
                        }

                        RowLayout {
                            id: fileRow
                            visible: !file.isImage
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                source: "document-open-symbolic"
                            }
                            PC3.Label {
                                Layout.maximumWidth: content.width - Kirigami.Units.iconSizes.small - Kirigami.Units.smallSpacing * 4
                                text: file.text
                                elide: Text.ElideMiddle
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }
            }
        }

        // ---- Buttons: the notification's actions, or the job's controls ----
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            visible: (!card.expired && !card.isJob && card.actionNames.length > 0)
                || (card.jobRunning && ((card.model.suspendable ?? false) || (card.model.killable ?? false)))
                || String(card.jobDestination) !== ""

            Repeater {
                model: card.expired || card.isJob ? [] : card.actionNames

                delegate: PC3.Button {
                    required property string modelData
                    required property int index
                    text: card.actionLabels[index] ?? modelData
                    onClicked: card.actionRequested(modelData)
                }
            }

            PC3.Button {
                visible: card.jobRunning && (card.model.suspendable ?? false)
                readonly property bool paused: card.jobState === NotificationManager.Notifications.JobStateSuspended
                icon.name: paused ? "media-playback-start-symbolic" : "media-playback-pause-symbolic"
                text: paused ? i18nc("Resume a paused job", "Resume") : i18nc("Pause a running job", "Pause")
                onClicked: paused ? card.resumeRequested() : card.suspendRequested()
            }
            PC3.Button {
                visible: card.jobRunning && (card.model.killable ?? false)
                icon.name: "dialog-cancel-symbolic"
                text: i18nc("Cancel a running job", "Cancel")
                onClicked: card.killRequested()
            }
            PC3.Button {
                visible: String(card.jobDestination) !== ""
                icon.name: "document-open-folder-symbolic"
                text: i18nc("Open where a finished job put its files", "Open")
                onClicked: {
                    Qt.openUrlExternally(card.jobDestination);
                    root.expanded = false;
                }
            }
        }
    }
}
