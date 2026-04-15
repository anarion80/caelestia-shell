pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services
import Caelestia.Config

Column {
    id: root

    spacing: Tokens.spacing.normal
    visible: MailService.unreadEmails.length > 0

    Repeater {
        model: ScriptModel {
            values: MailService.unreadEmails.slice(0, Math.min(GlobalConfig.bar.mail.emailsShown, 15))
        }

        Row {
            id: emails

            required property var modelData

            spacing: Tokens.spacing.small

            MaterialIcon {
                id: icon

                animate: true

                text: "mail"
                color: Colours.palette.m3onSurface
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: emails.modelData?.author + ": " ?? ""
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: emails.modelData?.subject ?? ""
                font.italic: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
