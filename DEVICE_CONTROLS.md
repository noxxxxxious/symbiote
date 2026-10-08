The dashboard's SOUND tab selects the default PipeWire output and input and controls their volume and mute state. Device lists update when hardware is connected or removed. Bluetooth audio devices appear here once BlueZ and PipeWire expose them.

The BLUETOOTH tab supports adapter power, a 30-second discovery scan, pairing, connect/disconnect, trust, and forget. Pairing prompts stay in the tab; pairing a device also trusts and connects it. PIN/passkey pairing requires Python 3, dbus-python, and PyGObject (Arch packages: `python-dbus` and `python-gobject`). The laptop also needs a running BlueZ service and PipeWire with a session manager such as WirePlumber. A radio blocked by a hardware switch must be unblocked first.

A volume OSD appears for output volume/mute changes, including changes made by external tools. Brightness OSD is not implemented yet. Optional Hyprland bindings for the new shell shortcuts:

```ini
bind = , XF86AudioRaiseVolume, global, faishell:volumeUp
bind = , XF86AudioLowerVolume, global, faishell:volumeDown
bind = , XF86AudioMute, global, faishell:volumeMute
```

Existing `wpctl` volume bindings also trigger the OSD. Choose one set of bindings to avoid changing volume twice.

Run `bash tests/run-devices.sh` to check the panels and device interactions using mock devices without altering hardware. Before travel, check real audio routing and Bluetooth pairing on the laptop.

The WI-FI tab uses Quickshell 0.3.1's native Networking module with NetworkManager. It supports radio power, adapter selection, 30-second scans, signal/security status, saved connections, open networks, WPA/WPA2 passwords, WPA3 SAE passwords, and disconnect. Connection errors appear in the panel; missing or rejected saved passwords reopen the password field. Passwords are cleared from the field after submission or dismissal. The dashboard stays open while a password prompt is active.

Wi-Fi networks use the same three-column card layout as Bluetooth. Configure enterprise/WEP authentication through NetworkManager first; this panel can reconnect saved profiles. Hidden-network setup is not included. When NetworkManager reports a captive portal, the panel directs you to sign in through your browser. Run `bash tests/run-wifi.sh` for isolated connection, password-retry, radio, and scan-lifecycle checks.
