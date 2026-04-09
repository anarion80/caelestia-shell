pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.modules.bar as Bar

Region {
    id: root

    required property Bar.BarWrapper bar
    required property Panels panels
    required property var win

    x: Config.border.clampedThickness + win.dragMaskPadding
    y: bar.clampedHeight + win.dragMaskPadding
    width: win.width - Config.border.clampedThickness * 2 - win.dragMaskPadding * 2
    height: win.height - bar.clampedHeight - Config.border.clampedThickness - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + Config.border.thickness
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + Config.border.thickness
    }

    R {
        id: sessionRegion

        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + Config.border.thickness + sidebarRegion.width
    }

    R {
        id: sidebarRegion

        panel: root.panels.sidebar
        x: root.win.width - width
        width: panel.width * (1 - root.panels.sidebar.offsetScale) + Config.border.thickness
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + Config.border.thickness + sessionRegion.width
    }

    R {
        panel: root.panels.notifications
        y: 0
        height: panel.height + Config.border.thickness
    }

    R {
        panel: root.panels.utilities
        y: root.win.height - height
        height: panel.height * (1 - root.panels.utilities.offsetScale) + Config.border.thickness
    }

    R {
        panel: root.panels.popoutsWrapper
        height: panel.height * (1 - root.panels.popoutsWrapper.offsetScale)
    }

    component R: Region {
        required property Item panel

        x: panel.x + Config.border.thickness
        y: panel.y + root.bar.implicitHeight
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
