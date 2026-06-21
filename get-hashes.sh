#!/usr/bin/env bash
# Kiro IDE - güncel versiyon ve hash'i flake.nix için hazırlar
# Kullanım: bash get-hashes.sh

set -e

METADATA="https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json"

echo "==> Metadata alınıyor..."
META=$(curl -fsSL "$METADATA")
echo "$META"
echo ""

VERSION=$(echo "$META" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('currentRelease',''))")
echo "==> Versiyon: $VERSION"

TAR_URL="https://prod.download.desktop.kiro.dev/releases/${VERSION}--distro-linux-x64-tar-gz"
echo "==> İndirme URL: $TAR_URL"
echo ""

echo "==> nix hash hesaplanıyor (büyük dosya, biraz bekle)..."
HASH=$(nix-prefetch-url "$TAR_URL" 2>/dev/null | tail -1)
SRI=$(nix hash to-sri --type sha256 "$HASH" 2>/dev/null)

echo ""
echo "========================================"
echo "Bunları flake.nix'e yapıştır:"
echo "  version = \"$VERSION\";"
echo "  sha256  = \"$SRI\";"
echo "========================================"

# Otomatik sed ile flake.nix'i güncelle (opsiyonel)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/flake.nix" ]]; then
  read -p "flake.nix otomatik güncellensin mi? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sed -i "s|version = \".*\";|version = \"$VERSION\";|" "$SCRIPT_DIR/flake.nix"
    sed -i "s|sha256  = \".*\";|sha256  = \"$SRI\";|" "$SCRIPT_DIR/flake.nix"
    echo "✓ flake.nix güncellendi"
  fi
fi
