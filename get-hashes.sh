#!/usr/bin/env bash
# get-hashes.sh
# -------------
# Kiro IDE'nin güncel versiyon ve hash bilgisini çeker,
# flake.nix'e yapıştırılacak değerleri hazırlar.
#
# Usage: bash get-hashes.sh
# Deps:  curl, python3, nix
set -euo pipefail

# ── config ──────────────────────────────────────────────────────────────────
METADATA_URL="https://prod.download.desktop.kiro.dev/stable/metadata-linux-x64-stable.json"
BASE_RELEASE="https://prod.download.desktop.kiro.dev/releases/stable/linux-x64/signed"

# ── helpers ─────────────────────────────────────────────────────────────────
log_info()  { echo "[INFO] $*"; }
log_error() { echo "[ERROR] $*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || log_error "Required tool not found: $1"
}

# ── validation ───────────────────────────────────────────────────────────────
require curl
require python3
require nix

# ── fetch version ────────────────────────────────────────────────────────────
log_info "Metadata alınıyor..."
META=$(curl -fsSL "$METADATA_URL") || log_error "Metadata alınamadı: $METADATA_URL"

VERSION=$(echo "$META" | python3 -c "
import sys, json
d = json.load(sys.stdin)
v = d.get('currentRelease', '')
if not v:
    raise SystemExit('currentRelease alanı bulunamadı')
print(v)
") || log_error "Versiyon parse edilemedi"

log_info "Versiyon: $VERSION"

# ── build tar url ─────────────────────────────────────────────────────────────
TAR_URL="${BASE_RELEASE}/${VERSION}/tar/kiro-ide-${VERSION}-stable-linux-x64.tar.gz"
log_info "İndirme URL: $TAR_URL"

# ── compute hash ─────────────────────────────────────────────────────────────
log_info "Hash hesaplanıyor (büyük dosya, biraz bekle)..."
RAW_HASH=$(nix-prefetch-url "$TAR_URL" 2>/dev/null | tail -1)
SRI=$(nix hash to-sri --type sha256 "$RAW_HASH" 2>/dev/null) \
  || log_error "SRI dönüşümü başarısız"

# ── output ───────────────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "Bunları flake.nix'e yapıştır:"
echo ""
echo "  version = \"$VERSION\";"
echo "  sha256  = \"$SRI\";"
echo "========================================"
echo ""

# ── auto-update (optional) ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE="$SCRIPT_DIR/flake.nix"

[[ -f "$FLAKE" ]] || { log_info "flake.nix bulunamadı, otomatik güncelleme atlandı."; exit 0; }

read -rp "flake.nix otomatik güncellensin mi? [y/N] " REPLY
echo

if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
  sed -i "s|version = \".*\";|version = \"$VERSION\";|" "$FLAKE"
  sed -i "s|sha256  = \".*\";|sha256  = \"$SRI\";|"   "$FLAKE"
  log_info "flake.nix güncellendi"
else
  log_info "Güncelleme atlandı"
fi