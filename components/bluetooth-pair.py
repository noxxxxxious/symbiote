#!/usr/bin/env python3
"""One pairing session; newline JSON prompts/replies over stdio."""
import json
import sys


def emit(kind, **fields):
    print(json.dumps(dict(kind=kind, **fields)), flush=True)


try:
    import dbus
    import dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
except ImportError:
    emit("error", message="Pairing requires python-dbus and python-gobject.")
    sys.exit(1)


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
loop = GLib.MainLoop()
AGENT = "org.bluez.Agent1"


class Agent(dbus.service.Object):
    pending = None

    def prompt(self, kind, reply, error, **fields):
        if self.pending:
            self.pending[1](Rejected("Superseded"))
        self.pending = (reply, error, kind)
        emit("prompt", promptType=kind, **fields)

    @dbus.service.method(AGENT, in_signature="", out_signature="")
    def Release(self):
        self.Cancel()

    @dbus.service.method(AGENT, in_signature="", out_signature="")
    def Cancel(self):
        if self.pending:
            self.pending[1](Rejected("Cancelled"))
            self.pending = None
        emit("cancelled")

    @dbus.service.method(AGENT, in_signature="o", out_signature="s", async_callbacks=("reply", "error"))
    def RequestPinCode(self, device, reply, error):
        self.prompt("pin", reply, error, message="Enter the PIN shown by the device.")

    @dbus.service.method(AGENT, in_signature="o", out_signature="u", async_callbacks=("reply", "error"))
    def RequestPasskey(self, device, reply, error):
        self.prompt("passkey", reply, error, message="Enter the six-digit passkey.")

    @dbus.service.method(AGENT, in_signature="ou", out_signature="", async_callbacks=("reply", "error"))
    def RequestConfirmation(self, device, passkey, reply, error):
        self.prompt("confirm", reply, error, message=f"Does the device show {int(passkey):06d}?")

    @dbus.service.method(AGENT, in_signature="o", out_signature="", async_callbacks=("reply", "error"))
    def RequestAuthorization(self, device, reply, error):
        self.prompt("confirm", reply, error, message="Allow this device to pair?")

    @dbus.service.method(AGENT, in_signature="os", out_signature="", async_callbacks=("reply", "error"))
    def AuthorizeService(self, device, uuid, reply, error):
        self.prompt("confirm", reply, error, message="Allow the device to connect?")

    @dbus.service.method(AGENT, in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pin):
        emit("display", message=f"Enter PIN {pin} on the device.")

    @dbus.service.method(AGENT, in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        emit("display", message=f"Enter {int(passkey):06d} on the device ({entered} digits entered).")

    def respond(self, data):
        if not self.pending:
            return
        reply, error, kind = self.pending
        self.pending = None
        if not data.get("accept"):
            error(Rejected("Declined"))
        elif kind == "pin":
            value = str(data.get("value", ""))
            if 1 <= len(value) <= 16:
                reply(value)
            else:
                error(Rejected("Invalid PIN"))
        elif kind == "passkey":
            value = str(data.get("value", ""))
            if value.isascii() and value.isdigit() and len(value) <= 6:
                reply(dbus.UInt32(int(value)))
            else:
                error(Rejected("Invalid passkey"))
        else:
            reply()


def read_reply(source, condition):
    line = sys.stdin.readline()
    if not line:
        loop.quit()
        return False
    try:
        agent.respond(json.loads(line))
    except (ValueError, TypeError):
        agent.respond({"accept": False})
    return True


def failed(error):
    emit("error", message=str(error))
    loop.quit()


def connected():
    emit("done", message="Paired and connected.")
    loop.quit()


def paired():
    try:
        dbus.Interface(device, "org.freedesktop.DBus.Properties").Set("org.bluez.Device1", "Trusted", True)
        dbus.Interface(device, "org.bluez.Device1").Connect(reply_handler=connected, error_handler=failed)
    except dbus.DBusException as error:
        failed(error)


try:
    agent = Agent(bus, "/org/faishell/PairingAgent")
    manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
    manager.RegisterAgent("/org/faishell/PairingAgent", "KeyboardDisplay")
    device = bus.get_object("org.bluez", sys.argv[1])
    GLib.io_add_watch(sys.stdin, GLib.IO_IN | GLib.IO_HUP, read_reply)
    GLib.timeout_add_seconds(120, lambda: (failed("Pairing timed out. Try again."), False)[1])
    dbus.Interface(device, "org.bluez.Device1").Pair(reply_handler=paired, error_handler=failed)
    loop.run()
except (dbus.DBusException, IndexError) as error:
    failed(error)
