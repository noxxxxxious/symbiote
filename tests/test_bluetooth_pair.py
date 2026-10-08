"""Exercise the pairing agent replies without connecting to the system bus."""
import contextlib
import io
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch, MagicMock


class PairingAgentTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import dbus
        from gi.repository import GLib
        with patch.object(dbus, "SystemBus", return_value=MagicMock()), patch.object(dbus, "Interface", return_value=MagicMock()), patch.object(GLib, "MainLoop"), patch.object(GLib, "io_add_watch"), patch.object(GLib, "timeout_add_seconds"), patch("sys.argv", ["agent", "/test/device"]), contextlib.redirect_stdout(io.StringIO()):
            cls.module = runpy.run_path(str(Path(__file__).parents[1] / "components/bluetooth-pair.py"))

    def setUp(self):
        self.agent = self.module["Agent"].__new__(self.module["Agent"])
        self.agent.pending = None
        self.reply = MagicMock()
        self.error = MagicMock()

    def prompt(self, kind):
        with contextlib.redirect_stdout(io.StringIO()):
            self.agent.prompt(kind, self.reply, self.error, message="test")

    def test_confirmation_requires_explicit_acceptance(self):
        self.prompt("confirm")
        self.agent.respond({"accept": False})
        self.error.assert_called_once()
        self.reply.assert_not_called()
        self.assertIsNone(self.agent.pending)

    def test_pin_preserves_leading_zeroes(self):
        self.prompt("pin")
        self.agent.respond({"accept": True, "value": "001234"})
        self.reply.assert_called_once_with("001234")

    def test_passkey_is_integer(self):
        self.prompt("passkey")
        self.agent.respond({"accept": True, "value": "001234"})
        self.assertEqual(int(self.reply.call_args.args[0]), 1234)

    def test_invalid_passkey_is_rejected(self):
        for value in ["", "1234567", "no", "-1", "１２３"]:
            self.reply.reset_mock()
            self.error.reset_mock()
            self.prompt("passkey")
            self.agent.respond({"accept": True, "value": value})
            self.error.assert_called_once()
            self.reply.assert_not_called()

    def test_cancel_rejects_pending_request(self):
        self.prompt("confirm")
        with contextlib.redirect_stdout(io.StringIO()):
            self.agent.Cancel()
        self.error.assert_called_once()
        self.assertIsNone(self.agent.pending)


if __name__ == "__main__":
    unittest.main()
