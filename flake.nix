{
  description = "Kiro IDE — AWS agentic IDE (spec-driven development)"; [cite: 2]

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable"; [cite: 3]
    flake-utils.url = "github:numtide/flake-utils"; [cite: 3]
  };

  outputs = { self, nixpkgs, flake-utils }: [cite: 4]
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: [cite: 4]
      let
        # Eski sistem uyarısını önlemek için import yapısını güncelledik
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; }; [cite: 4]

        version = "0.12.333"; [cite: 4]
        sha256   = "sha256-EEj0hz3fxPtesifXuFb0DQfFHaYgOQ1wgkaqcNMeX84="; [cite: 4]
        baseUrl  = "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed"; [cite: 4]

        fetchSource = pkgs.fetchurl { [cite: 5]
          url    = "${baseUrl}/${version}/tar/kiro-ide-${version}-stable-linux-x64.tar.gz"; [cite: 5]
          sha256 = sha256; [cite: 5]
        };

        runtimeDeps = with pkgs; [ [cite: 5]
          glibc stdenv.cc.cc.lib [cite: 5, 6]
          alsa-lib at-spi2-atk cairo pango [cite: 6]
          gdk-pixbuf glib gtk3 [cite: 6]
          cups dbus expat libuuid systemd [cite: 6]
          xdg-utils libnotify [cite: 7]
          libdrm libGL mesa nspr nss [cite: 7]
          libX11 libxcb libXcomposite libXdamage [cite: 7]
          libXext libXfixes libXrandr libxshmfence [cite: 7]
          libxkbfile [cite: 8]
          webkitgtk_4_1 [cite: 8]
          libsoup_3 [cite: 8]
          libsecret [cite: 9]
        ];

        launcherScript = '' [cite: 10]
          #!/usr/bin/env bash
          # kiro
          # ----
          # Kiro IDE binary'sini çalıştırır. Başka bir şey yapmaz.
          set -euo pipefail [cite: 11, 12]
          exec "@out@/lib/kiro-ide/kiro" "$@" [cite: 12]
        '';

        desktopEntry = '' [cite: 13]
          [Desktop Entry]
          Name=Kiro
          Comment=AWS Agentic IDE
          Exec=kiro %U
          Terminal=false
          Type=Application
          Icon=kiro
          Categories=Development;IDE; [cite: 14]
          MimeType=x-scheme-handler/kiro; [cite: 14]
          StartupWMClass=kiro [cite: 14]
        '';

        kiro-ide = pkgs.stdenv.mkDerivation { [cite: 15]
          pname   = "kiro-ide"; [cite: 15]
          version = version; [cite: 16]
          src     = fetchSource; [cite: 16]

          nativeBuildInputs = [ [cite: 17]
            pkgs.autoPatchelfHook [cite: 17]
            pkgs.wrapGAppsHook3 [cite: 17]
          ];

          buildInputs = runtimeDeps; [cite: 18]

          # autoPatchelfHook'un binary'yi bulabilmesi için runtime kütüphanelerini ekliyoruz
          runtimeDependencies = runtimeDeps;

          dontBuild     = true; [cite: 18]
          dontStrip     = true; [cite: 18]
          dontConfigure = true; [cite: 19]

          installPhase = '' [cite: 20]
            runHook preInstall [cite: 20]

            mkdir -p $out/lib/kiro-ide [cite: 20]

            # DÜZELTME: Klasörün kendisini değil, içindekileri kopyalıyoruz
            cp -r * $out/lib/kiro-ide/ [cite: 20]

            mkdir -p $out/bin [cite: 20]
            printf '%s' '${launcherScript}' > $out/bin/kiro [cite: 20]
            substituteInPlace $out/bin/kiro --subst-var out [cite: 20]
            chmod +x $out/bin/kiro [cite: 20]

            mkdir -p $out/share/applications [cite: 20]
            printf '%s' '${desktopEntry}' > $out/share/applications/kiro.desktop [cite: 20]

            runHook postInstall [cite: 21]
          '';

          meta = with pkgs.lib; { [cite: 21, 22]
            description = "Kiro — AWS agentic IDE with spec-driven development"; [cite: 22]
            longDescription = '' [cite: 23]
              Kiro is an agentic IDE built by AWS on Code OSS (VS Code foundation).
              Spec-driven development, agent hooks, steering files, MCP support.
              Powered by Claude via Amazon Bedrock. Free tier: 50 interactions/month. [cite: 24]
            '';
            homepage    = "https://kiro.dev"; [cite: 25]
            license     = licenses.unfree; [cite: 25]
            platforms   = [ "x86_64-linux" ]; [cite: 25]
            mainProgram = "kiro"; [cite: 26]
          };
        };

      in {
        packages = {
          kiro-ide = kiro-ide; [cite: 26]
          default  = kiro-ide; [cite: 27]
        };

        apps.default = {
          type    = "app"; [cite: 27]
          program = "${kiro-ide}/bin/kiro"; [cite: 28]
        };
      }
    );
}
