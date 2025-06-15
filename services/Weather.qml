pragma Singleton

import "root:/utils"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string loc
    property string icon
    property string description
    property real temperature

    function reload(): void {
        wttrProc.running = true;
    }

    onLocChanged: wttrProc.running = true

    Process {
        id: ipProc

        running: true
        command: ["curl", "ipinfo.io"]
        stdout: StdioCollector {
            onStreamFinished: root.loc = JSON.parse(text).loc
        }
    }

    Process {
        id: wttrProc

        command: ["curl", `https://wttr.in/${root.loc}?format=j1`]
        stdout: StdioCollector {
            onStreamFinished: {
                const json = JSON.parse(text).current_condition[0];
                root.icon = Icons.getWeatherIcon(json.weatherCode);
                root.description = json.weatherDesc[0].value;
                root.temperature = parseFloat(json.temp_C);
            }
        }
    }
}
