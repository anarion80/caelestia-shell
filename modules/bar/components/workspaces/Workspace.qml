import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property int index
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property real size: childrenRect.width + (hasWindows ? Appearance.padding.normal : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && BarConfig.workspaces.showWindows

    Layout.preferredWidth: size
    Layout.preferredHeight: childrenRect.height

    StyledText {
        id: indicator

        readonly property string label: BarConfig.workspaces.label || root.ws
        readonly property string occupiedLabel: BarConfig.workspaces.occupiedLabel || label
        readonly property string activeLabel: BarConfig.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label)

        animate: true
        text: Hyprland.activeWsId === root.ws ? `${activeLabel}` : root.isOccupied ? occupiedLabel : label
        color: BarConfig.workspaces.occupiedBg || root.isOccupied || Hyprland.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant
        horizontalAlignment: StyledText.AlignHCenter
        verticalAlignment: StyledText.AlignVCenter

        width: BarConfig.sizes.innerHeight
        height: BarConfig.sizes.innerHeight
    }

    Loader {
        id: windows

        active: BarConfig.workspaces.showWindows
        asynchronous: false

        anchors.verticalCenter: indicator.verticalCenter
        anchors.left: indicator.right

        sourceComponent: Row {
            spacing: Appearance.spacing.small

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: Hyprland.clients.filter(c => c.workspace?.id === root.ws)
                }

                MaterialIcon {
                    required property Hyprland.Client modelData

                    text: Icons.getAppCategoryIcon(modelData.wmClass, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on Layout.preferredWidth {
        Anim {}
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
