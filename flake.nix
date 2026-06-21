{
  # kiro-ide-flake
  # --------------
  # Kiro IDE'yi NixOS'a kurar. Başka bir şey yapmaz.
  #
  # Güncelleme: bash get-hashes.sh
  # Metadata:   curl https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json

  description = "Kiro IDE — AWS agentic IDE (spec-driven development)";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };

        # ── config — inject, never hardcode ─────────────────────────────────
        version = "0.12.333";
        sha256   = "sha256-EEj0hz3fxPtesifXuFb0DQfFHaYgOQ1wgkaqcNMeX84=";
        baseUrl  = "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed";

        # ── adapter: upstream tarball'ı indir ve doğrula ────────────────────
        fetchSource = pkgs.fetchurl {
          url    = "${baseUrl}/${version}/tar/kiro-ide-${version}-stable-linux-x64.tar.gz";
          sha256 = sha256;
        };

        # ── core: runtime bağımlılık listesi ────────────────────────────────
        # Electron/VSCode tabanlı IDE — glibc 2.39+
        runtimeDeps = with pkgs; [
          glibc stdenv.cc.cc.lib               # libc / C++ runtime
          alsa-lib at-spi2-atk cairo pango      # ses / erişilebilirlik / font
          gdk-pixbuf glib gtk3                  # GTK yığını
          cups dbus expat libuuid systemd        # sistem servisleri
          xdg-utils libnotify                   # masaüstü entegrasyonu
          libdrm libGL mesa nspr nss            # grafik / display
          libX11 libxcb libXcomposite libXdamage
          libXext libXfixes libXrandr libxshmfence
          libxkbfile                            # Microsoft-auth / keymapping
          webkitgtk_4_1                         # gömülü webview
          libsoup_3                             # HTTP / ağ
          libsecret                             # Keyring
        ];

        # ── module: $out/bin/kiro launcher scripti ──────────────────────────
        # L7V Bash kuralları: header, set -euo pipefail, tek iş.
        launcherScript = ''
          #!/usr/bin/env bash
          # kiro
          # ----
          # Kiro IDE binary'sini çalıştırır. Başka bir şey yapmaz.
          set -euo pipefail
          exec "@out@/lib/kiro-ide/kiro" "$@"
        '';

        # ── module: .desktop dosyası içeriği ────────────────────────────────
        desktopEntry = ''
          [Desktop Entry]
          Name=Kiro
          Comment=AWS Agentic IDE
          Exec=kiro %U
          Terminal=false
          Type=Application
          Icon=kiro
          Categories=Development;IDE;
          MimeType=x-scheme-handler/kiro;
          StartupWMClass=kiro
        '';

        # ── app: yukarıdaki parçaları wire et, derivation üret ──────────────
        kiro-ide = pkgs.stdenv.mkDerivation {
          pname   = "kiro-ide";
          version = version;
          src     = fetchSource;

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.wrapGAppsHook3
          ];

          buildInputs   = runtimeDeps;
          dontBuild     = true;
          dontStrip     = true;
          dontConfigure = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/kiro-ide
            cp -r . $out/lib/kiro-ide/

            mkdir -p $out/bin
            printf '%s' '${launcherScript}' > $out/bin/kiro
            substituteInPlace $out/bin/kiro --subst-var out
            chmod +x $out/bin/kiro

            mkdir -p $out/share/applications
            printf '%s' '${desktopEntry}' > $out/share/applications/kiro.desktop

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Kiro — AWS agentic IDE with spec-driven development";
            longDescription = ''
              Kiro is an agentic IDE built by AWS on Code OSS (VS Code foundation).
              Spec-driven development, agent hooks, steering files, MCP support.
              Powered by Claude via Amazon Bedrock. Free tier: 50 interactions/month.
            '';
            homepage    = "https://kiro.dev";
            license     = licenses.unfree;
            platforms   = [ "x86_64-linux" ];
            mainProgram = "kiro";
          };
        };

      in {
        packages = {
          kiro-ide = kiro-ide;
          default  = kiro-ide;
        };

        apps.default = {
          type    = "app";
          program = "${kiro-ide}/bin/kiro";
        };
      }
    );
}
