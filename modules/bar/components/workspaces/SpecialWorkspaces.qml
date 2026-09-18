pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Item {
    id: root

    required property HyprlandMonitor monitor

    readonly property int activeSpecialId: monitor?.lastIpcObject.specialWorkspace?.id ?? 0
    readonly property var wsIds: {
        const allMonitors = !Config.bar.workspaces.perMonitor;
        return Hypr.workspaces.values.filter(w => w.name.startsWith("special:") && (allMonitors || w.monitor === root.monitor)).map(w => w.id);
    }
    readonly property int activeIdx: wsIds.indexOf(activeSpecialId)
    readonly property real maxViewX: Math.max(0, view.contentWidth - width)

    readonly property Workspace activeWs: {
        view.itemsDirty;
        return view.itemAtIndex(activeIdx) as Workspace;
    }

    function ensureVisible(animate = true): void {
        if (!activeWs)
            return;

        const left = activeWs.LazyListView.layoutX;
        const right = left + activeWs.LazyListView.preferredWidth;

        let target = view.x;
        if (left < -target)
            target = -left;
        else if (right > -target + width)
            target = -(right - width);

        target = CUtils.clamp(target, -maxViewX, 0);
        if (target !== view.x) {
            if (animate) {
                const type = viewXAnim.type;
                viewXAnim.type = Anim.DefaultSpatial;
                view.x = target;
                viewXAnim.type = type;
            } else {
                viewXBehavior.enabled = false;
                view.x = target;
                viewXBehavior.enabled = true;
            }
        }
    }

    onActiveWsChanged: ensureVisible()
    onWidthChanged: ensureVisible(false)
    Component.onCompleted: ensureVisible(false)
    onMaxViewXChanged: ensureVisible()

    layer.enabled: true
    layer.effect: Mask {
        maskSource: mask
    }

    Connections {
        function onLayoutXChanged(): void {
            root.ensureVisible();
        }

        function onPreferredWidthChanged(): void {
            root.ensureVisible();
        }

        target: root.activeWs?.LazyListView ?? null
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.full

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Qt.rgba(0, 0, 0, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0, 0, 0, 1)
                }
                GradientStop {
                    position: 0.8
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

            radius: Tokens.rounding.full
            implicitWidth: parent.width / 2
            opacity: view.x < -Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            radius: Tokens.rounding.full
            implicitWidth: parent.width / 2
            opacity: view.x > -root.maxViewX + Tokens.padding.extraSmall ? 0 : 1

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    LazyListView {
        id: view

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        implicitWidth: contentWidth

        orientation: Qt.Horizontal

        cullDelegates: false
        spacing: Tokens.spacing.small
        removeDuration: Tokens.anim.durations.expressiveDefaultEffects

        onContentWidthChanged: root.ensureVisible()

        model: ScriptModel {
            values: root.wsIds
        }

        delegate: Workspace {
            activeWsId: root.activeSpecialId
            ws: modelData
            monitor: root.monitor
            offMonitorColour: Colours.palette.m3outline
            displayType: Config.bar.workspaces.specialDisplayType
            showWindows: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            iconRules: GlobalConfig.bar.workspaces.specialWorkspaceIcons
        }

        Behavior on x {
            id: viewXBehavior

            Anim {
                id: viewXAnim

                type: Anim.FastEffects
            }
        }
    }

    Loader {
        asynchronous: true
        anchors.top: view.top
        anchors.bottom: view.bottom
        active: Config.bar.workspaces.activeIndicator

        sourceComponent: ActiveIndicator {
            activeWs: root.activeWs
            mask: view
            color: Colours.palette.m3tertiary
            contentColour: Colours.palette.m3onTertiary
        }
    }

    MouseArea {
        property real startX
        property real startViewX
        property bool dragging

        anchors.fill: parent

        onPressed: event => {
            startX = event.x;
            startViewX = view.x;
            dragging = false;
        }

        onPositionChanged: event => {
            if (!dragging && Math.abs(event.x - startX) > drag.threshold)
                dragging = true;

            if (dragging)
                view.x = CUtils.clamp(startViewX + (event.x - startX), -root.maxViewX, 0);
        }

        onClicked: event => {
            if (dragging)
                return;

            const ws = view.itemAt(event.x - view.x, event.y) as Workspace;
            if (ws) {
                const match = Hypr.workspaces.values.find(w => w.id === ws.ws);
                if (match)
                    Hypr.toggleSpecial(Hypr.trimWsName(match.name));
            } else {
                Hypr.toggleSpecial("special");
            }
        }
    }
}
