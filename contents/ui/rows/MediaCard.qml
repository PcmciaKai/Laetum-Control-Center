import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

// Now playing, from the same MPRIS model as the Media Player applet
Rectangle {
    id: card

    readonly property var player: mpris.currentPlayer
    readonly property string track: player?.track ?? ""
    readonly property string artist: player?.artist ?? ""
    readonly property string identity: player?.identity ?? ""
    readonly property string artUrl: player?.artUrl ?? ""
    readonly property bool isPlaying: (player?.playbackStatus ?? 0) === Mpris.PlaybackStatus.Playing
    readonly property double length: player?.length ?? 0
    readonly property double position: player?.position ?? 0
    readonly property bool available: player !== null && track !== ""

    implicitHeight: content.implicitHeight + pad * 2
    readonly property int pad: Math.round(Kirigami.Units.largeSpacing * 1.5)

    radius: Kirigami.Units.cornerRadius * 1.5
    color: Qt.alpha(Kirigami.Theme.textColor, raiseArea.containsMouse ? 0.09 : 0.06)
    border.width: 1
    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.12)

    Mpris.Mpris2Model {
        id: mpris
    }

    // MPRIS doesn't push the position, so poll it while the popup is open
    Timer {
        interval: 1000
        repeat: true
        running: root.expanded && card.isPlaying
        triggeredOnStart: true
        onTriggered: card.player?.updatePosition()
    }

    // Click the card to bring the player's window up
    MouseArea {
        id: raiseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: card.player?.canRaise ?? false
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            card.player.Raise();
            root.expanded = false;
        }
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: card.pad
        spacing: Kirigami.Units.largeSpacing

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
            Layout.preferredHeight: Layout.preferredWidth
            radius: Kirigami.Units.cornerRadius
            color: root.accentColor
            clip: true

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.smallMedium
                height: width
                visible: art.status !== Image.Ready
                source: "media-album-cover"
                fallback: "audio-x-generic"
                color: Kirigami.Theme.highlightedTextColor
                isMask: true
            }

            Image {
                id: art
                anchors.fill: parent
                source: card.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width * Screen.devicePixelRatio
                sourceSize.height: height * Screen.devicePixelRatio
                visible: status === Image.Ready
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PC3.Label {
                Layout.fillWidth: true
                text: card.track
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            PC3.Label {
                Layout.fillWidth: true
                text: [card.artist, card.identity].filter(s => s !== "").join(" · ")
                font: Kirigami.Theme.smallFont
                opacity: 0.7
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }

        PC3.ToolButton {
            icon.name: "media-skip-backward-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: i18n("Previous track")
            enabled: card.player?.canGoPrevious ?? false
            onClicked: card.player.Previous()
        }
        PC3.ToolButton {
            icon.name: card.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: card.isPlaying ? i18n("Pause") : i18n("Play")
            enabled: card.isPlaying ? (card.player?.canPause ?? false) : (card.player?.canPlay ?? false)
            onClicked: card.isPlaying ? card.player.Pause() : card.player.Play()
        }
        PC3.ToolButton {
            icon.name: "media-skip-forward-symbolic"
            display: PC3.AbstractButton.IconOnly
            text: i18n("Next track")
            enabled: card.player?.canGoNext ?? false
            onClicked: card.player.Next()
        }
    }

    // Progress, inset like the accent edge on the search bar
    Rectangle {
        visible: card.length > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: card.radius / 2
        anchors.rightMargin: card.radius / 2
        height: 3
        radius: 1.5
        color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, card.position / card.length))
            height: parent.height
            radius: 1.5
            color: root.accentColor
        }
    }
}
