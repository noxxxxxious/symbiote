#!/usr/bin/env python3
"""OpenVPN profile discovery and NetworkManager control. Emits one JSON result."""
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

NM = "org.freedesktop.NetworkManager"
ROOT = "/org/freedesktop/NetworkManager"
SETTINGS = NM + ".Settings.Connection"
PREFIX = "faishell-vpn-"
SOURCE = "faishell.vpn.source"
SECRETS = []


def profile_id(path):
    return PREFIX + hashlib.sha256(str(path).encode()).hexdigest()[:16] + "-" + path.stem


def auth_reference(path):
    """Parse just auth-user-pass, skipping inline certificate/key blocks."""
    inline = False
    for line in path.read_text().splitlines():
        line = line.strip()
        if line.startswith("<") and line.endswith(">"):
            inline = not line.startswith("</")
            continue
        if inline or not line or line.startswith(("#", ";")):
            continue
        fields = shlex.split(line, comments=True)
        if fields and fields[0] == "auth-user-pass":
            if len(fields) < 2:
                raise ValueError("This profile needs an auth-user-pass file containing a username and password.")
            auth = Path(fields[1]).expanduser()
            return auth if auth.is_absolute() else path.parent / auth
    return None


def credentials(path):
    auth = auth_reference(path)
    if auth is None:
        return None
    try:
        lines = auth.read_text().splitlines()
    except OSError:
        raise ValueError("Cannot read the profile's auth-user-pass file. Check its path and permissions.") from None
    if len(lines) < 2 or not lines[0] or not lines[1]:
        raise ValueError("The auth-user-pass file must contain a username and password on separate lines.")
    if len(lines[0]) > 4096 or len(lines[1]) > 4096:
        raise ValueError("The auth-user-pass credentials are too long.")
    SECRETS.extend(lines[:2])
    return lines[0], lines[1]


def plugin_available():
    return any((Path(directory) / "nm-openvpn-service.name").exists() for directory in
               ["/usr/lib/NetworkManager/VPN", "/usr/share/NetworkManager/VPN", "/etc/NetworkManager/VPN"])


def run_nmcli(arguments, cwd=None, secret=None):
    command = ["nmcli", "--colors", "no", "--wait", "60", *arguments]
    read_fd = write_fd = None
    try:
        if secret is not None:
            # Credentials travel through an inherited pipe, never argv or disk.
            read_fd, write_fd = os.pipe()
            os.write(write_fd, ("vpn.secrets.password:" + secret + "\n").encode())
            os.close(write_fd)
            write_fd = None
            command += ["passwd-file", f"/proc/self/fd/{read_fd}"]
        result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=75,
                                env={**os.environ, "LC_ALL": "C"},
                                pass_fds=() if read_fd is None else (read_fd,))
    finally:
        if read_fd is not None:
            os.close(read_fd)
        if write_fd is not None:
            os.close(write_fd)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip() or "NetworkManager could not complete the VPN operation.")
    return result.stdout


