import Quickshell.Io

JsonObject {
    property Apps apps: Apps {}
    property Idle idle: Idle {}

    component Apps: JsonObject {
        property list<string> terminal: ["foot"]
        property list<string> audio: ["pavucontrol"]
        property list<string> playback: ["mpv"]
        property list<string> explorer: ["thunar"]
    }

    component Idle: JsonObject {
        property bool inhibitWhenAudio: true
        property real lockTimeout: 180 // 3 mins
        property real dpmsTimeout: 300 // 5 mins
        property real sleepTimeout: 600 // 10 mins
    }
}
