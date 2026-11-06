import QtQuick
import org.kde.plasma.plasmoid
import ".."

// Click to pick a colour from the screen (copied as hex); › shows the picked colours
Tile {
    id: tile

    readonly property string lastColor: Plasmoid.configuration.colorHistory.length > 0 ? Plasmoid.configuration.colorHistory[0] : ""

    iconName: "color-picker-symbolic"
    label: i18n("Color Picker")
    status: lastColor !== "" ? lastColor : i18n("Pick a color")
    hasDetails: true
    detailsTooltip: i18n("Picked colors")

    onActivated: root.pickColor()
    onDetailsRequested: root.pageRequested("colors")
}
