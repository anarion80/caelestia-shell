pragma Singleton

import qs.config
import qs.utils
import Quickshell
import QtQuick

Searcher {
    id: root

    function launch(entry: DesktopEntry): void {
        console.log(entry.name);
        console.log(entry.command);
        console.log(entry.execString);
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

    function search(search: string): list<var> {
        const prefix = Config.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["desc", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["wmClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.modelData);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.modelData);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: variants.instances
    useFuzzy: Config.launcher.useFuzzy.apps

    Variants {
        id: variants

        model: [...DesktopEntries.applications.values].filter(a => !Config.launcher.hiddenApps.includes(a.id)).sort((a, b) => a.name.localeCompare(b.name))

        QtObject {
            required property DesktopEntry modelData
            readonly property string id: modelData.id
            readonly property string name: modelData.name
            readonly property string desc: modelData.comment
            readonly property string execString: modelData.execString
            readonly property string wmClass: modelData.startupClass
            readonly property string genericName: modelData.genericName
            readonly property string categories: modelData.categories.join(" ")
            readonly property string keywords: modelData.keywords.join(" ")
        }
    }
}
