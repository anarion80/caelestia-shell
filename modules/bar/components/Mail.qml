import qs.components
import qs.components.misc
import qs.services
import qs.config
import Quickshell
import QtQuick

Item {
    id: root

    implicitWidth: icon.implicitHeight + mailText.implicitHeight + Appearance.padding.small * 2
    implicitHeight: icon.implicitHeight + mailText.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: root.implicitWidth + Appearance.padding.small * 2
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full

        function onClicked(): void {
            Quickshell.execDetached(["ghostty", "--title=NeomuttFloat", "-e", "neomutt"]);
        }
    }

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
            color: Colours.palette.m3tertiary

            anchors.verticalCenter: parent.verticalCenter

        }

        StyledText {
            id: mailText

            anchors.verticalCenter: parent.verticalCenter

            verticalAlignment: StyledText.AlignVCenter
            text: qsTr("%1").arg(Mail.unreadEmails.length ?? "N/A")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
        }
    }
}
