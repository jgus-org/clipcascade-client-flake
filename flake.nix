{
  description = "ClipCascade Linux desktop client: clipboard sync across devices (Sathvik-Rao/ClipCascade).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    let
      pin = import ./pin.nix;
      inherit (pin) version;
      source = {
        asset = "ClipCascade_Linux.tar.xz";
        owner = "Sathvik-Rao";
        repo = "ClipCascade";
        tag = "v\${version}";
        type = "github-release-asset";
      };
    in
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = rec {
          clipcascade-client = pkgs.stdenvNoCC.mkDerivation {
            inherit version;
            src = pkgs.fetchurl {
              hash = pin.hash;
              url = "https://github.com/${source.owner}/${source.repo}/releases/download/v${version}/${source.asset}";
            };
            # GI typelibs collected onto GI_TYPELIB_PATH: AyatanaAppIndicator3 backs the pystray tray on Plasma's StatusNotifier host.
            buildInputs = [
              pkgs.glib
              pkgs.gtk3
              pkgs.gdk-pixbuf
              pkgs.libayatana-appindicator
            ];
            desktopItems = [
              (pkgs.makeDesktopItem {
                categories = [ "Utility" ];
                comment = "Sync clipboard across devices";
                desktopName = "ClipCascade";
                exec = "clipcascade";
                icon = "edit-copy";
                name = "clipcascade";
                startupNotify = false;
                terminal = false;
              })
            ];
            dontBuild = true;
            # Wrap by hand to fold gappsWrapperArgs into the python launcher.
            dontWrapGApps = true;
            installPhase = ''
              runHook preInstall
              mkdir -p $out/share/clipcascade
              cp -r . $out/share/clipcascade/
              runHook postInstall
            '';
            meta = {
              description = "Clipboard sync across devices (desktop client)";
              homepage = "https://github.com/Sathvik-Rao/ClipCascade";
              license = pkgs.lib.licenses.gpl3Only;
              mainProgram = "clipcascade";
              platforms = pkgs.lib.platforms.linux;
            };
            nativeBuildInputs = [
              pkgs.wrapGAppsHook3
              pkgs.gobject-introspection
              pkgs.copyDesktopItems
            ];
            patches = [ ./writable-config-dir.patch ];
            pname = "clipcascade-client";
            preFixup =
              let
                # gi (clipboard monitor) and tkinter (login/dialog GUI) are imported but unlisted in upstream's requirements; dbus-python backs plyer desktop notifications.
                pythonEnv = pkgs.python3.withPackages (ps: [
                  ps.aiortc
                  ps.beautifulsoup4
                  ps.dbus-python
                  ps.keyring
                  ps.pillow
                  ps.plyer
                  ps.prompt-toolkit
                  ps.pycryptodome
                  ps.pyfiglet
                  ps.pygobject3
                  ps.pystray
                  ps.requests
                  ps.tkinter
                  ps.websocket-client
                  ps.xxhash
                ]);
              in
              ''
                makeWrapper ${pythonEnv}/bin/python3 $out/bin/clipcascade \
                  --add-flags $out/share/clipcascade/main.py \
                  --set PYSTRAY_BACKEND appindicator \
                  --prefix PATH : ${
                    pkgs.lib.makeBinPath [
                      pkgs.wl-clipboard
                      pkgs.xclip
                      pkgs.libnotify
                    ]
                  } \
                  "''${gappsWrapperArgs[@]}"
              '';
            sourceRoot = "ClipCascade";
          };
          default = clipcascade-client;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            minimumTrackingVersion = "3.3.0";
            pinSchema = "github-asset";
          };
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
          };
        };
      }
    );
}
