# clipcascade-client

A Nix flake that packages the Linux desktop client of [ClipCascade](https://github.com/Sathvik-Rao/ClipCascade), a clipboard that syncs between devices.

## Outputs

| Attribute                     | What you get                                                                                                                                  |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages.default`            | `bin/clipcascade` — the client wrapped with its own Python environment, a desktop entry, and the clipboard and notification helpers it calls. |
| `packages.clipcascade-client` | The same package under its own name.                                                                                                          |

Published for `x86_64-linux` and `aarch64-linux`. The packaged payload is the Linux release archive, so there is nothing to publish for another system.

## Requirements and notes

- The client is half of a pair. It syncs through a ClipCascade server and does nothing on its own, and it signs in to that server at first run.
- It is a desktop application: a display server, a notification daemon for its popups, and a StatusNotifier/tray host — the launcher selects the AppIndicator backend, so the icon depends on that watcher being present.
- Clipboard access is delegated to `wl-clipboard` on Wayland and `xclip` on X11; both are already on the wrapped `PATH`, and neither functions headless.
- Everything it keeps goes into `$XDG_DATA_HOME/ClipCascade` (default `~/.local/share/ClipCascade`), which it creates on first run: the configuration, the clipboard database, and the sign-in it stores when you enable "store password locally" — the password itself while encryption is off, its hash once encryption is on. Treat that directory as secret-bearing, and back it up if you want the session to survive.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
