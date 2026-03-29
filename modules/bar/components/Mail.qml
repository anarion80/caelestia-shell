pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.components.misc
import qs.services
import qs.config

Item {
    id: root

    implicitWidth: Config.bar.mail.enabled ? icon.implicitHeight + mailText.implicitHeight + Appearance.padding.small * 2 : 0
    implicitHeight: Config.bar.mail.enabled ? icon.implicitHeight + mailText.implicitHeight : 0
    visible: Config.bar.mail.enabled
    enabled: Config.bar.mail.enabled

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        function onClicked(): void {
            Quickshell.execDetached(["ghostty", "--title=NeomuttFloat", "-e", "neomutt"]);
        }

        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: root.implicitWidth + Appearance.padding.small * 2
        implicitHeight: icon.implicitHeight + Appearance.padding.small * 2

        radius: Appearance.rounding.full
    }

    Row {
        id: row

        spacing: Appearance.spacing.small
        anchors.verticalCenter: parent.verticalCenter

        Ref {
            service: MailService
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
            text: qsTr("%1").arg(MailService.unreadEmails.length ?? "N/A")
            font.pointSize: Appearance.font.size.smaller
            font.family: Appearance.font.family.mono
            color: Colours.palette.m3tertiary
        }
    }
}
