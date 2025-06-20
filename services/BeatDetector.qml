pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real bpm

    Process {
        running: true
        command: [`${Quickshell.configDir}/assets/realtime-beat-detector.py`]
        stdout: SplitParser {
            onRead: data => root.bpm = parseFloat(data)
        }
    }
}
