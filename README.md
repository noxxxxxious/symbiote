# Symbiote (faishell)

A Hyprland desktop shell built with Quickshell and Qt Quick, with an animated border, clock, system tray, application launcher, settings, notifications, workspaces, and a dashboard for system information, audio, Bluetooth, and Wi-Fi.

The Quickshell configuration and Hyprland shortcut application ID are both `faishell`.

## Requirements

Run the shell inside a **Hyprland Wayland session**, as your regular user. It uses Hyprland-specific workspace APIs, global shortcuts, and `hyprctl`; other compositors are not currently supported.

The current setup has been checked with **Quickshell 0.3.1** and **Hyprland 0.56.2**. Use Quickshell 0.3.1 or a compatible newer release with the `Quickshell.Networking`, `Quickshell.Bluetooth`, and `Quickshell.Services.Pipewire` modules enabled.

| Requirement | Purpose | Arch Linux packages |
| --- | --- | --- |
| Hyprland | Compositor, shortcuts, workspace control, and `hyprctl` | `hyprland` |
| Quickshell and Qt 6 | Runs the QML shell; Qt Quick Controls, layouts, effects, SVG icons, and Wayland support | `quickshell` (pulls in `qt6-base`, `qt6-declarative`, `qt6-svg`, and `qt6-wayland`) |
| D-Bus | Session and system communication for notifications, tray, networking, and Bluetooth | `dbus` |
| PipeWire audio and a session manager | Audio input/output selection, volume, mute, and Bluetooth audio routing | `pipewire`, `pipewire-audio`, `wireplumber` |
| NetworkManager | Wi-Fi discovery and connection management | `networkmanager` |
| BlueZ | Bluetooth adapter and device management | `bluez` |
| Python 3, dbus-python, and PyGObject | Bluetooth pairing agent, including PIN/passkey and confirmation prompts | `python`, `python-dbus`, `python-gobject` |
| Standard command-line tools | System information and wallpaper discovery: `sh`, `bash`, `df`, `cat`, `stat`, `tr`, `head`, `sort`, `awk`, `sed`, and `find` | `bash`, `coreutils`, `gawk`, `sed`, `findutils` |
| systemd/logind | Power menu actions through `systemctl` | `systemd` |

Quickshell needs the modules above even on a machine where you do not use every dashboard feature. Hardware-dependent features additionally need their corresponding services and devices.

On other distributions, install the equivalent components using your distribution's package names. Check that its Quickshell build includes the native Networking module; older releases may not have it. The package manager should resolve Quickshell's Qt and graphics-library dependencies.

### Install on Arch Linux

For the shell and its audio, Wi-Fi, and Bluetooth features:

```bash
sudo pacman -Syu --needed \
    git hyprland quickshell dbus systemd \
    bash coreutils gawk sed findutils \
    pipewire pipewire-audio wireplumber \
    networkmanager bluez python python-dbus python-gobject
```

The package names and Quickshell dependencies are documented by Arch's [Quickshell package](https://archlinux.org/packages/extra/x86_64/quickshell/) and [PipeWire audio package](https://archlinux.org/packages/extra/x86_64/pipewire-audio/).

### Optional packages

| Package | When you need it |
| --- | --- |
| `pipewire-pulse` | Recommended for applications that use PulseAudio; the shell itself talks to PipeWire directly. |
| `pipewire-alsa` | Routes applications using ALSA through PipeWire. |
| `bluez-utils` | Provides `bluetoothctl` for diagnosing Bluetooth; the shell does not invoke it. |
| `libnotify` | Provides `notify-send` for the Settings panel's test-notification button. |
| `zenity` or `kdialog` | Opens the wallpaper folder picker. You can also type the directory in Settings. |
| `btrfs-progs` and `util-linux` | Enables detailed Btrfs pool/snapshot reporting with `btrfs` and `findmnt`. Storage reporting falls back to `df` when these tools are unavailable. |
| `qt6-imageformats` | Adds image format support for wallpapers, depending on the formats you use. |
| `qt6-shadertools` | Provides `qsb` for rebuilding shaders after editing them. Compiled `.qsb` files are already included. |
| `ripgrep` | Provides `rg`, used by the device and Wi-Fi test runners. |

## Services

NetworkManager must manage the laptop's Wi-Fi adapter. Bluetooth requires a running BlueZ service. On a system using NetworkManager and BlueZ, enable them with:

```bash
sudo systemctl enable --now NetworkManager.service bluetooth.service
```

PipeWire and WirePlumber run in your **user session**. On Arch Linux, start the audio stack with:

