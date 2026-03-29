pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    property list<string> unreadEmails: []

    property int refCount

    reloadableId: "mailText"

    Timer {
        running: root.refCount > 0
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getUnreadEmails.running = true;
        }
    }

    Process {
        id: getUnreadEmails

        running: true
        command: Config.bar.mail.fetchCommand
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text);
                    const unreadEmails = json.filter(m => m && m.authors && m.subject)   // safety guard
                    .map(m => `${m.authors}: ${m.subject}`);
                    root.unreadEmails = unreadEmails;
                } catch (e) {
                    console.error("Failed to parse mail output:", e.message);
                    root.unreadEmails = [];
                }
            }
        }
    }
}
