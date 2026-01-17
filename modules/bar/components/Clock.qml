pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

Row {
    id: root

    property color colour: Colours.palette.m3tertiary

    spacing: Appearance.spacing.small

    Loader {
        anchors.verticalCenter: parent.verticalCenter

        active: Config.bar.clock.showIcon
        visible: active

        sourceComponent: MaterialIcon {
            text: "calendar_month"
            color: root.colour
        }
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
