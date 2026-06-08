#!/bin/bash
# ============================================================
# oled-safe.sh  v5
# OLED-safe black screensaver for Ubuntu (Wayland + X11)
#
# - Pure black screen  →  OLED pixels off = near-zero power
# - Status text drifts every 5s  →  prevents burn-in
# - Mouse cursor hidden  →  no static pixel on OLED
# - Screen lock + screensaver disabled while active
# - System suspend blocked  →  download keeps running
# - All settings auto-restored when you exit
#
# Usage : bash oled-safe.sh
# Exit  : press ESC  or  click anywhere on the black screen
# ============================================================

# ── Guard: must be run inside a graphical session ─────────
# $DISPLAY is set under X11; $WAYLAND_DISPLAY under Wayland.
# If neither exists, we're in a headless/SSH session — bail out.
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
  echo "❌  No display found. Run this from a graphical terminal, not SSH."
  exit 1
fi

# ── Step 1: Snapshot current GNOME power/lock settings ────
# Save everything before changing it so cleanup() can
# restore the exact original values later.
echo "💾  Saving current settings..."

IDLE_DELAY=$(gsettings get org.gnome.desktop.session idle-delay                                   2>/dev/null || echo "uint32 300")
SS_ACTIVE=$(gsettings get org.gnome.screensaver idle-activation-enabled                           2>/dev/null || echo "true")
LOCK_ON=$(gsettings get org.gnome.screensaver lock-enabled                                        2>/dev/null || echo "true")
IDLE_DIM=$(gsettings get org.gnome.settings-daemon.plugins.power idle-dim                        2>/dev/null || echo "true")
SLEEP_AC=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout       2>/dev/null || echo "900")
SLEEP_BAT=$(gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 2>/dev/null || echo "300")

# ── Step 2: Disable screen lock, screensaver, and dimming ─
echo "🔓  Disabling screen lock..."

gsettings set org.gnome.desktop.session idle-delay 0                                           2>/dev/null
gsettings set org.gnome.screensaver idle-activation-enabled false                              2>/dev/null
gsettings set org.gnome.screensaver lock-enabled false                                         2>/dev/null
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false                          2>/dev/null
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0             2>/dev/null
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0        2>/dev/null

# ── Step 3: Block system suspend at the systemd level ─────
# Holds a sleep:idle lock while "sleep infinity" runs in the
# background. Prevents battery idle-suspend killing the download.
echo "⚡  Inhibiting suspend..."

systemd-inhibit \
  --what=sleep:idle \
  --who="oled-safe" \
  --why="Download in progress" \
  --mode=block \
  sleep infinity &
INHIBIT_PID=$!  # save PID so cleanup can kill it

# ── Step 4: Cleanup — runs automatically on any exit ──────
cleanup() {
  echo ""
  echo "🔄  Restoring settings..."
  gsettings set org.gnome.desktop.session idle-delay "$IDLE_DELAY"                                    2>/dev/null
  gsettings set org.gnome.screensaver idle-activation-enabled "$SS_ACTIVE"                             2>/dev/null
  gsettings set org.gnome.screensaver lock-enabled "$LOCK_ON"                                          2>/dev/null
  gsettings set org.gnome.settings-daemon.plugins.power idle-dim "$IDLE_DIM"                          2>/dev/null
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout "$SLEEP_AC"         2>/dev/null
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout "$SLEEP_BAT"   2>/dev/null
  kill "$INHIBIT_PID" 2>/dev/null  # release the suspend inhibitor
  echo "✅  All settings restored. Download should still be running."
}
trap cleanup EXIT INT TERM

echo "🖤  Black screen active — press ESC or click to exit"
echo ""

# ── Step 5: Launch the black fullscreen window ────────────
# GTK via python3-gi ships with every Ubuntu GNOME install.
python3 - <<'PY'
import gi, random
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib

# ── Window setup ──────────────────────────────────────────
win = Gtk.Window()
win.fullscreen()  # cover the whole screen

# Pure black background. On OLED, black pixels are physically OFF.
# Label colour green: readable up close, no bright burn risk.
css = b"""
window { background-color: black; }
label  { color: green; font-family: monospace; font-size: 11pt; }
"""
provider = Gtk.CssProvider()
provider.load_from_data(css)
win.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

# ── Layout ────────────────────────────────────────────────
# Gtk.Fixed allows absolute x/y placement so we can drift the label.
fixed = Gtk.Fixed()
win.add(fixed)

# The status text — tells you what's running and how to close.
lbl = Gtk.Label(
    label="Screensaver on - Press ESC or click anywhere to close"
)
lbl.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

# put() adds AND positions in one call. Start at (100,100) so the
# label is ALWAYS on-screen immediately, even before any timer fires.
fixed.put(lbl, 100, 100)

# Tracks the label's current position for incremental drift.
pos = [100, 100]

def screen_size():
    """
    Return the true screen size using the WINDOW's own allocation.
    In fullscreen this equals the screen dimensions, and unlike the
    old Gdk.Screen.get_width() it is RELIABLE on Wayland.
    Returns (1, 1) until the window has actually been allocated.
    """
    return win.get_allocated_width(), win.get_allocated_height()

def place_initial():
    """
    Centre the label horizontally, near the bottom, once the window
    has a real size. Retries every tick until allocation is ready,
    then stops (returns False).
    """
    sw, sh = screen_size()
    if sw <= 1 or sh <= 1:
        return True  # window not sized yet — try again next tick

    lw = lbl.get_allocated_width()
    lh = lbl.get_allocated_height()
    pos[0] = (sw - lw) // 2  # horizontally centred
    pos[1] = sh - 90         # near the bottom
    fixed.move(lbl, pos[0], pos[1])
    return False  # done — don't repeat

def move_label():
    """
    Drift the label by a small random offset (±25px each axis)
    every 5 seconds, clamped to stay 40px inside the screen edges.
    Returning True keeps the GLib timer repeating.
    """
    sw, sh = screen_size()
    if sw <= 1 or sh <= 1:
        return True  # not ready yet

    lw = lbl.get_allocated_width()
    lh = lbl.get_allocated_height()
    margin = 40
    dx = random.randint(-25, 25)
    dy = random.randint(-25, 25)

    pos[0] = max(margin, min(sw - lw - margin, pos[0] + dx))
    pos[1] = max(margin, min(sh - lh - margin, pos[1] + dy))
    fixed.move(lbl, pos[0], pos[1])
    return True

def on_realize(widget):
    """Hide the mouse cursor once the window exists (static cursor burns in)."""
    try:
        blank = Gdk.Cursor.new_from_name(win.get_display(), "none")
        if blank is None:
            raise Exception("cursor 'none' unavailable")
    except Exception:
        blank = Gdk.Cursor.new_for_display(win.get_display(), Gdk.CursorType.BLANK_CURSOR)
    win.get_window().set_cursor(blank)

win.connect('realize', on_realize)

# Timers: centre the label as soon as size is known, then drift every 5s.
GLib.timeout_add(100, place_initial)
GLib.timeout_add(5000, move_label)

# ── Exit handlers ─────────────────────────────────────────
def on_key(w, event):
    if event.keyval == Gdk.KEY_Escape:  # ESC closes
        Gtk.main_quit()

win.connect('destroy',            Gtk.main_quit)
win.connect('key-press-event',    on_key)
win.connect('button-press-event', lambda *a: Gtk.main_quit())  # click closes

win.show_all()
Gtk.main()  # blocks until the window closes
PY
# python3 exits here → bash EXIT trap fires → cleanup() restores settings.
