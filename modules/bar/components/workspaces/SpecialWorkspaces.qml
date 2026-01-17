pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import qs.utils
import qs.config
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property string activeSpecial: (Config.bar.workspaces.perMonitorWorkspaces ? monitor : Hypr.focusedMonitor)?.lastIpcObject?.specialWorkspace?.name ?? ""

    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: mask
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.full

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.3
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.7
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0, 0, 0, 0)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom

            radius: Appearance.rounding.full
            implicitWidth: parent.width / 2
            opacity: view.contentX > 0 ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            radius: Appearance.rounding.full
            implicitWidth: parent.width / 2
            opacity: view.contentX < view.contentWidth - parent.width + Appearance.padding.small ? 0 : 1

            Behavior on opacity {
                Anim {}
            }
        }
    }

    ListView {
        id: view

        anchors.fill: parent
        spacing: Appearance.spacing.normal
        interactive: false
        orientation: ListView.Horizontal

        currentIndex: model.values.findIndex(w => w.name === root.activeSpecial)
        onCurrentIndexChanged: currentIndex = Qt.binding(() => model.values.findIndex(w => w.name === root.activeSpecial))

        model: ScriptModel {
            values: Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (!Config.bar.workspaces.perMonitorWorkspaces || w.monitor === root.monitor))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: width
        highlightRangeMode: ListView.StrictlyEnforceRange

        highlightFollowsCurrentItem: false
        highlight: Item {
            x: view.currentItem?.x ?? 0
            implicitWidth: view.currentItem?.size ?? 0

            Behavior on x {
                Anim {}
            }
        }

        delegate: RowLayout {
            id: ws

            required property HyprlandWorkspace modelData
            readonly property int size: label.Layout.preferredWidth + (hasWindows ? windows.implicitWidth + Appearance.padding.small : 0)
            property int wsId
            property string icon
            property bool hasWindows

            anchors.top: view.contentItem.top
            anchors.bottom: view.contentItem.bottom

            spacing: 0

            Component.onCompleted: {
                wsId = modelData.id;
                icon = Icons.getSpecialWsIcon(modelData.name);
                hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && modelData.lastIpcObject.windows > 0;
            }

            // Hacky thing cause modelData gets destroyed before the remove anim finishes
            Connections {
                target: ws.modelData

                function onIdChanged(): void {
                    if (ws.modelData)
                        ws.wsId = ws.modelData.id;
                }

                function onNameChanged(): void {
                    if (ws.modelData)
                        ws.icon = Icons.getSpecialWsIcon(ws.modelData.name);
                }

                function onLastIpcObjectChanged(): void {
                    if (ws.modelData)
                        ws.hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
                }
            }

            Connections {
                target: Config.bar.workspaces

                function onShowWindowsOnSpecialWorkspacesChanged(): void {
                    if (ws.modelData)
                        ws.hasWindows = Config.bar.workspaces.showWindowsOnSpecialWorkspaces && ws.modelData.lastIpcObject.windows > 0;
                }
            }

            Loader {
                id: label

                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft 
                Layout.preferredWidth: Config.bar.sizes.innerHeight - Appearance.padding.small * 2

                sourceComponent: ws.icon.length === 1 ? letterComp : iconComp

                Component {
                    id: iconComp

                    MaterialIcon {
                        fill: 1
                        text: ws.icon
                        horizontalAlignment: Qt.AlignHCenter
                    }
                }

                Component {
                    id: letterComp

                    StyledText {
                        text: ws.icon
                        horizontalAlignment: Qt.AlignHCenter
                    }
                }
            }

            Loader {
                id: windows

                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.preferredWidth: implicitWidth

                visible: active
                active: ws.hasWindows

                sourceComponent: Row {
                    spacing: 0

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
                            values: Hypr.toplevels.values.filter(c => c.workspace?.id === ws.wsId)
                        }

                        MaterialIcon {
                            required property var modelData

                            grade: 0
                            text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                Behavior on Layout.preferredWidth {
                    Anim {}
                }
            }
        }

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
        }

        remove: Transition {
            Anim {
                property: "scale"
                to: 0.5
                duration: Appearance.anim.durations.small
            }
            Anim {
                property: "opacity"
                to: 0
                duration: Appearance.anim.durations.small
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

        displaced: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing.bezierCurve: Appearance.anim.curves.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    Loader {
        active: Config.bar.workspaces.activeIndicator
        anchors.fill: parent

        sourceComponent: Item {
            StyledClippingRect {
                id: indicator

                anchors.top: parent.top
                anchors.bottom: parent.bottom

                x: (view.currentItem?.x ?? 0) - view.contentX
                implicitWidth: view.currentItem?.size ?? 0

                color: Colours.palette.m3tertiary
                radius: Appearance.rounding.full

                Colouriser {
                    source: view
                    sourceColor: Colours.palette.m3onSurface
                    colorizationColor: Colours.palette.m3onTertiary

                    anchors.verticalCenter: parent.verticalCenter

                    x: -indicator.x
                    y: 0
                    implicitWidth: view.width
                    implicitHeight: view.height
                }

                Behavior on x {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }

                Behavior on implicitWidth {
                    Anim {
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                }
            }
        }
    }

    MouseArea {
        property real startX

        anchors.fill: view

        drag.target: view.contentItem
        drag.axis: Drag.XAxis
        drag.maximumX: 0
        drag.minimumX: Math.min(0, view.width - view.contentWidth - Appearance.padding.small)

        onPressed: event => startX = event.x

        onClicked: event => {
            if (Math.abs(event.x - startX) > drag.threshold)
                return;

            const ws = view.itemAt(event.x, event.y);
            if (ws?.modelData)
                Hypr.dispatch(`togglespecialworkspace ${ws.modelData.name.slice(8)}`);
            else
                Hypr.dispatch("togglespecialworkspace special");
        }
    }
}
