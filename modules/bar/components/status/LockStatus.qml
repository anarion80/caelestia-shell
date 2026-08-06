import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property color colour
    required property int parentSpacing

    property real gap: Hypr.capsLock && Hypr.numLock ? parentSpacing : 0
    property real capsHeight: Hypr.capsLock ? capslockIcon.implicitHeight : 0
    property real numHeight: Hypr.numLock ? numlockIcon.implicitHeight : 0

    // Fixed slot height: this entry must never change size, otherwise the
    // status icon row re-lays-out and pushes the other icons when locks toggle.
    implicitWidth: column.implicitWidth
    implicitHeight: Tokens.sizes.bar.innerHeight

    Behavior on gap {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on capsHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    Behavior on numHeight {
        Anim {
            type: Anim.SlowEffects
        }
    }

    ColumnLayout {
        id: column

        anchors.centerIn: parent

        spacing: Math.round(root.gap)

        Item {
            implicitWidth: capslockIcon.implicitWidth
            implicitHeight: Math.round(root.capsHeight)

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
            implicitWidth: numlockIcon.implicitWidth
            implicitHeight: Math.round(root.numHeight)

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
}
