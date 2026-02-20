#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

REMOVE_PATHS=(
  "$ROOT_DIR/DerivedData"
  "$ROOT_DIR/Index.noindex"
  "$ROOT_DIR/ModuleCache.noindex"
  "$ROOT_DIR/SymbolCache.noindex"
  "$ROOT_DIR/CompilationCache.noindex"
  "$ROOT_DIR/build"
  "$ROOT_DIR/Build"
  "$ROOT_DIR/.build"
  "$ROOT_DIR/.swiftpm"
  "$ROOT_DIR/Anchor.xcodeproj/xcuserdata"
  "$ROOT_DIR/Anchor.xcodeproj/project.xcworkspace/xcuserdata"
  "$ROOT_DIR/Anchor.xcodeproj/project.xcworkspace/xcshareddata"
)

REMOVE_DERIVEDDATA=false
if [[ "${1:-}" == "--deriveddata" ]]; then
  REMOVE_DERIVEDDATA=true
fi

printf "Cleaning generated artifacts inside repo:\n"
for path in "${REMOVE_PATHS[@]}"; do
  if [[ -e "$path" ]]; then
    printf "  - removing %s\n" "$path"
    rm -rf "$path"
  fi
done

# Remove .DS_Store files in repo
find "$ROOT_DIR" -name '.DS_Store' -type f -delete || true

if $REMOVE_DERIVEDDATA; then
  DERIVED="$HOME/Library/Developer/Xcode/DerivedData"
  if [[ -d "$DERIVED" ]]; then
    printf "\nRemoving global DerivedData for Anchor (best effort):\n"
    find "$DERIVED" -maxdepth 1 -type d -name 'Anchor-*' -print -exec rm -rf {} + || true
  fi
fi

printf "\nDone.\n"
