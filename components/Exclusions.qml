import Quickshell
import Quickshell.Wayland

Scope {
  id: root

  required property var modelData

  readonly property bool isFullscreen: HyprState.isFullscreen(root.modelData)

  // qmllint disable uncreatable-type
  component EdgeZone: PanelWindow {
    id: edge
    screen: root.modelData
    color: "transparent"
    mask: Region {}

    WlrLayershell.namespace: "faishell:exclusion"

    exclusiveZone: root.isFullscreen ? 0 : Theme.borderThickness
    implicitWidth: 1
    implicitHeight: 1
  }

  EdgeZone { anchors.top: true }
  EdgeZone { anchors.bottom: true }
  EdgeZone { anchors.left: true }
  EdgeZone { anchors.right: true }
}
