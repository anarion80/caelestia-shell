pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property alias enabled: props.enabled

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "idleInhibitor"
    }

    Process {
        running: root.enabled
        command: ["systemd-inhibit", "--what=idle", "--who=caelestia-shell", "--why=Idle inhibitor active", "--mode=block", "sleep", "inf"]
    }

    IpcHandler {
        target: "idleInhibitor"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }
    }
}
