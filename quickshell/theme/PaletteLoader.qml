import QtQuick
import Quickshell
import Quickshell.Io

// Singleton that watches palette.json and keeps Theme's colours in sync.
// Lives in ShellRoot so it is always active.
//
// ===== the two shapes of palette.json =====
// The Lacia palette (what Theme.qml ships with) uses the semantic names:
// glass, bodyLow, bodyMid, bodyTop, rim, edge, recess, ink, inkDim, inkFaint,
// ice, accentCyan, accent, accentDeep.
//
// A palette written by an older scripts/palette.sh, or one kept from before
// this change, uses the Catppuccin names instead: mantle, base, surface0,
// surface1, text, subtext0, subtext1, mauve. Those are still read, and are
// mapped onto the same ladder, so an old palette.json does not silently turn
// the shell grey -- it just wears a different hue on the same structure.
//
// Both are guarded by `if (p.x)`, so a file with only some of the keys leaves
// the rest of the Theme alone.
QtObject {
    property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/palette.json"
        watchChanges: true
        onFileChanged: this.reload()
        onLoaded: {
            try {
                var p = JSON.parse(this.text());

                // ---- semantic names (current) ----
                if (p.glass)      Theme.glass      = p.glass;
                if (p.bodyLow)    Theme.bodyLow    = p.bodyLow;
                if (p.bodyMid)    Theme.bodyMid    = p.bodyMid;
                if (p.bodyTop)    Theme.bodyTop    = p.bodyTop;
                if (p.rim)        Theme.rim        = p.rim;
                if (p.edge)       Theme.edge       = p.edge;
                if (p.recess)     Theme.recess     = p.recess;
                if (p.ink)        Theme.ink        = p.ink;
                if (p.inkDim)     Theme.inkDim     = p.inkDim;
                if (p.inkFaint)   Theme.inkFaint   = p.inkFaint;
                if (p.ice)        Theme.ice        = p.ice;
                if (p.accentCyan) Theme.accentCyan = p.accentCyan;
                if (p.accent)     Theme.accent     = p.accent;
                if (p.accentDeep) Theme.accentDeep = p.accentDeep;
                if (p.danger)     Theme.danger     = p.danger;

                // ---- legacy names, mapped onto the same ladder ----
                if (p.mantle)   Theme.bodyLow  = p.mantle;
                if (p.base)     Theme.glass    = p.base;
                if (p.surface0) Theme.bodyMid  = p.surface0;
                if (p.surface1) Theme.bodyTop  = p.surface1;
                if (p.text)     Theme.ink      = p.text;
                if (p.subtext0) Theme.inkFaint = p.subtext0;
                if (p.subtext1) Theme.inkDim   = p.subtext1;
                if (p.mauve)    Theme.accent   = p.mauve;
                if (p.red)      Theme.danger   = p.red;
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
