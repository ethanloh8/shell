pragma Singleton

import qs.config
import qs.utils
import Caelestia.Models
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: Config.services.smartScheme ? [] : ["--no-smart"]

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool initialLoad: true
    property bool swwwReady: false

    Component.onCompleted: {
        if (Config.background.swww.enabled)
            swwwDaemon.running = true;
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;

        if (Config.background.swww.enabled) {
            // Build swww command with transition options
            const swwwArgs = ["swww", "img", path];
            const swwwConfig = Config.background.swww;

            if (swwwConfig.transitionType)
                swwwArgs.push("--transition-type", swwwConfig.transitionType);
            if (swwwConfig.transitionDuration > 0)
                swwwArgs.push("--transition-duration", swwwConfig.transitionDuration.toString());
            if (swwwConfig.transitionStep > 0)
                swwwArgs.push("--transition-step", swwwConfig.transitionStep.toString());
            if (swwwConfig.transitionFps > 0)
                swwwArgs.push("--transition-fps", swwwConfig.transitionFps.toString());

            Quickshell.execDetached(swwwArgs);

            // Write path to state file
            Quickshell.execDetached(["sh", "-c", `mkdir -p "$(dirname '${currentNamePath}')" && printf '%s' '${path}' > '${currentNamePath}'`]);

            // Run color extraction if smart scheme is enabled and scheme is dynamic
            if (Config.services.smartScheme && Colours.scheme === "dynamic")
                colourExtractionProc.running = true;
        } else {
            // Use legacy caelestia CLI backend, only apply colors if scheme is dynamic
            const args = Config.services.smartScheme && Colours.scheme === "dynamic" ? [] : ["--no-smart"];
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...args]);
        }
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: Config.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.actualCurrent = text().trim();
            root.previewColourLock = false;
            if (root.initialLoad && root.actualCurrent && root.swwwReady) {
                root.initialLoad = false;
                root.setWallpaper(root.actualCurrent);
            }
        }
    }

    Process {
        id: swwwDaemon
        command: ["swww-daemon", "--no-cache"]
        onStarted: {
            root.swwwReady = true;
            if (root.initialLoad && root.actualCurrent) {
                root.initialLoad = false;
                root.setWallpaper(root.actualCurrent);
            }
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: colourExtractionProc

        command: ["caelestia", "wallpaper", "-p", root.actualCurrent, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, false);
            }
        }
    }
}
