import QtQuick
import Quickshell.Io
import "."

Item {
    id: root
    required property var targetScreen
    readonly property bool isOpen: PowerMenuController.isOpenOn(targetScreen)
    readonly property bool visuallyOpen: isOpen || card0.growth > 0.01 || card1.growth > 0.01 || card2.growth > 0.01 || card3.growth > 0.01 || card4.growth > 0.01
    readonly property var cards: [card0, card1, card2, card3, card4]
    readonly property var slots: {
        var config = Config.sAdapter.powerMenu
        return manager0.slots.concat(manager1.slots, manager2.slots, manager3.slots, manager4.slots).filter(function(slot) {
            return slot.isExtra && slot.activation > 0.001
        }).map(function(slot) {
            var copy = Object.assign({}, slot)
            copy.rootThick *= config.rootThickness
            copy.waistThick *= config.waistThickness
            copy.panelThick *= config.tipThickness
            return copy
        })
    }
    readonly property bool busy: actionProcess.running
    property string errorMessage: ""
    visible: visuallyOpen
    onVisibleChanged: console.log("[PowerMenu]", targetScreen ? targetScreen.name : "<none>", "visible:", visible, "isOpen:", isOpen, "visuallyOpen:", visuallyOpen)
    function panelRect(index) {
        var c = cards[index]
        return Qt.vector4d(c.x, c.y, c.width, c.height)
    }
    function commandForAction(index) {
        var action = {0: "poweroff", 2: "suspend", 3: "reboot"}[index]
        return action ? ["systemctl", action] : []
    }
    function activate(index) {
        if (!isOpen || busy || index === 1) return
        if (index === 4) {
            SettingsController.openOn(targetScreen)
            return
        }
        var command = commandForAction(index)
        if (!command.length) return
        errorMessage = ""
        actionProcess.command = command
        actionProcess.running = true
    }
    Process {
        id: actionProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) PowerMenuController.close()
            else root.errorMessage = "Could not complete the action. Check your session permissions and try again."
        }
    }
    onIsOpenChanged: {
        console.log("[PowerMenu]", targetScreen ? targetScreen.name : "<none>", "isOpen:", isOpen, "visuallyOpen:", visuallyOpen)
        errorMessage = ""
        if (isOpen) {
            forceActiveFocus()
            var order = [0, 1, 2, 3, 4]
            for (var i = order.length - 1; i > 0; --i) {
                var j = Math.floor(Math.random() * (i + 1))
                var temp = order[i]; order[i] = order[j]; order[j] = temp
            }
            for (var k = 0; k < order.length; ++k) cards[order[k]].reveal(k * 110)
        } else {
            for (var n = 0; n < cards.length; ++n) cards[n].dismiss()
        }
    }
    Keys.onEscapePressed: PowerMenuController.close()
    MouseArea { anchors.fill: parent; onClicked: PowerMenuController.close() }
    PowerCard { id: card0; menu: root; actionIndex: 0 }
    PowerCard { id: card1; menu: root; actionIndex: 1 }
    PowerCard { id: card2; menu: root; actionIndex: 2 }
    PowerCard { id: card3; menu: root; actionIndex: 3 }
    PowerCard { id: card4; menu: root; actionIndex: 4 }
    TendrilManager { id: manager4; panel: card4; enabled: card4.revealed; screenWidth: root.width; screenHeight: root.height }
    TendrilManager { id: manager0; panel: card0; enabled: card0.revealed; screenWidth: root.width; screenHeight: root.height }
    TendrilManager { id: manager1; panel: card1; enabled: card1.revealed; screenWidth: root.width; screenHeight: root.height }
    TendrilManager { id: manager2; panel: card2; enabled: card2.revealed; screenWidth: root.width; screenHeight: root.height }
    TendrilManager { id: manager3; panel: card3; enabled: card3.revealed; screenWidth: root.width; screenHeight: root.height }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.93
        width: parent.width * 0.8
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.errorMessage || ""
        color: Theme.textColorSoft; font.pixelSize: 14
    }
}
