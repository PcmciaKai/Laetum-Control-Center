import QtQuick
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

PC3.ToolButton {
    id: button

    property string iconName
    property string tooltip
    property int iconSize: Kirigami.Units.iconSizes.smallMedium
    // The thin header: less room above and below the icon
    property bool thin: false

    icon.name: iconName
    icon.width: iconSize
    icon.height: iconSize
    display: PC3.AbstractButton.IconOnly
    text: tooltip
    flat: true
    topPadding: thin ? Math.round(Kirigami.Units.smallSpacing / 2) : undefined
    bottomPadding: thin ? Math.round(Kirigami.Units.smallSpacing / 2) : undefined

    PC3.ToolTip.text: tooltip
    PC3.ToolTip.visible: hovered
    PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
}
