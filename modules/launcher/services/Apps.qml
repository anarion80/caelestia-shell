pragma Singleton

import qs.config
import qs.utils
import Quickshell

Searcher {
    id: root

    list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    useFuzzy: Config.launcher.useFuzzy.apps

    function launch(entry: DesktopEntry): void {
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["ghostty", "-e", `${Quickshell.configDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["sh", "-c", `gtk-launch '${entry.id}.desktop' || gtk-launch -- ${entry.execString}`],
                workingDirectory: entry.workingDirectory
            });
    }
}
