import QtQuick
import QtQuick.Shapes
import qs.config
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.session as Session
import qs.modules.sidebar as Sidebar
import qs.modules.utilities as Utilities
import qs.modules.bar.popouts as BarPopouts

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.topMargin: bar.implicitHeight
    preferredRendererType: Shape.CurveRenderer

    Osd.Background {
        wrapper: root.panels.osd // qmllint disable incompatible-type

        startX: root.width - root.panels.session.width - root.panels.sidebar.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Notifications.Background {
        wrapper: root.panels.notifications // qmllint disable incompatible-type
        sidebar: sidebar

        startX: root.width + 1
        startY: -1
    }

    Session.Background {
        wrapper: root.panels.session // qmllint disable incompatible-type

        startX: root.width - root.panels.sidebar.width
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: root.panels.launcher // qmllint disable incompatible-type

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height + 1
    }

    Dashboard.Background {
        wrapper: root.panels.dashboard // qmllint disable incompatible-type

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: -1
    }

    BarPopouts.Background {
        wrapper: root.panels.popouts // qmllint disable incompatible-type
        invertBottomRounding: wrapper.x + wrapper.width + 1 >= root.width

        startX: wrapper.x - rounding * sideRounding
        startY: wrapper.y - 1
    }

    Utilities.Background {
        wrapper: root.panels.utilities // qmllint disable incompatible-type
        sidebar: sidebar

        startX: root.width
        startY: root.height
    }

    Sidebar.Background {
        id: sidebar

        wrapper: root.panels.sidebar // qmllint disable incompatible-type
        panels: root.panels

        startX: root.width
        startY: root.panels.notifications.height
    }
}
