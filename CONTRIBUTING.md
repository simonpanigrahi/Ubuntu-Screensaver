# Contributing to Ubuntu OLED Screensaver

Thanks for taking the time to contribute. This is a small, focused utility — contributions that keep it simple and dependency-free are most welcome.

---

## Ways to Contribute

### Report a Bug

Open an issue using the **Bug Report** template. Include:
- Your Ubuntu version (`lsb_release -a`)
- Whether you're on Wayland or X11 (`echo $XDG_SESSION_TYPE`)
- The exact error output from the terminal

### Suggest a Feature

Open an issue using the **Feature Request** template. Keep in mind the project goals: zero extra dependencies, works out of the box on Ubuntu GNOME.

### Submit a Pull Request

1. Fork the repo and create a branch: `git checkout -b feature/your-feature`
2. Make your changes to `oled-safe.sh`
3. Test on Ubuntu (Wayland preferred, X11 also)
4. Verify settings are fully restored after exit
5. Open a PR with a clear description of what changed and why

### Add a Demo Screenshot or GIF

The README currently has no screenshot. A clean GIF showing the script running, the black screen appearing, and the exit is genuinely useful. Tools you can use:

```bash
# Install peek (screen recorder → GIF)
sudo apt install peek

# Or use byzanz
sudo apt install byzanz
byzanz-record --duration=10 --x=0 --y=0 --width=1920 --height=1080 demo.gif
```

Open a PR adding the GIF to a `/assets` folder and update the README `Demo` section.

---

## Code Style

- Bash: comments on every non-obvious line, `2>/dev/null` on all `gsettings` calls
- Python: Google-style docstrings on every function
- No new `apt` dependencies — if it doesn't ship with Ubuntu GNOME, it doesn't belong here

---

## Testing Checklist

Before submitting a PR, confirm:

- [ ] Script runs without errors on Ubuntu 22.04+ (Wayland)
- [ ] Black screen appears fullscreen
- [ ] Status text is visible (dim but readable up close)
- [ ] Text drifts after 5 seconds
- [ ] Mouse cursor is hidden
- [ ] ESC closes the window
- [ ] Click closes the window
- [ ] All gsettings values are restored correctly after exit
- [ ] `systemd-inhibit` process is cleaned up after exit
