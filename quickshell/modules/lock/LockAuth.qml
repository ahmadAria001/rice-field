// PAM-backed authentication for the lock screen.
// One instance is shared by every lock surface, because a PAM conversation is
// single-session: two screens must not authenticate simultaneously.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// The context is idle until the user submits, then started per attempt. Keeping it
// active while idle is wrong: PAM asks for a response that nobody can give, and the
// conversation fails immediately.
Item {
    id: root

    // Set from the login user, so the lock screen needs no configuration.
    readonly property string userName: Quickshell.env("USER")
    // Human name from the GECOS field, falling back to the login name.
    property string displayName: userName
    property string message: ""
    property bool messageIsError: false
    property bool busy: false
    // Set once authentication succeeds, so further input is ignored while the
    // unlock animation plays.
    property bool finishing: false
    // Held only between start() and the response, then cleared.
    property string pendingPassword: ""
    property bool responded: false

    signal unlocked()
    signal failed()

    function submit(password) {
        if (busy || finishing)
            return ;

        if (password === "") {
            root.message = "Type your password";
            root.messageIsError = true;
            return ;
        }
        // Leave no half-open conversation behind from a previous attempt.
        if (pam.active)
            pam.abort();

        root.pendingPassword = password;
        root.responded = false;
        root.busy = true;
        root.message = "";
        if (!pam.start()) {
            root.pendingPassword = "";
            root.busy = false;
            root.message = "Could not start authentication";
            root.messageIsError = true;
        }
    }

    function clearMessage() {
        root.message = "";
        root.messageIsError = false;
    }

    Process {
        id: whoamiProc

        command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                const name = line.trim();
                if (name !== "")
                    root.displayName = name;

            }
        }

    }

    PamContext {
        // Started per attempt by submit(), never left running.

        id: pam

        config: "lockscreen"
        configDirectory: Quickshell.env("HOME") + "/.config/quickshell/pam"
        user: root.userName
        // PAM is asking for the password.
        onPamMessage: {
            if (pam.responseRequired && !root.responded) {
                root.responded = true;
                const secret = root.pendingPassword;
                root.pendingPassword = "";
                pam.respond(secret);
            }
        }
        onCompleted: (result) => {
            root.pendingPassword = "";
            root.busy = false;
            if (result === PamResult.Success) {
                root.message = "";
                root.messageIsError = false;
                root.finishing = true;
                root.unlocked();
            } else if (result === PamResult.Failed) {
                root.message = "Incorrect password";
                root.messageIsError = true;
                root.failed();
            } else if (result === PamResult.MaxTries) {
                root.message = "Too many attempts, try again";
                root.messageIsError = true;
                root.failed();
            } else {
                root.message = "Authentication error";
                root.messageIsError = true;
                root.failed();
            }
        }
        onError: (error) => {
            root.pendingPassword = "";
            root.busy = false;
            root.message = PamError.toString(error);
            root.messageIsError = true;
            root.failed();
        }
    }

}
