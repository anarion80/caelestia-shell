import qs.components
import qs.services
import qs.config
import QtQuick

Row {
    id: root

    property color colour: Colours.palette.m3tertiary

    spacing: Appearance.spacing.small

    MaterialIcon {
        id: icon

        text: "schedule"
        color: root.colour

        anchors.verticalCenter: parent.verticalCenter
    }

    StyledText {
        id: text

        anchors.verticalCenter: parent.verticalCenter

        verticalAlignment: StyledText.AlignVCenter
        text: Time.format(Config.services.useTwelveHourClock ? "hh:mm A" : "hh:mm")
        font.pointSize: Appearance.font.size.smaller
        font.family: Appearance.font.family.mono
        color: root.colour
    }
}
