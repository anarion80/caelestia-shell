pragma ComponentBehavior: Bound

import qs.components
import qs.components.containers
import qs.services
import qs.config
import qs.modules.bar
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

Variants {
    model: Quickshell.screens

    Scope {
        id: scope

        required property ShellScreen modelData

        Exclusions {
            screen: scope.modelData
            bar: bar
        }

        StyledWindow {
            id: win

            screen: scope.modelData
            name: "drawers"
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            mask: Region {
                x: Config.border.thickness
                y: bar.implicitHeight
                width: win.width - Config.border.thickness * 2
                height: win.height - bar.implicitHeight - Config.border.thickness
                intersection: Intersection.Xor

                regions: regions.instances
            }

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Variants {
                id: regions

                model: panels.children

                Region {
                    required property Item modelData

                    x: modelData.x + Config.border.thickness
                    y: modelData.y + bar.implicitHeight
                    width: modelData.width
                    height: modelData.height
                    intersection: Intersection.Subtract
                }
            }

            HyprlandFocusGrab {
                active: (visibilities.launcher && Config.launcher.enabled) || (visibilities.session && Config.session.enabled)
                windows: [win]
                onCleared: {
                    visibilities.launcher = false;
                    visibilities.session = false;
                }
            }

            StyledRect {
                anchors.fill: parent
                opacity: visibilities.session && Config.session.enabled ? 0.5 : 0
                color: Colours.palette.m3scrim

                Behavior on opacity {
                    Anim {}
                }
            }

            Item {
                anchors.fill: parent
                opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    blurMax: 15
                    shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.7)
                }

                Border {
                    bar: bar
                }

                Backgrounds {
                    panels: panels
                    bar: bar
                }
            }

            PersistentProperties {
                id: visibilities

                property bool bar
                property bool osd
                property bool session
                property bool launcher
                property bool dashboard
                property bool utilities

                Component.onCompleted: Visibilities.load(scope.modelData, this)
            }

            Interactions {
                screen: scope.modelData
                popouts: panels.popouts
                visibilities: visibilities
                panels: panels
                bar: bar

                // FIXME: remove when Hyprland bug fixed
                Item {
                    anchors.fill: parent
                    anchors.rightMargin: 1
                    anchors.bottomMargin: 1

                    Panels {
                        id: panels

                        screen: scope.modelData
                        visibilities: visibilities
                        bar: bar
                    }

                    BarWrapper {
                        id: bar

                        anchors.left: parent.left
                        anchors.right: parent.right

                        screen: scope.modelData
                        visibilities: visibilities
                        popouts: panels.popouts

                        Component.onCompleted: Visibilities.bars.set(scope.modelData, this)
                    }
                }
            }
        }
    }
}
