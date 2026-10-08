"""VPN operations tested against fake NetworkManager connections, never a tunnel."""
import contextlib
import io
import json
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import dbus

spec = importlib.util.spec_from_file_location("vpn_helper", Path(__file__).parents[1] / "components/vpn-helper.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
UUID = "11111111-1111-1111-1111-111111111111"


class FakeSettings:
    def __init__(self, manager, path, settings):
        self.manager, self.path, self.settings = manager, path, settings

    def Update(self, settings):
        self.settings = settings
        self.manager.updates.append(settings)

    def Delete(self):
        del self.manager.pool[self.path]


class FakeManager(helper.Manager):
    def __init__(self):
        self.dbus = dbus
        self.pool = {}
        self.updates = []
        self.active_items = []
        self.deactivated = []
        self.nm = self

    def connections(self):
        return [(path, item.settings) for path, item in self.pool.items()]

    def active(self):
        return self.active_items

    def interface(self, path, name):
        return self.pool[path]

    def DeactivateConnection(self, path):
        self.deactivated.append(path)

    def imported(self):
        settings = {"connection": {"id": "Imported", "uuid": UUID, "type": "vpn"},
                    "vpn": {"service-type": "org.freedesktop.NetworkManager.openvpn", "data": {}}}
        self.pool["/test/imported"] = FakeSettings(self, "/test/imported", settings)
        return f"Connection 'Imported' ({UUID}) successfully added."


class VpnTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.profile = self.root / "sample.ovpn"
        self.profile.write_text("client\nauth-user-pass auth\n<key>\nPRIVATE KEY NOT A DIRECTIVE\n</key>\n")
        (self.root / "auth").write_text("test-user\ntest-password\n")
        helper.SECRETS.clear()

    def test_relative_auth_file(self):
        self.assertEqual(helper.credentials(self.profile), ("test-user", "test-password"))

    def test_quoted_auth_file_and_inline_blocks(self):
        (self.root / "my auth").write_text("user\npassword\n")
        self.profile.write_text('<key>\nauth-user-pass wrong\n</key>\nauth-user-pass "my auth" # comment\n')
        self.assertEqual(helper.auth_reference(self.profile), self.root / "my auth")

    def test_missing_auth_is_actionable(self):
        (self.root / "auth").unlink()
        with self.assertRaisesRegex(ValueError, "Cannot read"):
            helper.credentials(self.profile)
        self.profile.write_text("auth-user-pass\n")
        with self.assertRaisesRegex(ValueError, "needs an auth-user-pass file"):
            helper.credentials(self.profile)

    def test_import_once_reuse_and_refresh_changed_profile(self):
        manager = FakeManager()
        calls = []
        def nmcli(arguments, **kwargs):
            calls.append((arguments, kwargs))
            return manager.imported() if "import" in arguments else "activated"
        with patch.object(helper, "plugin_available", return_value=True), patch.object(helper, "run_nmcli", side_effect=nmcli):
            manager.connect(self.profile, self.root)
            self.assertEqual(len(manager.pool), 1)
            settings = manager.updates[-1]
            self.assertFalse(settings["connection"]["autoconnect"])
            self.assertEqual(settings["vpn"]["data"]["username"], "test-user")
            self.assertEqual(settings["vpn"]["data"]["password-flags"], "2")
            self.assertNotIn("secrets", settings["vpn"])
            self.assertNotIn("test-password", str(settings))
            self.assertEqual(calls[-1][1]["secret"], "test-password")
            manager.connect(self.profile, self.root)
            self.assertEqual(sum("import" in args for args, _ in calls), 1)
            # Simulate a new UUID/path on reimport, as real NetworkManager does.
            def reimport(arguments, **kwargs):
                calls.append((arguments, kwargs))
                if "import" in arguments:
                    result = manager.imported()
                    item = manager.pool.pop("/test/imported")
                    item.settings["connection"]["uuid"] = "22222222-2222-2222-2222-222222222222"
                    item.path = "/test/changed"
                    manager.pool["/test/changed"] = item
                    return result.replace(UUID, item.settings["connection"]["uuid"])
                return "activated"
            self.profile.write_text(self.profile.read_text() + "verb 3\n")
            # Move the old entry so the simulated importer doesn't replace it.
            manager.pool["/test/old"] = manager.pool.pop("/test/imported")
            manager.pool["/test/old"].path = "/test/old"
            with patch.object(helper, "run_nmcli", side_effect=reimport):
                manager.connect(self.profile, self.root)
            self.assertEqual(len(manager.pool), 1)
            self.assertEqual(sum("import" in args for args, _ in calls), 2)

    def test_no_second_vpn_and_disconnect_is_scoped(self):
        manager = FakeManager()
        manager.active_items = [{"uuid": UUID, "path": "/active/test", "state": 2}]
        with patch.object(helper, "plugin_available", return_value=True):
            with self.assertRaisesRegex(ValueError, "Disconnect the active VPN"):
                manager.connect(self.profile, self.root)
        manager.disconnect("other-uuid")
        self.assertEqual(manager.deactivated, [])
        manager.disconnect(UUID)
        self.assertEqual(manager.deactivated, ["/active/test"])

    def test_credentials_use_pipe_and_not_command_arguments(self):
        def run(command, **kwargs):
            self.assertNotIn("test-password", str(command))
            fd = kwargs["pass_fds"][0]
            self.assertEqual(os.read(fd, 8192), b"vpn.secrets.password:test-password\n")
            return subprocess.CompletedProcess(command, 0, "connected", "")
        with patch.object(helper.subprocess, "run", side_effect=run):
            self.assertEqual(helper.run_nmcli(["connection", "up", "uuid", UUID], secret="test-password"), "connected")

    def test_operation_errors_redact_credentials(self):
        manager = FakeManager()
        def fail(*args):
            helper.SECRETS.extend(["test-user", "test-password"])
            raise RuntimeError("Connection failed for test-user with test-password")
        output = io.StringIO()
        with patch.object(helper, "Manager", return_value=manager), patch.object(manager, "connect", side_effect=fail), patch("sys.argv", ["helper", "connect", str(self.profile)]), contextlib.redirect_stdout(output):
            helper.main()
        self.assertNotIn("test-password", output.getvalue())
        self.assertNotIn("test-user", output.getvalue())
        self.assertIn("[redacted]", json.loads(output.getvalue())["error"])

    def test_snapshot_finds_files_without_reading_auth(self):
        manager = FakeManager()
        (self.root / "auth").unlink()
        with patch.object(helper, "plugin_available", return_value=True):
            result = manager.snapshot(self.root)
        self.assertEqual(len(result["profiles"]), 1)
        self.assertEqual(result["profiles"][0]["state"], 0)
        self.assertEqual(result["active"], [])


if __name__ == "__main__":
    unittest.main()
