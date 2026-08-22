pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.misc
import qs.services
import Caelestia.Config
import qs.utils

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    readonly property alias items: mailRow

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: Config.bar.mail.enabled ? mailRow.implicitWidth + Tokens.padding.medium * 2 : 0
    implicitHeight: Config.bar.mail.enabled ? Tokens.sizes.bar.innerHeight : 0
    visible: Config.bar.mail.enabled
    enabled: Config.bar.mail.enabled

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        onClicked: Quickshell.execDetached(Config.bar.mail.clickCommand)

        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        radius: Tokens.rounding.full
    }

    RowLayout {
        id: mailRow

        anchors.centerIn: parent
        anchors.rightMargin: Tokens.padding.medium

        spacing: 0

        Ref {
            service: MailService
        }

        WrappedLoader {
            name: "mail"
            active: root.visible

            sourceComponent: MaterialIcon {
                animate: true
                text: Icons.getMailIcon(MailService.unreadEmails.length)
                color: root.colour
            }
        }

        StyledText {
            id: mailText

            visible: Config.bar.mail.showNumber && MailService.unreadEmails.length > 0

            Layout.alignment: Qt.AlignVCenter

            text: qsTr("%1").arg(MailService.unreadEmails.length)
            font: Tokens.font.body.small
            color: Colours.palette.m3tertiary
        }
    }

    component WrappedLoader: Loader {
        required property string name

        asynchronous: true
        Layout.alignment: Qt.AlignVCenter
        visible: active
    }
}
