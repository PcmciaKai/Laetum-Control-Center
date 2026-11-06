import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

// System Settings search results (KRunner's settings plugin), styled like Laetum Launcher's lists
ListView {
    id: list

    property bool keyboardNav: false
    readonly property int scrollBarSpace: vbar.size < 1 ? vbar.width + Kirigami.Units.smallSpacing : 0

    model: root.runnerModel.count > 0 ? root.runnerModel.modelForRow(0) : null
    clip: true
    currentIndex: -1
    boundsBehavior: Flickable.StopAtBounds
    keyNavigationEnabled: false
    spacing: 2

    PC3.ScrollBar.vertical: PC3.ScrollBar {
        id: vbar
    }

    Kirigami.WheelHandler {
        target: list
        filterMouseEvents: true
        keyNavigationEnabled: false
    }

    function reset() {
        currentIndex = -1;
        keyboardNav = false;
        positionViewAtBeginning();
    }

    function launch(row) {
        if (model && row >= 0 && row < count) {
            model.trigger(row, "", null);
            root.expanded = false;
        }
    }

    // Enter opens the selected result, or the first one when nothing is selected
    function activate() {
        launch(currentIndex >= 0 ? currentIndex : 0);
    }

    function moveKey(key) {
        if (count === 0) {
            return;
        }
        keyboardNav = true;
        if (key === Qt.Key_Down) {
            currentIndex = Math.min(count - 1, currentIndex + 1);
        } else if (key === Qt.Key_Up) {
            currentIndex = Math.max(0, currentIndex - 1);
        }
        positionViewAtIndex(currentIndex, ListView.Contain);
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: list.count === 0 && !root.runnerModel.querying
        iconName: "edit-find-symbolic"
        text: i18n("No settings match “%1”", root.searchText)
    }

    delegate: MouseArea {
        id: row

        required property int index
        required property var model
        readonly property bool highlighted: containsMouse || (list.keyboardNav && ListView.isCurrentItem)

        width: list.width - list.scrollBarSpace
        height: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        hoverEnabled: true

        onEntered: {
            list.keyboardNav = false;
            list.currentIndex = index;
        }
        onExited: {
            if (!list.keyboardNav && list.currentIndex === index) {
                list.currentIndex = -1;
            }
        }
        onClicked: list.launch(index)

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius * 2
            color: Kirigami.Theme.textColor
            opacity: row.highlighted ? (row.pressed ? 0.12 : 0.07) : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
        }

        RowLayout {
            id: content
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Kirigami.Units.largeSpacing
            anchors.rightMargin: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                source: row.model.decoration
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PC3.Label {
                    Layout.fillWidth: true
                    text: row.model.display ?? ""
                    elide: Text.ElideRight
                }
                PC3.Label {
                    Layout.fillWidth: true
                    visible: text !== "" && text !== row.model.display
                    text: row.model.description ?? ""
                    elide: Text.ElideRight
                    opacity: 0.65
                    font: Kirigami.Theme.smallFont
                }
            }
        }
    }
}
