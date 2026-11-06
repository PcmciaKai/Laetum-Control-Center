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
- [ ] Hiding all three indicators in the settings shows the panel icon instead

## Header

- [ ] Laptop: charge ring and time left; desktop: day ring, time and date
- [ ] Pencil opens the settings, the sliders button opens System Settings, Power opens the session menu

## Controls tab

- [ ] Every tile toggles the real setting, and the matching tray applet shows the same state
- [ ] Wi-Fi off in airplane mode: the tile can't be toggled but its › still works
- [ ] Do Not Disturb toggles and shows Plasma's OSD
- [ ] Power profile opens a menu with the available profiles
- [ ] Tiles for missing hardware are hidden
- [ ] Volume slider, mute button and the number stay in sync with the tray's volume
- [ ] Brightness slider appears on a laptop or with a DDC/CI monitor
- [ ] Media card appears while something plays; buttons and progress work; clicking the card raises the player

## Notifications tab

- [ ] Hidden when Plasma's Notifications applet isn't in use
- [ ] Badge counts unread notifications and clears when the tab is opened
- [ ] Cards show app, time, summary, body and action buttons; actions work
- [ ] Close and Clear all also remove the notifications from the tray's history
- [ ] Do Not Disturb switch follows the tile and the tray

## Calendar tab

- [ ] Shows the current month with today highlighted; arrows change the month

## Pages

- [ ] Wi-Fi ›: list of networks, connected one tinted; Disconnect works; a saved network connects; a new WPA network asks for the password inline; Esc in the field cancels
- [ ] Bluetooth ›: paired devices; clicking connects/disconnects; Pair device… opens the wizard
- [ ] Microphone › and volume ›: Sound page; clicking a device makes it the default
- [ ] The switch in a page's header turns Wi-Fi / Bluetooth on and off
- [ ] Back and Esc return to the tabs; the popup keeps the same height

## Search

- [ ] Typing shows System Settings matches; arrows and Enter work; Esc clears, then closes

## Settings

- [ ] Tiles can be hidden and reordered
- [ ] Each "Show" and "Tabs" checkbox hides its part
