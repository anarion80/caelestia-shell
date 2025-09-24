pragma Singleton

import qs.services
import qs.config
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property alias enabled: props.enabled

    function setDynamicConfs(): void {
        Hypr.message("[[BATCH]]keyword animations:enabled 0;keyword decoration:shadow:enabled 0;keyword decoration:blur:enabled 0;keyword general:gaps_in 0;keyword general:gaps_out 0;keyword general:border_size 1;keyword decoration:rounding 0;keyword general:allow_tearing 1");
    }

    onEnabledChanged: {
        if (enabled) {
            setDynamicConfs();
            if (Config.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled Hyprland animations, blur, gaps and shadows"), "gamepad");
        } else {
            Hypr.message("reload");
            if (Config.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: Hypr.options["animations:enabled"] === 0

        reloadableId: "gameMode"
    }

    Connections {
        target: Hypr

        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }
    }

    IpcHandler {
        target: "gameMode"

        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }
    }
}
