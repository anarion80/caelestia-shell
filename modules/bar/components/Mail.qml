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
