pragma ComponentBehavior: Bound

import qs.widgets
import qs.config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Appearance.spacing.small / 2

    StyledText {
        Layout.bottomMargin: Appearance.spacing.small
        text: qsTr("Bluetooth %1").arg(BluetoothAdapterState.toString(Bluetooth.defaultAdapter.state).toLowerCase())
    }

    StyledText {
        text: qsTr("%n connected device(s)", "", Bluetooth.devices.values.filter(d => d.connected).length)
    }

    Repeater {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
        }

        RowLayout {
            id: device

            required property var modelData
            readonly property bool loading: device.modelData.state === BluetoothDeviceState.Connecting || device.modelData.state === BluetoothDeviceState.Disconnecting

            Layout.fillWidth: true
            spacing: Appearance.spacing.small / 2

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                Layout.rightMargin: Appearance.spacing.small
                text: Icons.getBluetoothIcon(device.modelData.icon)
            }

            StyledText {
                Layout.fillWidth: true
                text: device.modelData.name
            }

            Item {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Appearance.padding.small * 2

                StyledBusyIndicator {
                    anchors.centerIn: parent

                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight

                    running: opacity > 0
                    opacity: device.loading ? 1 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StateLayer {
                    radius: Appearance.rounding.full
                    disabled: device.loading

                    function onClicked(): void {
                        device.modelData.connected = !device.modelData.connected;
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: device.modelData.connected ? "link_off" : "link"

                    opacity: device.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }

            Loader {
                asynchronous: true
                active: device.modelData.paired
                sourceComponent: Item {
                    implicitWidth: connectBtn.implicitWidth
                    implicitHeight: connectBtn.implicitHeight

                    StateLayer {
                        radius: Appearance.rounding.full

                        function onClicked(): void {
                            device.modelData.forget();
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete"
                    }
                }
            }
        }
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.standard
    }
}
