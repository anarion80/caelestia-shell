import qs.widgets
import qs.services
import qs.config
import QtQuick
import Quickshell

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: implicitHeight
    // property real radius: Appearance.rounding.large
    property color colour: Colours.palette.m3tertiary

    Row {
        id: row

        spacing: Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter


        Ref {
            service: Mail
        }

        MaterialIcon {
            id: icon
            animate: true

            text: "mail"
            color: root.colour

            anchors.verticalCenter: parent.verticalCenter

        }

        StyledText {
            id: mailText

            anchors.verticalCenter: parent.verticalCenter

            verticalAlignment: StyledText.AlignVCenter
            text: qsTr("%1").arg(Mail.unreadEmails.length ?? "N/A")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: root.colour
          }
    }
   
    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: root
        anchors.horizontalCenterOffset: 1

        implicitWidth: implicitHeight
        implicitHeight: root.implicitWidth + Appearance.padding.small * 2

        radius: Appearance.rounding.full
        hoverEnabled: false

        function onClicked(): void {
            // root.visibilities.session = !root.visibilities.session;
            Quickshell.execDetached(["ghostty", "--title=NeomuttFloat", "-e", "neomutt"]);
        }
    }


    // MouseArea {
    //     id: mousearea
    //
    //     property bool disabled
    //     property color color: Colours.palette.m3onSurface
    //     property real radius: Appearance.rounding.full
    //     // property real radius: parent?.radius ?? 0
    //         anchors.centerIn: root
    //         anchors.horizontalCenterOffset: 1
    //
    //         // implicitWidth: implicitHeight
    //         implicitHeight: root.implicitWidth + Appearance.padding.small * 2
    //
    //         implicitWidth: root.implicitWidth + Appearance.padding.normal * 2
    //     function onClicked(): void {
    //         Quickshell.execDetached(["ghostty", "--title=NeomuttFloat", "-e", "neomutt"]);
    //     }
    //
    //     anchors.fill: undefined
    //     // radius: Appearance.rounding.full
    //
    //     cursorShape: disabled ? undefined : Qt.PointingHandCursor
    //     // hoverEnabled: true
    //
    //     onPressed: event => {
    //         if (disabled)
    //             return;
    //
    //         rippleAnim.x = event.x;
    //         rippleAnim.y = event.y;
    //
    //         const dist = (ox, oy) => ox * ox + oy * oy;
    //         rippleAnim.radius = Math.sqrt(Math.max(dist(event.x, event.y), dist(event.x, height - event.y), dist(width - event.x, event.y), dist(width - event.x, height - event.y)));
    //
    //         rippleAnim.restart();
    //     }
    //
    //     onClicked: event => !disabled && onClicked(event)
    //
    //     SequentialAnimation {
    //         id: rippleAnim
    //
    //         property real x
    //         property real y
    //         property real radius
    //
    //         PropertyAction {
    //             target: ripple
    //             property: "x"
    //             value: rippleAnim.x
    //         }
    //         PropertyAction {
    //             target: ripple
    //             property: "y"
    //             value: rippleAnim.y
    //         }
    //         PropertyAction {
    //             target: ripple
    //             property: "opacity"
    //             value: 0.08
    //         }
    //         Anim {
    //             target: ripple
    //             properties: "implicitWidth,implicitHeight"
    //             from: 0
    //             to: rippleAnim.radius * 2
    //             duration: Appearance.anim.durations.normal
    //             easing.bezierCurve: Appearance.anim.curves.standardDecel
    //         }
    //         Anim {
    //             target: ripple
    //             property: "opacity"
    //             to: 0
    //             duration: Appearance.anim.durations.normal
    //             easing.type: Easing.BezierSpline
    //             easing.bezierCurve: Appearance.anim.curves.standard
    //         }
    //     }
    //
    //     StyledClippingRect {
    //         id: hoverLayer
    //
    //         anchors.fill: parent
    //
    //         color: Qt.alpha(mousearea.color, mousearea.disabled ? 0 : mousearea.pressed ? 0.1 : mousearea.containsMouse ? 0.08 : 0)
    //         radius: mousearea.radius
    //
    //         StyledRect {
    //             id: ripple
    //
    //             // radius: Appearance.rounding.full
    //             color: mousearea.color
    //             opacity: 0
    //
    //             transform: Translate {
    //                 x: -ripple.width / 2
    //                 y: -ripple.height / 2
    //             }
    //         }
    //     }
    //
    //     component Anim: NumberAnimation {
    //         duration: Appearance.anim.durations.normal
    //         easing.type: Easing.BezierSpline
    //         easing.bezierCurve: Appearance.anim.curves.standard
    //     }
    // }
}
