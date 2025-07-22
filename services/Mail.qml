pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property list<string> unreadEmails: []
    readonly property int unreadEmailsCount: unreadEmails.length ?? null
    
    reloadableId: "mailText"

    property int refCount

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
        command: ["notmuch", "search", "--format=json", "--output=summary", "tag:unread", "-tag:trash"]
        environment: ({
                LANG: "C",
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const json = JSON.parse(text);
                const unreadEmails = json
                  .filter(m => m && m.authors && m.subject)   // safety guard
                  .map(m => `${m.authors}: ${m.subject}`)   
                root.unreadEmails = unreadEmails;
            }
        }
    }
}
