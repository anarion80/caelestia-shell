pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)

    function fontFor(text: string, metricWidth: int): font {
        // We don't count seconds for the max width because it changes too often
        const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.height, minMetrics.height) / metricWidth);
        return root.font.width(scale * 100).letterSpacing(scale).build();
    }

    implicitWidth: layout.implicitWidth + root.padding * 2
    implicitHeight: Tokens.sizes.bar.innerHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    RowLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showDate
            visible: active

            sourceComponent: RowLayout {
                spacing: layout.spacing

                StyledText {
                    id: dateText

                    Layout.alignment: Qt.AlignVCenter
                    text: Time.format("ddd")
                    font: root.font.build()
                    color: root.colour
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: Time.format("d")
                    font: root.font.build()
                    color: root.colour
                }
            }
        }

        StyledRect {
            visible: Config.bar.clock.showDate
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 1
            implicitHeight: hourMetrics.height
            color: Qt.alpha(root.colour, 0.5)
        }

        StyledText {
            id: hourText

            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 0
            text: Time.hourStr
            font: root.fontFor(text, hourMetrics.width)
            color: root.colour

            TextMetrics {
                id: hourMetrics

                font: root.font.build()
                text: Time.hourStr
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: -parent.spacing
            Layout.rightMargin: -parent.spacing
            text: ":"
            font: root.font.build()
            color: root.colour
        }

        StyledText {
            Layout.leftMargin: -parent.spacing
            Layout.rightMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignVCenter
            text: Time.minuteStr
            font: root.fontFor(text, minMetrics.width)
            color: root.colour

            TextMetrics {
                id: minMetrics

                font: root.font.build()
                text: Time.minuteStr
            }
        }

        Loader {
            Layout.rightMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignVCenter
            asynchronous: true
            active: Config.bar.clock.showSeconds
            visible: active

            sourceComponent: StyledText {
                text: Time.format("ss")
                font: root.fontFor(text, secMetrics.width)
                color: root.colour

                TextMetrics {
                    id: secMetrics

                    font: root.font.build()
                    text: Time.format("ss")
                }
            }
        }

        Loader {
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.body.builders.small.scale(0.9).build()
                color: root.colour
            }
        }
    }
}
