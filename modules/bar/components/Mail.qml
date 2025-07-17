import qs.widgets
import qs.services
import qs.config
import QtQuick

Row {
    id: root

    property color colour: Colours.palette.m3tertiary

    spacing: Appearance.spacing.small
    
    Ref {
            service: Mail
        }

    MaterialIcon {
        id: icon

        text: "mail"
        color: root.colour

        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        id: text

        anchors.verticalCenter: parent.verticalCenter

        verticalAlignment: StyledText.AlignVCenter
        text: `${Math.ceil(Mail.unreadMail)}`
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        color: root.colour
    }
}
