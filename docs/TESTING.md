# Testing checklist

There's no automated test for a plasmoid, so this is the list to walk through after a change. Install with `kpackagetool6 -t Plasma/Applet -u .` (or `-i` the first time), then run `plasmashell --replace &` so Plasma drops its cached QML.

Keep a log open while testing; anything wrong in the QML shows up here:

```bash
journalctl --user -f | grep -i -E "laetum|qml"
```

Quicker, without touching your panel:

```bash
plasmoidviewer -a local.laetum.controlcenter -l bottomedge -f horizontal
```

## Panel button

- [ ] Network, volume and battery icons show (battery only on a laptop)
- [ ] Scrolling on the button changes the volume
- [ ] A bell appears while there are unread notifications and goes away after opening the Notifications tab; it is crossed out during Do Not Disturb
- [ ] Hiding all indicators in the settings shows the panel icon instead

## Header

- [ ] Laptop: charge ring and time left; desktop: day ring, time and date
- [ ] Pencil opens the settings, the sliders button opens System Settings, Power opens the session menu

## Controls tab

- [ ] Every tile toggles the real setting, and the matching tray applet shows the same state
- [ ] Wi-Fi off in airplane mode: the tile can't be toggled but its › still works
- [ ] Do Not Disturb toggles and shows Plasma's OSD
- [ ] Power Mode opens a menu with the available profiles
- [ ] Tile labels fit on one line, and the › arrows line up with the tile icons
- [ ] Dark Mode switches light ↔ dark and back to the original scheme or theme
- [ ] Clipboard shows the item count; its page lists the history, clicking an entry copies it, Clear history empties it
- [ ] Color Picker: clicking closes the popup and shows KWin's picker; the hex code is copied and appears on the tile and in the › page; Esc cancels
- [ ] Tiles for missing hardware are hidden
- [ ] Volume slider, mute button and the number stay in sync with the tray's volume
- [ ] Brightness slider appears on a laptop or with a DDC/CI monitor
- [ ] Media card appears while something plays; buttons and progress work; clicking the card raises the player
- [ ] Removable devices card appears with a USB stick plugged in; clicking opens it (mounting first); eject unmounts and powers it off, or says it's in use
- [ ] Print queue card appears while printing; cancel removes the job

## Notifications tab

- [ ] Hidden when Plasma's Notifications applet isn't in use
- [ ] Badge counts unread notifications and clears when the tab is opened
- [ ] Cards show app, time, summary, body and action buttons; actions work
- [ ] Close and Clear all also remove the notifications from the tray's history
- [ ] Do Not Disturb switch follows the tile and the tray

## Pages

- [ ] Wi-Fi ›: list of networks, connected one tinted; Disconnect works; a saved network connects; a new WPA network asks for the password inline; Esc in the field cancels
- [ ] Bluetooth ›: paired devices; clicking connects/disconnects; Pair device… opens the wizard
- [ ] Microphone › and volume ›: Sound page; clicking a device makes it the default
- [ ] The switch in a page's header turns Wi-Fi / Bluetooth on and off
- [ ] Back and Esc return to the tabs; the popup keeps the same height

## Settings

- [ ] Tiles can be hidden and reordered
- [ ] Each "Show" and "Tabs" checkbox hides its part
