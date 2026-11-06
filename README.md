# Laetum Control Center

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-KDE%20Plasma%206-1D99F3?logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)

A quick-settings popup for KDE Plasma 6, designed as a companion to [Laetum Launcher](https://github.com/PcmciaKai/Laetum-Launcher). It has the same opaque header over a translucent body, the same accent bars and search bar, and quick-toggle tiles in the spirit of the Windows 11 quick settings.

It talks to the same Plasma components as the built-in system tray applets (Networks, Bluetooth, Audio Volume, Brightness and Color, Power and Battery, Notifications, Media Player), so toggling something here is the same as toggling it there.

> **Status: 0.2.0, early version.** Controls, Notifications and Calendar tabs and the Wi-Fi, Bluetooth and Sound pages are in. An in-popup edit mode is next (see [Roadmap](#roadmap)).

## Features

- **Three tabs** with Laetum Launcher's sliding accent indicator: **Controls**, **Notifications** (with an unread badge) and **Calendar**
- **Quick-toggle tiles:** Wi-Fi, Bluetooth, Night Light, Do Not Disturb, Airplane mode, Power profile, Microphone, KDE Connect and Keep awake
  - Click a tile to toggle it; the › button opens more options
  - Wi-Fi, Bluetooth and Microphone (and the volume slider's ›) slide in a page inside the popup: pick and connect to Wi-Fi networks (with an inline password field), connect paired Bluetooth devices or pair a new one, choose the default sound output and input
  - The other tiles' › opens the matching System Settings page
  - Tiles for hardware you don't have (e.g. Wi-Fi on a desktop) hide themselves
  - Choose which tiles appear and their order in the settings
- **Volume and brightness sliders**, one brightness slider per display that supports it (laptop panels and DDC/CI monitors)
- **Notifications tab:** your notification history as cards, with their action buttons, Close, notification settings, Do Not Disturb and Clear all. It uses the same history as Plasma's Notifications applet, so reading or closing a notification here does the same there
- **Calendar tab:** Plasma's own month view (the one the Digital Clock uses)
- **Now playing card** for the current MPRIS player, with previous / play-pause / next and a progress bar; click it to raise the player
- **Header** with a battery charge ring and time remaining (laptops) or today's date (desktops), plus Edit tiles, System Settings and Power (lock, sleep, hibernate, restart, shut down, switch user, log out)
- **Settings search:** type to search System Settings pages, Enter opens the first match
- **Keyboard:** type to search, Ctrl+Tab to switch tabs, Esc to go back from a page or close
- **Panel indicators:** network, volume and battery icons; scroll on them to change the volume
- Uses your **colour scheme's accent colour**, like Laetum Launcher

## Requirements

- KDE Plasma 6 (written against the Plasma 6.7 sources)

Each tile and row loads on its own, so a missing component only hides that part:

| Part | Comes from |
| --- | --- |
| Wi-Fi, Airplane mode, network indicator | `plasma-nm` |
| Bluetooth | `bluedevil` |
| Volume, Microphone | `plasma-pa` |
| Brightness, Night Light, Power profile, Keep awake | `powerdevil` (Power profiles also need `power-profiles-daemon` or `tuned-ppd`) |
| Battery | `plasma-workspace` |
| Do Not Disturb, Notifications tab | Plasma's Notifications applet (the one in the system tray) |
| Calendar tab | `plasma-workspace` |
| KDE Connect | `kdeconnect` |

## Install

Download `laetum-control-center-<version>.plasmoid` from the [Releases](../../releases) page, then:

```bash
kpackagetool6 -t Plasma/Applet -i laetum-control-center-0.2.0.plasmoid
```

Or from a checkout of this repository:

```bash
kpackagetool6 -t Plasma/Applet -i .
```

To update an existing install, use `-u` instead of `-i`. Plasma caches QML, so after updating run `plasmashell --replace &` (or log out and back in) if you don't see your changes.

Then right-click the panel → **Add Widgets…** → **Laetum Control Center**. It works well next to (or instead of) the system tray; you can hide the tray entries it replaces in the tray's own settings.

To try it in a window without touching your panel:

```bash
plasmoidviewer -a local.laetum.controlcenter -l bottomedge -f horizontal
```

## Settings

Right-click the icon → **Configure Laetum Control Center…** (or the pencil button in the popup's header).

| Setting | What it does |
| --- | --- |
| Panel icon | Shown when all panel indicators are hidden or unavailable |
| Panel indicators | Show or hide the network, volume and battery icons on the panel |
| Tiles | Which tiles appear, and their order |
| Show | Volume and brightness sliders, media player, settings search bar |
| Tabs | Show or hide the Notifications and Calendar tabs |
| Header buttons | Small, Medium (default) or Large |
| Animations | Squeeze tiles when clicked |

## Troubleshooting

If a tile or the whole widget is missing, the reason is usually in the log:

```bash
journalctl --user -f | grep -i -E "laetum|qml"
```

This widget uses some of Plasma's **private** QML modules (the same ones the tray applets use, just as Laetum Launcher uses Kickoff's). They have no stability promise, so a Plasma update can occasionally break a tile until it is adjusted. Please open an issue with the log line if that happens.

## Roadmap

- **Edit mode** in the popup: remove, add and drag tiles
- Notifications: group by app, job progress (file copies), screenshot thumbnails
- Calendar: events and holidays from the Digital Clock's calendar plugins
- KDE Connect: phone battery on the tile
- Slide animation when opening and closing pages

## AI Disclosure

The majority of this project's source code was written with the help of AI tools. Because the code is largely AI-generated, it builds on the collective work of countless developers who share their knowledge openly — and it should give back in the same way. For this reason, this project is and must always remain open source.

## License

Laetum Control Center is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version (GPL-3.0-or-later). See [LICENSE](LICENSE).
