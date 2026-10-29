import Quickshell
import Quickshell.Io
import "modules/bar"
import "modules/clipboard"
import "modules/launcher"
import "modules/lock"
import "modules/notifications"
import "modules/overview"
import "theme"

ShellRoot {
    // Always-on palette watcher — hot-reloads Theme colors when palette.json changes
    PaletteLoader {
    }

    Bar {
    }

    ClipboardPanel {
    }

    Launcher {
    }

    LockScreen {
        id: lockScreen
    }

    Notifications {
    }

    Overview {
    }

}
