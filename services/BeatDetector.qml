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
            onRead: data => {
                const match = data.match(/BPM: ([0-9]+\.[0-9])/);
                if (match)
                    root.bpm = parseFloat(match[1]);
            }
        }
    }
}
