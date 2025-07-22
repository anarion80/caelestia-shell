import qs.widgets
import qs.services
import qs.config
import QtQuick
import Quickshell

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: implicitHeight
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
            Quickshell.execDetached(["ghostty", "--title=NeomuttFloat", "-e", "neomutt"]);
        }
    }
}
