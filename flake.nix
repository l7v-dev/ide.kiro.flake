{
  description = "Kiro IDE - AWS agentic IDE (spec-driven development)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # ---------------------------------------------------------------
        # Güncellemek için: bash get-hashes.sh
        # Metadata:
        #   curl https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json
        # ---------------------------------------------------------------
        version = "0.12.333";
        # Nix'in indirme sırasında doğruladığı gerçek SRI hash değeri:
        sha256  = "sha256-EEj0hz3fxPtesifXuFb0DQfFHaYgOQ1wgkaqcNMeX84=";

        kiro-ide = pkgs.stdenv.mkDerivation {
          pname = "kiro-ide";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed/${version}/tar/kiro-ide-${version}-stable-linux-x64.tar.gz";
            inherit sha256;
          };

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.wrapGAppsHook3 # <-- nixpkgs-unstable uyumluluğu için güncel kanca
          ];

          # Electron/VSCode tabanlı IDE'nin runtime bağımlılıkları (glibc 2.39+)
          buildInputs = with pkgs; [
            glibc
            stdenv.cc.cc.lib
            alsa-lib
            at-spi2-atk
            cairo
            cups
            dbus
            expat
            gdk-pixbuf
            glib
            gtk3
            libdrm
            libnotify
            libuuid
            libX11
            libxcb
            libXcomposite
            libXdamage
            libXext
            libXfixes
            libXrandr
            libxshmfence
            mesa
            nspr
            nss
            pango
            systemd
            xdg-utils

            # ── auto-patchelf tarafından istenen bağımlılıklar ──
            libxkbfile           # Microsoft-auth ve keymapping için güncel paket adı
            webkitgtk_4_1        # Gömülü webview bileşenleri için
            libsoup_3            # Ağ ve HTTP istekleri için
            libsecret            # Güvenli kimlik doğrulama saklama (Keyring) için
            libGL                # ANGLE/Display EGL grafik çökmelerini engellemek için GPU sürücü bağımlılığı
          ];

          dontBuild = true;
          dontStrip = true;
          dontConfigure = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/kiro-ide
            cp -r . $out/lib/kiro-ide/

            mkdir -p $out/bin
            cat > $out/bin/kiro << 'EOF'
#!/bin/sh
exec "@out@/lib/kiro-ide/kiro" "$@"
EOF
            substituteInPlace $out/bin/kiro --subst-var out
            chmod +x $out/bin/kiro

            mkdir -p $out/share/applications
            cat > $out/share/applications/kiro.desktop << 'EOF'
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
EOF

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Kiro - AWS agentic IDE with spec-driven development";
            longDescription = ''
              Kiro is an agentic IDE built by AWS on Code OSS (VS Code foundation).
              Spec-driven development, agent hooks, steering files, MCP support.
              Powered by Claude via Amazon Bedrock. Free tier: 50 interactions/month.
            '';
            homepage = "https://kiro.dev";
            license = licenses.unfree;
            platforms = [ "x86_64-linux" ];
            mainProgram = "kiro";
          };
        };

      in {
        packages = {
          kiro-ide = kiro-ide;
          default = kiro-ide;
        };

        apps.default = {
          type = "app";
          program = "${kiro-ide}/bin/kiro";
        };
      }
    );
}