class Manager:
    def __init__(self):
        import dbus
        self.dbus = dbus
        self.bus = dbus.SystemBus()
        self.nm = dbus.Interface(self.bus.get_object(NM, ROOT), NM)
        self.settings = dbus.Interface(self.bus.get_object(NM, ROOT + "/Settings"), NM + ".Settings")

    def interface(self, path, interface):
        return self.dbus.Interface(self.bus.get_object(NM, path), interface)

    def connections(self):
        result = []
        for path in self.settings.ListConnections():
            try:
                settings = self.interface(path, SETTINGS).GetSettings()
                if settings.get("connection", {}).get("type") == "vpn":
                    result.append((str(path), settings))
            except self.dbus.DBusException:
                continue
        return result

    def active(self):
        paths = self.interface(ROOT, "org.freedesktop.DBus.Properties").Get(NM, "ActiveConnections")
        result = []
        for path in paths:
            try:
                data = self.interface(path, "org.freedesktop.DBus.Properties").GetAll(NM + ".Connection.Active")
                if data.get("Type") == "vpn" and int(data.get("State", 0)) in (1, 2, 3):
                    result.append({"uuid": str(data["Uuid"]), "name": re.sub(r"^faishell-vpn-[0-9a-f]{16}-", "", str(data["Id"])),
                                   "state": int(data["State"]), "path": str(path)})
            except self.dbus.DBusException:
                continue
        return result

    def snapshot(self, directory):
        active = self.active()
        connections = self.connections()
        profiles = []
        if directory.exists():
            for path in sorted(directory.iterdir()):
                if not path.is_file() or path.suffix.lower() != ".ovpn":
                    continue
                path = path.absolute()
                found = next((s for _, s in connections if s.get("connection", {}).get("id") == profile_id(path)), None)
                uuid = str(found["connection"]["uuid"]) if found else ""
                state = next((a["state"] for a in active if a["uuid"] == uuid), 0)
                profiles.append({"name": path.stem, "path": str(path), "uuid": uuid, "state": state})
        return {"profiles": profiles, "active": active, "available": plugin_available() and bool(shutil.which("nmcli")),
                "error": "" if plugin_available() else "Install NetworkManager's OpenVPN plugin to connect these profiles."}

    def connect(self, path, directory):
        path = Path(path).expanduser().absolute()
        if path.parent != directory.absolute() or path.suffix.lower() != ".ovpn" or not path.is_file():
            raise ValueError("Choose an .ovpn file in ~/.vpn.")
        if not plugin_available():
            raise ValueError("Install NetworkManager's OpenVPN plugin (networkmanager-vpn-plugin-openvpn on Arch).")
        auth = credentials(path)
        fingerprint = hashlib.sha256(path.read_bytes()).hexdigest()
        old = next(((p, s) for p, s in self.connections() if s["connection"]["id"] == profile_id(path)), None)
        if self.active():
            raise ValueError("Disconnect the active VPN before connecting another profile.")
        connection = old
        if old is None or old[1].get("user", {}).get("data", {}).get("faishell.vpn.fingerprint") != fingerprint:
            output = run_nmcli(["connection", "import", "type", "openvpn", "file", str(path)], cwd=path.parent)
            match = re.search(r"\(([0-9a-fA-F-]{36})\)", output)
            if not match:
                raise RuntimeError("NetworkManager imported the profile but did not return its UUID.")
            connection = next(((p, s) for p, s in self.connections() if s["connection"]["uuid"] == match.group(1)), None)
            if connection is None:
                raise RuntimeError("Cannot find the imported VPN profile.")
        conn_path, settings = connection
        settings["connection"]["id"] = profile_id(path)
        settings["connection"]["autoconnect"] = self.dbus.Boolean(False)
        settings["connection"]["permissions"] = self.dbus.Array([f"user:{getpass.getuser()}:"], signature="s")
        settings["user"] = self.dbus.Dictionary({"data": self.dbus.Dictionary(
            {SOURCE: str(path), "faishell.vpn.fingerprint": fingerprint}, signature="ss")}, signature="sv")
        if auth:
            data = settings["vpn"].get("data", self.dbus.Dictionary({}, signature="ss"))
            data["username"] = auth[0]
            data["password-flags"] = "2"  # NM_SETTING_SECRET_FLAG_NOT_SAVED
            settings["vpn"]["data"] = data
            settings["vpn"].pop("secrets", None)
        try:
            self.interface(conn_path, SETTINGS).Update(settings)
        except Exception:
            if old is None or conn_path != old[0]:
                self.interface(conn_path, SETTINGS).Delete()
            raise
        if old and conn_path != old[0]:
            self.interface(old[0], SETTINGS).Delete()
        run_nmcli(["connection", "up", "uuid", str(settings["connection"]["uuid"])],
                  cwd=path.parent, secret=auth[1] if auth else None)

    def disconnect(self, uuid):
        active = next((item for item in self.active() if item["uuid"] == uuid), None)
        if active:
            self.nm.DeactivateConnection(active["path"])


def main():
    directory = Path.home() / ".vpn"
    try:
        manager = Manager()
        action = sys.argv[1] if len(sys.argv) > 1 else "list"
        if action == "connect":
            manager.connect(sys.argv[2], directory)
        elif action == "disconnect":
            manager.disconnect(sys.argv[2])
        elif action != "list":
            raise ValueError("Unknown VPN operation.")
        result = manager.snapshot(directory)
        if action != "list":
            result["message"] = "VPN connected." if action == "connect" else "VPN disconnect requested."
    except ImportError:
        result = {"error": "VPN controls require Python 3 and python-dbus.", "available": False}
    except subprocess.TimeoutExpired:
        result = {"error": "The VPN operation timed out. Check the profile and try again."}
    except Exception as error:
        message = str(error)
        for secret in SECRETS:
            message = message.replace(secret, "[redacted]")
        result = {"error": message}
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
