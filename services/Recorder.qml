pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property alias running: props.running
    readonly property alias paused: props.paused

    function toggle(): void {
        Quickshell.execDetached(["caelestia", "record"]);
        props.running = !props.running;
        if (!props.running)
            props.paused = false;
    }

    function togglePause(): void {
        Quickshell.execDetached(["caelestia", "record", "-p"]);
        props.paused = !props.paused;
    }

    PersistentProperties {
        id: props

        property bool running: false
        property bool paused: false

        reloadableId: "recorder"
    }

    Process {
        running: true
        command: ["pidof", "gpu-screen-recorder"]
        onExited: code => props.running = code === 0
    }
}
