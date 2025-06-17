import "root:/widgets"
import "root:/services"
import "root:/config"
import QtQuick

StyledText {
    text: Icons.osIcon
    font.pointSize: Appearance.font.size.smaller
    font.family: Appearance.font.family.mono
    color: Colours.palette.m3tertiary
}
// Column {
//     id: root
//
//     spacing: Appearance.spacing.normal
//
//     StyledText {
//         text: qsTr("Connected to: %1").arg(Network.active?.ssid ?? "None")
//     }
//
//     StyledText {
//         text: qsTr("Strength: %1/100").arg(Network.active?.strength ?? 0)
//     }
//
//     StyledText {
//         text: qsTr("Frequency: %1 MHz").arg(Network.active?.frequency ?? 0)
//     }
//
//     StyledText {
//         text: qsTr("BSSID: %1").arg(Network.active?.bssid ?? "None")
//     }
// }
