#!/bin/bash
# Aplica patches locales a dependencias SPM.
# Ejecutar después de 'swift package resolve' o 'swift package update'.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PATCHES_DIR="$PROJECT_DIR/patches"
TUIKIT_DIR="$PROJECT_DIR/.build/checkouts/TUIkit"

if [ ! -d "$TUIKIT_DIR" ]; then
    echo "ERROR: TUIkit checkout no encontrado en $TUIKIT_DIR"
    echo "Ejecuta 'swift package resolve' primero."
    exit 1
fi

echo "Aplicando patches a TUIkit..."

cd "$TUIKIT_DIR"

PATCH="$PATCHES_DIR/tuikit-modal-tab-navigation.patch"
if git apply --check "$PATCH" 2>/dev/null; then
    git apply "$PATCH"
    echo "  ✓ tuikit-modal-tab-navigation.patch aplicado"
else
    echo "  - tuikit-modal-tab-navigation.patch ya aplicado o no aplica (omitiendo)"
fi

echo "Listo."
