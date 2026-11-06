import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

// Slider with the accent-coloured fill from the design, independent of the Plasma style
T.Slider {
    id: control

    readonly property color accent: root.accentColor

    implicitWidth: Kirigami.Units.gridUnit * 10
    implicitHeight: Kirigami.Units.gridUnit * 1.5
    hoverEnabled: true
    wheelEnabled: true

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: Qt.alpha(Kirigami.Theme.textColor, 0.18)

        Rectangle {
            x: control.mirrored ? parent.width - width : 0
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 2
            color: control.accent
        }
    }

    handle: Rectangle {
        Kirigami.Theme.colorSet: Kirigami.Theme.Button
        Kirigami.Theme.inherit: false

        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: Kirigami.Units.gridUnit
        height: width
        radius: width / 2
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: control.hovered || control.pressed || control.visualFocus ? control.accent : Qt.alpha(Kirigami.Theme.textColor, 0.25)
    }
}
