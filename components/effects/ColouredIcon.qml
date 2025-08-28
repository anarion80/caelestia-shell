pragma ComponentBehavior: Bound

import Caelestia
import Quickshell.Widgets
import QtQuick

IconImage {
    id: root

    required property color colour
    property color dominantColour

    asynchronous: true

    layer.enabled: true
    layer.effect: Colouriser {
        sourceColor: root.dominantColour
        colorizationColor: root.colour
    }

    layer.onEnabledChanged: {
        if (layer.enabled && status === Image.Ready)
            CUtils.getDominantColour(this, c => dominantColour = c);
    }

    onStatusChanged: {
        if (layer.enabled && status === Image.Ready)
            CUtils.getDominantColour(this, c => dominantColour = c);
    }
}
