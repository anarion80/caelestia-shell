pragma ComponentBehavior: Bound

import "root:/widgets"
import "root:/services"
import "root:/utils"
import "root:/config"
import QtQuick

Item {
    id: root

    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary
    readonly property Item child: child

    implicitWidth: child.implicitWidth
    implicitHeight: child.implicitHeight

    MouseArea {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: child.left

        onWheel: event => {
            if (event.angleDelta.y > 0)
                Audio.setVolume(Audio.volume + 0.1);
            else if (event.angleDelta.y < 0)
                Audio.setVolume(Audio.volume - 0.1);
        }
    }

    // MouseArea {
    //     anchors.top: parent.top
    //     anchors.bottom: parent.bottom
    //     anchors.left: child.right
    //     anchors.right: parent.right
    //
    //     onWheel: event => {
    //         const monitor = root.monitor;
    //         if (event.angleDelta.y > 0)
    //             monitor.setBrightness(monitor.brightness + 0.1);
    //         else if (event.angleDelta.y < 0)
    //             monitor.setBrightness(monitor.brightness - 0.1);
    //     }
    // }

    Item {
        id: child

        property Item current: text1

        anchors.centerIn: parent

        clip: true
        implicitWidth: icon.implicitWidth + current.implicitWidth + current.anchors.leftMargin
        // implicitWidth: 400 
        implicitHeight: Math.max(icon.implicitHeight, current.implicitHeight)

        MaterialIcon {
            id: icon

            animate: true
            text: Icons.getAppCategoryIcon(Hyprland.activeClient?.wmClass, "desktop_windows")
            color: root.colour

            anchors.verticalCenter: parent.verticalCenter
        }

        Title {
            id: text1
        }

        Title {
            id: text2
        }

        TextMetrics {
            id: metrics

            text: Hyprland.activeClient?.title ?? qsTr("Desktop")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            elide: Qt.ElideRight
            elideWidth: BarConfig.sizes.activeWindowWidth - icon.width

            onTextChanged: {
                const next = child.current === text1 ? text2 : text1;
                next.text = elidedText;
                child.current = next;
            }
            onElideWidthChanged: child.current.text = elidedText
        }

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.emphasized
            }
        }
    }

    component Title: StyledText {
        id: text

        anchors.verticalCenter: icon.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: Appearance.spacing.small

        font.pointSize: metrics.font.pointSize
        font.family: metrics.font.family
        color: root.colour
        opacity: child.current === this ? 1 : 0

        // transform: Rotation {
        //     angle: 90
        //     origin.x: text.implicitHeight / 2
        //     origin.y: text.implicitHeight / 2
        // }

        width: implicitWidth
        height: implicitHeight

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
}
