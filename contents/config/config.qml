import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Custom Tiles")
        icon: "system-run"
        source: "ConfigCustom.qml"
    }
}
