import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour

    // The caps lock icon takes the first slot, the num lock icon the second.
    // Slots extend leftward (into the bar's fill-width spacer) as locks toggle
    // on; both whole icons are shown side by side when both locks are on.
    property real capsWidth: Hypr.capsLock ? capslockIcon.implicitWidth : 0
    property real numWidth: Hypr.numLock ? numlockIcon.implicitWidth : 0

    // Fixed slot height: this entry must never change height, otherwise the
    // status icon row re-lays-out and pushes the other icons when locks toggle.
    implicitWidth: Math.round(capsWidth + numWidth)
    implicitHeight: Tokens.sizes.bar.innerHeight

    Behavior on capsWidth {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numWidth {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Item {
        id: capsSlot

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        width: Math.round(root.capsWidth)
        height: capslockIcon.implicitHeight

        MaterialIcon {
            id: capslockIcon

            anchors.centerIn: parent

            scale: Hypr.capsLock ? 1 : 0.5
            opacity: Hypr.capsLock ? 1 : 0

            text: "keyboard_capslock_badge"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Item {
        id: numSlot

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        width: Math.round(root.numWidth)
        height: numlockIcon.implicitHeight

        MaterialIcon {
            id: numlockIcon

            anchors.centerIn: parent

            scale: Hypr.numLock ? 1 : 0.5
            opacity: Hypr.numLock ? 1 : 0

            text: "looks_one"
            color: root.colour
            fill: 1
            grade: 25

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }
    }
}
