pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Mail")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: Tr.tr("Enabled")
            subtext: Tr.tr("Show the mail indicator in the bar")
            checked: Config.bar.mail.enabled
            onToggled: GlobalConfig.bar.mail.enabled = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: Tr.tr("Show number")
            subtext: Tr.tr("Display the unread email count")
            checked: Config.bar.mail.showNumber
            onToggled: GlobalConfig.bar.mail.showNumber = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: Tr.tr("Emails shown")
            subtext: Tr.tr("Maximum emails shown in the popout")
            value: Config.bar.mail.emailsShown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.mail.emailsShown = v
        }
    }
}
