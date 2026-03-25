pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    required property bool disabled

    readonly property int clampedHeight: Math.max(Config.border.minThickness, implicitHeight)
    readonly property int padding: Math.max(Appearance.padding.smaller, Config.border.thickness)
    readonly property int contentHeight: Config.bar.sizes.innerHeight + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || visibilities.bar) ? contentHeight : Config.border.thickness
    readonly property bool shouldBeVisible: !disabled && (Config.bar.persistent || visibilities.bar || isHovered)
    property bool isHovered

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function checkPopout(x: real): void {
        (content.item as Bar)?.checkPopout(x);
    }

    function handleWheel(y: real, angleDelta: point): void {
        (content.item as Bar)?.handleWheel(x, angleDelta);
    }

    visible: height > Config.border.thickness
    implicitHeight: Config.border.thickness

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.implicitHeight: root.contentHeight
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "implicitHeight"
                duration: Appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "implicitHeight"
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    ]

    Loader {
        id: content

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: parent.right

        active: root.shouldBeVisible || root.visible

        sourceComponent: Bar {
            height: root.contentHeight
            screen: root.screen
            visibilities: root.visibilities
            popouts: root.popouts // qmllint disable incompatible-type
        }
    }
}
