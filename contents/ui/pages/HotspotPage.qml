import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.networkmanagement as PlasmaNM
import ".."

// Hotspot name and password (plasma-nm's settings, shared with the Networks applet), with the
// on/off switch in the header
ColumnLayout {
    id: page

    // ---- Page contract (read by the panel's header) ----
    readonly property string title: i18n("Hotspot")
    readonly property string subtitle: hotspot.active ? i18n("On · %1", hotspot.ssid)
        : (hotspot.airplane ? i18n("Airplane mode is on") : (hotspot.starting ? i18n("Starting…") : i18n("Off")))
    readonly property bool hasSwitch: true
    readonly property bool switchChecked: hotspot.active
    readonly property bool switchEnabled: !hotspot.airplane && passwordField.acceptableInput
    readonly property bool available: hotspot.supported
    function toggleSwitch() {
        save();
        hotspot.toggle();
    }

    // The fields apply on the next start; save what's typed before starting
    function save() {
        if (nameField.text.trim() !== "") {
            PlasmaNM.Configuration.hotspotName = nameField.text.trim();
        }
        if (passwordField.acceptableInput) {
            PlasmaNM.Configuration.hotspotPassword = passwordField.text;
        }
    }

    spacing: Kirigami.Units.largeSpacing

    HotspotControl {
        id: hotspot
    }

    // Before the first start there's no password yet: offer one, so the fields aren't empty
    Component.onCompleted: {
        if (PlasmaNM.Configuration.hotspotPassword.length < hotspot.minimumPasswordLength) {
            PlasmaNM.Configuration.hotspotPassword = hotspot.randomPassword();
        }
        nameField.text = PlasmaNM.Configuration.hotspotName;
        passwordField.text = PlasmaNM.Configuration.hotspotPassword;
    }

    PC3.Label {
        Layout.leftMargin: Kirigami.Units.smallSpacing
        text: i18n("Network name")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }
    PC3.TextField {
        id: nameField
        Layout.fillWidth: true
        enabled: !hotspot.active
        maximumLength: 32
        onEditingFinished: page.save()
    }

    PC3.Label {
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.topMargin: Kirigami.Units.smallSpacing
        text: i18n("Password")
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PC3.TextField {
            id: passwordField
            Layout.fillWidth: true
            enabled: !hotspot.active
            echoMode: showButton.checked ? TextInput.Normal : TextInput.Password
            maximumLength: 63
            // WPA2: 8 to 63 printable ASCII characters
            validator: RegularExpressionValidator {
                regularExpression: /[\x20-\x7e]{8,63}/
            }
            onEditingFinished: page.save()
        }
        PC3.ToolButton {
            id: showButton
            checkable: true
            icon.name: checked ? "view-hidden-symbolic" : "view-visible-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: checked ? i18n("Hide password") : i18n("Show password")
            PC3.ToolTip.text: text
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
        PC3.ToolButton {
            icon.name: "edit-copy-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: i18n("Copy password")
            onClicked: root.copyText(passwordField.text)
            PC3.ToolTip.text: text
            PC3.ToolTip.visible: hovered
            PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }

    PC3.Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        text: hotspot.active
            ? i18n("Turn the hotspot off to change the name or password.")
            : (passwordField.acceptableInput
                ? i18n("Most Wi-Fi cards can't be connected to a network and be a hotspot at the same time, so starting it may disconnect this computer from Wi-Fi.")
                : i18n("The password needs at least 8 characters."))
    }

    Item {
        Layout.fillHeight: true
    }
}
