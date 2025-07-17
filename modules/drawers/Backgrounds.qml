import qs.services
import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.topMargin: bar.implicitHeight
    preferredRendererType: Shape.CurveRenderer
    opacity: Colours.transparency.enabled ? Colours.transparency.base : 1

    Osd.Background {
        wrapper: panels.osd

        startX: root.width - panels.session.width + 1
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Notifications.Background {
        wrapper: panels.notifications

        startX: root.width + 1
        startY: -1
    }

    Session.Background {
        wrapper: panels.session

        startX: root.width + 1
        startY: (root.height - wrapper.height) / 2 - rounding
    }

    Launcher.Background {
        wrapper: panels.launcher

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: root.height + 1
    }

    Dashboard.Background {
        wrapper: panels.dashboard

        startX: (root.width - wrapper.width) / 2 - rounding
        startY: 0
    }

    BarPopouts.Background {
        wrapper: panels.popouts
        invertBottomRounding: wrapper.x + wrapper.width + 1 >= root.width

        startX: wrapper.x - rounding * sideRounding
        startY: wrapper.y
    }

    Utilities.Background {
        wrapper: panels.utilities

        startX: root.width
        startY: root.height
    }
}
