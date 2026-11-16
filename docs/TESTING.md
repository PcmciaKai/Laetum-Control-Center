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

- [ ] Laptop: percentage inside the ring, plugged in/charging state and time left next to it; desktop: no ring, just the buttons on the right
- [ ] Header shows CPU: CPU usage in the ring, "RAM x of y" below; GPU: GPU usage, "VRAM x of y" with the card's own total (not the RAM's); switching between them while the popup is open updates right away; Nothing: just the buttons
- [ ] Header height Thin: about half the height; the ring, both lines of text (also "Plugged in, not charging" with "100%") and the buttons fit, also with Large buttons and on a page (Back, title, status, switch)
- [ ] Header buttons: Default and Large; a setting saved as the old Small shows as Default
- [ ] About page: the website links to GitHub, "Report an issue" to the GitHub issues
- [ ] The sliders button opens System Settings, Power opens the session menu

## Controls tab

- [ ] Every tile toggles the real setting, and the matching tray applet shows the same state
- [ ] Wi-Fi off in airplane mode: the tile can't be toggled but its › still works
- [ ] Do Not Disturb toggles and shows Plasma's OSD
- [ ] Power Mode opens a menu with the available profiles
- [ ] Tile labels fit on one line, and the › arrows line up with the tile icons
- [ ] Dark Mode switches light ↔ dark and back to the original scheme or theme
- [ ] Clipboard shows the item count; its page lists the history, clicking an entry copies it, Clear history empties it
- [ ] KDE Connect tile shows the phone's name and battery (when the phone sends it); its page: battery, ring / browse / send files / send clipboard work, files dropped on a device are sent; the remote keyboard field appears while the phone asks for it; phone notifications can be dismissed and replied to
- [ ] Screenshot: click closes the popup and starts Spectacle's region selection; › menu modes work
- [ ] Night Light: click pauses and resumes; › page: Pause for an hour / until tomorrow morning show the time on the tile and resume by themselves, Resume now works, the temperature slider shows the colour while dragging and is kept after release, the header switch turns Night Light off and on
- [ ] VPN: without VPNs the tile says Not set up and › shows Add a VPN…; with one VPN a click connects and disconnects it; with several, › lists them and clicking one toggles it; with a VPN that only carries IPv4 on a network with IPv6, the page shows the IPv6 warning
- [ ] Custom tiles: without commands they say Not set up and a click opens the settings; with ON and OFF commands a click runs them and the tile shows On / Off; with a status command the tile follows it (also after changing the state outside); with only an ON command the tile is a button
- [ ] Hotspot: tile starts and stops it; › page shows name and password, switch works, fields are locked while it runs; hidden without a capable Wi-Fi card
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
- [ ] Several notifications from one app are grouped under the app's name; Show more / Show fewer and the group's close button work
- [ ] A file copy shows a progress bar with percentage and speed; Pause / Resume and Cancel work; when done, Open shows the destination
- [ ] A notification with an attached picture (e.g. a saved screenshot) shows a thumbnail; clicking it opens the picture
- [ ] Do Not Disturb switch follows the tile and the tray

## Pages

- [ ] Wi-Fi ›: list of networks, connected one tinted; Disconnect works; a saved network connects; a new WPA network asks for the password inline; Esc in the field cancels
- [ ] Bluetooth ›: paired devices; clicking connects/disconnects; Pair device… opens the wizard
- [ ] Microphone › and volume ›: Sound page; clicking a device makes it the default; apps playing sound are listed under Apps (with a note when none is playing) with their own slider, and clicking an app's icon mutes it
- [ ] The switch in a page's header turns Wi-Fi / Bluetooth on and off
- [ ] Pages slide in from the right and back out; Back and Esc return to the tabs; the popup keeps the same height

## Settings

- [ ] Tiles can be hidden and reordered
- [ ] Each "Show" and "Tabs" checkbox hides its part
