import ".."
import qs.services
import qs.config
import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root

    leftPadding: 0

    contentItem: StyledRect {
        x: 0
        implicitWidth: 6
        opacity: root.pressed ? 1 : mouse.containsMouse ? 0.8 : root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1) ? 0.6 : 0
        radius: Appearance.rounding.full
        color: Colours.palette.m3secondary

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Behavior on opacity {
            Anim {}
        }
    }

    CustomMouseArea {
        z: -1
        anchors.fill: parent

        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrease();
            else if (event.angleDelta.y < 0)
                root.increase();
        }
    }
}
