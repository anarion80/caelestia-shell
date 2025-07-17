pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string unreadMail

    property int refCount

    Timer {
        running: root.refCount > 0
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            checkMail.running = true;
        }
    }

    Process {
        id: checkMail

        running: true
        command: ["sh", "-c", "notmuch count tag:unread"]
        stdout: StdioCollector {
            onStreamFinished: {
                const temp = text.trim();
                root.unreadMail = temp;
            }
        }
    }
}
