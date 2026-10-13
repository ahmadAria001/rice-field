import QtQuick
import Quickshell
import Quickshell.Io

// Singleton that watches palette.json and keeps Theme colors in sync.
// Lives in ShellRoot so it is always active.
QtObject {
    property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/palette.json"
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: {
            try {
                var p = JSON.parse(this.text());
                if (p.mantle)   Theme.mantle   = p.mantle;
                if (p.base)     Theme.base      = p.base;
                if (p.surface0) Theme.surface0  = p.surface0;
                if (p.surface1) Theme.surface1  = p.surface1;
                if (p.text)     Theme.text      = p.text;
                if (p.subtext0) Theme.subtext0  = p.subtext0;
                if (p.subtext1) Theme.subtext1  = p.subtext1;
                if (p.mauve)    Theme.mauve     = p.mauve;
            } catch (e) {
                // palette.json missing or malformed — keep current colors
            }
        }
    }

    property FileView motionFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/motion.json"
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: {
            try {
                var m = JSON.parse(this.text());
                if (m.hasOwnProperty("enabled")) {
                    Theme.motionScale = m.enabled ? 1.0 : 0.0;
                } else if (m.hasOwnProperty("scale")) {
                    Theme.motionScale = Number(m.scale);
                }
            } catch (e) {
            }
        }
    }
}
