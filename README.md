# Ubuntu OLED Screensaver

> A zero-dependency, OLED-safe black screensaver for Ubuntu — built for modern Wayland desktops.  
> Keeps your downloads alive, prevents screen burn-in, and restores every setting when you're done.

![License](https://img.shields.io/github/license/simonpanigrahi/Ubuntu-Screensaver?style=flat-square)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%2B-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![Wayland](https://img.shields.io/badge/Wayland-compatible-0076C6?style=flat-square)
![Stars](https://img.shields.io/github/stars/simonpanigrahi/Ubuntu-Screensaver?style=flat-square)

---

## The Problem

Modern Ubuntu laptops (22.04+) run Wayland by default . If you step away while a download, compile, or long script is running, Ubuntu will:

- Lock your screen (requiring a password when you return)
- Dim and blank your display
- Eventually **suspend the system**, killing your background task

On top of that, if you have an OLED display, leaving any static content on screen — even the lock screen — risks **burn-in**. The old `xscreensaver` and `xset` tools don't work on Wayland. There was no simple, lightweight fix. So I built one.

---

## What It Does

| Feature | Detail |
|---|---|
| **Pure black screen** | OLED pixels showing black are physically **OFF** — near-zero power draw and zero burn-in risk |
| **Drifting status text** | The on-screen label shifts every 5 seconds so no pixel stays lit in the same spot |
| **Hidden cursor** | Mouse cursor is invisible — a static cursor on OLED will burn in |
| **Screen lock disabled** | No password prompt when you come back — just exit and you're straight in |
| **Suspend blocked** | Uses `systemd-inhibit` to keep the system alive so downloads don't die |
| **Auto-restore** | Every setting is snapshotted and restored exactly when you exit |
| **Zero dependencies** | Uses only `bash`, `python3-gi` (GTK), and `systemd` — all ship with Ubuntu GNOME |
| **Wayland-native** | No `xset`, no `xscreensaver` — works on modern Ubuntu out of the box |

---

## Demo

> 📸 **Screenshot / GIF coming soon**  
> Want to contribute one? See [Contributing](#contributing).

---

## Requirements

- Ubuntu 22.04 or later (GNOME, Wayland or X11)
- No `apt install` needed — everything is already on your system

---

## Installation

### Install via PPA (Ubuntu / Debian)

The easiest way on Ubuntu. Installs the `screensaver` command and pulls in its dependencies automatically.

```bash
sudo add-apt-repository ppa:simonpanigrahi/screensaver
sudo apt update
sudo apt install oled-screensaver
```

### Install via AUR (Arch Linux)

```bash
# with an AUR helper
yay -S oled-screensaver

# …or manually
git clone https://aur.archlinux.org/oled-screensaver.git
cd oled-screensaver
makepkg -si
```

### Manual install (from source)

Works on any distro that has `bash`, `python3-gi` (GTK 3) and `systemd`:

```bash
git clone https://github.com/simonpanigrahi/Ubuntu-Screensaver.git
cd Ubuntu-Screensaver
sudo make install        # installs to /usr/local/bin/screensaver
```

Uninstall any time with `sudo make uninstall`.

---

## Usage

Run it from anywhere:

```bash
screensaver
```

**Exit when you're back**

Press **`ESC`** or **click anywhere** on the black screen.  
All your original settings are restored automatically.

---

## How It Works

```
screensaver
│
├── Snapshots current GNOME power/lock settings via gsettings
├── Disables: idle timeout · screensaver · screen lock · screen dimming · sleep timeouts
├── Runs: systemd-inhibit sleep infinity (blocks system suspend)
│
├── Opens fullscreen pure-black GTK window
│   ├── Status label drifts ±25px every 5 seconds (burn-in prevention)
│   └── Mouse cursor hidden (Gdk blank cursor)
│
└── On ESC / click / Ctrl+C
    └── Restores all saved settings exactly as they were
```

The key insight for OLED: a black pixel on an OLED panel is a pixel that is **physically switched off**. Showing a pure black screen uses effectively the same power as having the screen off, without triggering the lock screen that would require a password on resume.

---

## Why Not Just Turn the Screen Off?

Turning the screen off via DPMS on Wayland will still trigger the lock screen on resume. You'd need to enter your password — defeating the purpose. This script keeps the screen on (but showing black), so you return to an unlocked desktop instantly.

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Ideas for future improvements:

- `--timeout` flag to auto-exit after N minutes
- Configurable drift speed and label text
- System tray indicator
- `.desktop` file for GUI launch

---

## License

MIT — see [LICENSE](LICENSE).

---

## Author

**Simon Kenny Panigrahi**  
B.Tech Information Technology, VSSUT Burla  
[GitHub](https://github.com/simonpanigrahi) · [LinkedIn](https://linkedin.com/in/simonkp)

> Built because I needed it. Scratching your own itch is still the best reason to build something.
