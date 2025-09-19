import "lock"
import qs.config
import qs.services
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    required property Lock lock
    readonly property bool enabled: !Config.general.idle.inhibitWhenAudio || !Players.list.some(p => p.isPlaying)

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.general.idle.lockTimeout
        onIsIdleChanged: {
            if (isIdle)
                root.lock.lock.locked = true;
        }
    }

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.general.idle.dpmsTimeout
        onIsIdleChanged: {
            if (isIdle)
                Hypr.dispatch("dpms off");
            else
                Hypr.dispatch("dpms on");
        }
    }

    IdleMonitor {
        enabled: root.enabled
        timeout: Config.general.idle.sleepTimeout
        onIsIdleChanged: {
            if (isIdle)
                Quickshell.execDetached(["systemctl", "suspend-then-hibernate"]);
        }
    }
}
