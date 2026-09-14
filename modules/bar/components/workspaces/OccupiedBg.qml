pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Components
import qs.components
import qs.services

Item {
    id: root

    required property var workspaces
    required property int wsSpacing

    readonly property color colour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property color colourAnimated: colour

    Behavior on colourAnimated {
        CAnim {}
    }

    // Item wrappers because `layer.enabled` clips the content, and the rects extend 1px outside the parent
    Item {
        anchors.fill: parent
        anchors.margins: -1

        opacity: root.colourAnimated.a
        layer.enabled: opacity < 1 // Forces opacity to apply to children as a single layer

        Item {
            anchors.fill: parent
            anchors.margins: 1

            Repeater {
                model: ScriptModel {
                    values: root.workspaces
                }

                OccupiedRect {}
            }
        }
    }

    component OccupiedRect: StyledRect {
        required property int index
        required property Workspace modelData
        property real leftRadius: {
            if (!modelData?.isOccupied || index === 0)
                return height / 2;
            return (root.workspaces[index - 1]?.isOccupied ?? false) ? 0 : height / 2;
        }
        property real rightRadius: {
            if (!modelData?.isOccupied || index === root.workspaces.length - 1)
                return height / 2;
            return (root.workspaces[index + 1]?.isOccupied ?? false) ? 0 : height / 2;
        }
        property real leftPadding: {
            if (!modelData?.isOccupied || index === 0)
                return 0;
            return (root.workspaces[index - 1]?.isOccupied ?? false) ? root.wsSpacing : 0;
        }
        property real rightPadding: {
            if (!modelData?.isOccupied || index === root.workspaces.length - 1)
                return 0;
            return (root.workspaces[index + 1]?.isOccupied ?? false) ? root.wsSpacing : 0;
        }

        anchors.top: parent?.top
        anchors.bottom: parent?.bottom
        anchors.margins: -1

        x: modelData ? modelData.x + anchors.margins - leftPadding : 0
        implicitWidth: modelData ? modelData.LazyListView.visibleWidth - anchors.margins * 2 + leftPadding + rightPadding : 0

        color: Qt.alpha(root.colour, 1)
        topLeftRadius: leftRadius
        topRightRadius: rightRadius
        bottomLeftRadius: leftRadius
        bottomRightRadius: rightRadius

        opacity: modelData?.isOccupied ? 1 : 0

        Behavior on leftRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on rightRadius {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on leftPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on rightPadding {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
