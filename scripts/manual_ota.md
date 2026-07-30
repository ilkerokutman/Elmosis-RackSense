Since this is a one-off manual deploy directly to the field Pi (per the flow in `AGENTS.md`), here are copy-paste snippets for the VNC session on the Pi. No repo scripts touched.

**1. Stop the running app & back up the current version (for easy rollback)**

Here are the snippets to run **on the Pi** (via the VNC terminal), assuming both zips are downloaded to e.g. `/home/pi/Downloads/`:

### 1. Stop the app & back up the current build (for easy rollback)
```bash
sudo pkill -x rack_sense || true

# keep the currently-running version around in case you need to revert
sudo mv /opt/rack_sense /opt/rack_sense.bak_0.1.0+1
```

### 2. Extract the new build into `/opt/rack_sense`
```bash
sudo mkdir -p /opt/rack_sense
sudo unzip -o /home/pi/Downloads/rack_sense_v0.1.1+2.zip -d /opt/rack_sense
```

### 3. Adjust permissions
```bash
sudo chown -R pi:pi /opt/rack_sense
sudo chmod -R 755 /opt/rack_sense
sudo chmod +x /opt/rack_sense/rack_sense
```

### 4. Run it manually to check
```bash
/opt/rack_sense/rack_sense
```
(or just double-click the existing Desktop shortcut)

### Rollback if you don't like it
```bash
sudo pkill -x rack_sense || true
sudo rm -rf /opt/rack_sense
sudo mv /opt/rack_sense.bak_0.1.0+1 /opt/rack_sense
```
(Keep `rack_sense_v0.1.0+1.zip` around too — you already have it — in case the backed-up folder gets clobbered by a future attempt.)

### 5. Auto-start on boot

This Pi already uses XDG autostart conventions (see `scripts/remove_ccmain_autorun.sh`, which looks at `~/.config/autostart` and LXSession configs) — so the simplest, consistent approach is an autostart `.desktop` entry, same pattern as the existing Desktop shortcut:

```bash
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/rack_sense.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=RackSense
Comment=Elmosis RackSense Controller
Exec=/opt/rack_sense/rack_sense
Path=/opt/rack_sense
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
chmod +x ~/.config/autostart/rack_sense.desktop
```

**Important prerequisite:** this only fires if the Pi boots straight into the `pi` desktop session (auto-login enabled). Check with:
```bash
sudo raspi-config
# System Options -> Boot / Auto Login -> Desktop Autologin
```
If the Pi requires a manual login instead, the autostart entry won't run until someone logs in — in that case a `systemd` user/system service tied to `graphical.target` (with `DISPLAY`/`XAUTHORITY` env vars set) would be needed instead. Let me know if that's the case and I'll give you that variant too.