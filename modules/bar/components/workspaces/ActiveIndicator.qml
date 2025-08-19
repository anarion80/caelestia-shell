import qs.components
import qs.components.effects
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    required property int activeWsId
    required property Repeater workspaces
    required property Item mask

    readonly property int currentWsIdx: (activeWsId - 1) % Config.bar.workspaces.shown

    property real leading: workspaces.itemAt(currentWsIdx)?.y ?? 0
    property real trailing: workspaces.itemAt(currentWsIdx)?.y ?? 0
    property real currentSize: workspaces.itemAt(currentWsIdx)?.size ?? 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && lastWs > currentWsIdx) {
            const ws = workspaces.itemAt(lastWs);
            // console.log(ws, lastWs);
            return ws ? Math.min(ws.y + ws.size - offset, s) : 0;
        }
        return s;
    }

    property int cWs
    property int lastWs

    onCurrentWsIdxChanged: {
        lastWs = cWs;
        cWs = currentWsIdx;
    }

    clip: true
    x: offset + mask.x
    implicitWidth: size
    implicitHeight: Config.bar.sizes.innerHeight - Appearance.padding.small * 2
    radius: Appearance.rounding.full
    color: Colours.palette.m3primary

    Colouriser {
        source: root.mask
        sourceColor: Colours.palette.m3onSurface
        colorizationColor: Colours.palette.m3onPrimary

        x: -parent.offset
        y: 0
        implicitWidth: root.mask.implicitWidth
        implicitHeight: root.mask.implicitHeight

        anchors.verticalCenter: parent.verticalCenter
    }

    Behavior on leading {
        enabled: Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on trailing {
        enabled: Config.bar.workspaces.activeTrail

        Anim {
            duration: Appearance.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on offset {
        enabled: !Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on size {
        enabled: !Config.bar.workspaces.activeTrail

        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
