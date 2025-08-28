pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real bpm: 150

    Process {
        running: true
        command: [`${Paths.libdir}/beat_detector`, "--no-log", "--no-stats", "--no-visual"]
        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/BPM: ([0-9]+\.[0-9])/);
                if (match)
                    root.bpm = parseFloat(match[1]);
            }
        }
    }
}