```bash
systemctl --user enable --now pipewire.socket wireplumber.service
```

If you installed `pipewire-pulse`, also enable its socket:

```bash
systemctl --user enable --now pipewire-pulse.socket
```

Keep your existing working audio/session-manager setup if it already provides these services. Wi-Fi and Bluetooth hardware radio switches must be enabled for software controls to work.

## Install and run

Clone the repository into a named Quickshell configuration:

```bash
mkdir -p ~/.config/quickshell
git clone https://github.com/noxxxxxious/symbiote.git ~/.config/quickshell/faishell
quickshell -c faishell
```

If you use a custom `XDG_CONFIG_HOME`, put the checkout under `$XDG_CONFIG_HOME/quickshell/faishell` instead. Alternatively, run any checkout directly:

```bash
quickshell -p /path/to/faishell
```

Run it from inside your Hyprland session. There is no application build step for normal use, and the included shaders do not need recompiling.

To start it with Hyprland, add this to `~/.config/hypr/hyprland.conf`:

```ini
exec-once = quickshell -c faishell --no-duplicate
```

The shell includes its own wallpaper window and notification server. Stop any other notification daemon, such as Dunst or Mako, if you want this shell to receive notifications.

## Keyboard shortcuts

Add bindings to your Hyprland configuration; change the keys to suit your setup:

```ini
bind = SUPER, SPACE, global, faishell:toggleLauncher
bind = SUPER, S, global, faishell:toggleSettings
bind = SUPER, D, global, faishell:toggleDashboard
bind = SUPER, N, global, faishell:toggleNotifications
bind = SUPER, B, global, faishell:toggleWidgets

bind = , XF86AudioRaiseVolume, global, faishell:volumeUp
bind = , XF86AudioLowerVolume, global, faishell:volumeDown
bind = , XF86AudioMute, global, faishell:volumeMute
```

`toggleWidgets` temporarily suppresses widgets configured in parasitic mode. You can also reveal the dashboard by hovering at the top center of the screen, and open the power menu by dragging upward from the bottom-center trigger.

Existing `wpctl` media-key bindings also trigger the volume OSD. Choose either those bindings or the shell's volume shortcuts to avoid adjusting volume twice. Hyprland documents the `global` dispatcher in its [key-binding guide](https://wiki.hypr.land/Configuring/Binds/).

## Configuration

Settings are saved in `config.json` next to `shell.qml`. The Settings panel edits this file, and manual changes reload automatically. Keep the checkout writable by your user. Application usage is stored alongside it in `app_usage.json`.

Before using the supplied configuration on another machine:

- Set `wallpaper.directory` and `wallpaper.path` to your own files; the checked-in values point to the author's home directory.
- Check notification screen selection and placement. The supplied configuration contains a `DP-3` monitor name; use your laptop's monitor or the current active screen mode.
- Adjust dashboard size, workspace placement/count, and widget modes in Settings to suit your display.

No special font or separate wallpaper daemon is required by the code. Application/tray icons come from the installed icon themes and applications.

See [device controls](DEVICE_CONTROLS.md) for more detail about audio, Bluetooth, Wi-Fi, and OSD behavior.

## Current scope

Audio includes default input/output selection, volume, mute, and an output volume/mute OSD. Bluetooth includes power, timed scanning, pairing prompts, connections, trust, and forget. Wi-Fi includes power, timed scanning, adapter selection, saved connections, open networks, WPA/WPA2/WPA3 password entry, and disconnect.

Enterprise/WEP Wi-Fi profiles must be configured through NetworkManager first; hidden-network setup is not included. Captive portals still require browser sign-in. The VPN and Media dashboard tabs are placeholders, and brightness OSD is not implemented.

## Development and checks

From the repository root, run the device checks without changing real hardware:

```bash
bash tests/run-devices.sh
bash tests/run-wifi.sh
python3 tests/test_bluetooth_pair.py
```

The QML checks use Qt Test and an offscreen Quickshell instance. Install `ripgrep` for the device/Wi-Fi runners, and the Python pairing dependencies for the pairing-agent tests. Other existing suites are `tests/run-workspaces.sh`, `tests/run-notifications.sh`, and `tests/run-power-menu.sh`; the notification and power-menu suites currently have known failing assertions.

To rebuild shaders after editing their source, install `qt6-shadertools` and run:

```bash
PATH="/usr/lib/qt6/bin:$PATH" bash components/compile-shaders components/shaders
```

On other distributions, adjust the Qt tools path if `qsb` is not already on `PATH`.
