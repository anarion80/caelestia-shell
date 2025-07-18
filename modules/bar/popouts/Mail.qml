import qs.widgets
import qs.services
import qs.config
import Quickshell
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal

    Repeater {
        model: ScriptModel {
            values: Mail.unreadEmails.filter(p => p)
        }

        Row {
            id: emails

            required property var modelData

            spacing: Appearance.spacing.small

            MaterialIcon {
                id: icon
                animate: true

                text: "mail"
                color: Colours.palette.m3onSurface
            }

            StyledText {
                id: text
                text: qsTr("%1").arg(modelData ?? "None")
            }
        }
    }
}
