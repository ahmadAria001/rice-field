// "Lacia After Dark" -- the session lock, on Lacia's material.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// A pure Quickshell session lock: WlSessionLock covers every screen, each screen
// gets a LockSurface, and unlocking runs through PAM.
Item {
    id: root

    // Flipping this to true hands the compositor the lock.
    property bool locked: false
    // True while the unlock animation plays, so surfaces can fade before the
    // compositor drops the lock.
    property bool unlocking: false
    // Set once the compositor confirms every screen is covered.
    readonly property bool secure: lock.secure
    property string wallpaperSource: ""
    property string avatarSource: ""
    // Assets come from ~/Pictures/Wallpapers/ only.
    readonly property string assetDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/quickshell/current_wallpaper.txt"
    // Preferred avatar within the asset directory; falls back to the first image.
    property string preferredAvatar: "107505216_p0.jpg"

    function lock() {
        root.unlocking = false;
        root.locked = true;
    }

    function beginUnlock() {
        if (root.unlocking)
            return ;

        root.unlocking = true;
        unlockTimer.restart();
    }

    function unlock() {
        root.locked = false;
        root.unlocking = false;
        lockAuth.finishing = false;
        lockAuth.clearMessage();
    }

    // If Quickshell exits while locked the compositor keeps the screen blank, so
    // unlock on the way out rather than stranding the session.
    Component.onDestruction: {
        if (root.locked)
            root.unlock();

    }

    // Resolves both assets, staying inside ~/Pictures/Wallpapers/.
    Process {
        id: assetsProc

        command: ["python3", "-c", `
import json, os
d = os.path.expanduser("~/Pictures/Wallpapers")
exts = (".jpg", ".jpeg", ".png", ".webp")
def images():
    try:
        return sorted(f for f in os.listdir(d) if f.lower().endswith(exts))
    except OSError:
        return []
names = images()
wall = ""
state = os.path.expanduser("${root.stateFile}")
try:
    with open(state) as fh:
        cand = fh.read().strip()
    if cand and os.path.dirname(cand) == d and os.path.basename(cand) in names:
        wall = cand
except OSError:
    pass
if not wall and names:
    wall = os.path.join(d, names[0])
pref = os.path.join(d, ${JSON.stringify(root.preferredAvatar)})
avatar = pref if os.path.isfile(pref) else (os.path.join(d, names[0]) if names else "")
print(json.dumps({"wallpaper": wall, "avatar": avatar}))
`]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim());
                    root.wallpaperSource = data.wallpaper ? "file://" + data.wallpaper : "";
                    root.avatarSource = data.avatar ? "file://" + data.avatar : "";
                } catch (e) {
                    root.wallpaperSource = "";
                    root.avatarSource = "";
                }
            }
        }

    }

    LockAuth {
        id: lockAuth

        onUnlocked: root.beginUnlock()
    }

    Timer {
        id: unlockTimer

        // Slightly longer than the unlock animation (see LockSurface), so the content
        // finishes dissolving before the compositor drops the lock.
        interval: 500
        onTriggered: root.unlock()
    }

    WlSessionLock {
        id: lock

        locked: root.locked

        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                // Bound to the id, not to a name that the surface also declares:
                // `auth: auth` resolves the right-hand side to this very property, so
                // the surface received null and every submit was dropped by the
                // authReady guard.
                auth: lockAuth
                wallpaperSource: root.wallpaperSource
                avatarSource: root.avatarSource
                unlocking: root.unlocking
            }

        }

    }

    // Only `lock` is exposed. Unlocking is deliberately not reachable over IPC:
    // `unlock` and `toggle` used to release the session through the same path PAM
    // success uses, so any local process could drop the lock without a password.
    // Every other IPC caller in this config uses `lock` only.
    IpcHandler {
        function lock() {
            root.lock();
        }

        target: "lockscreen"
    }

}
