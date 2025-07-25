import Quickshell.Io

JsonObject {
    property bool persistent: true
    property bool showOnHover: true
    property int dragThreshold: 20
    property Workspaces workspaces: Workspaces {}
    property Sizes sizes: Sizes {}

    component Workspaces: JsonObject {
        property int shown: 8
        property bool rounded: true
        property bool activeIndicator: true
        property bool occupiedBg: true
        property bool showWindows: true
        property bool activeTrail: true
        property string label: "  "
        property string occupiedLabel: "󰮯 "
        property string activeLabel: "󰮯 "
    }

    component Sizes: JsonObject {
        property int innerHeight: 30
        property int windowPreviewSize: 400
        property int trayMenuWidth: 300
        property int batteryWidth: 250
    }
}
