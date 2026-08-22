#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.2}"
FLUTTER_CACHE_DIR="${HOME}/.cache/flutter/${FLUTTER_VERSION}"
FLUTTER_ROOT="${FLUTTER_CACHE_DIR}/flutter"
FLUTTER_ARCHIVE="${FLUTTER_CACHE_DIR}/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

git config --global --add safe.directory "$PWD"

if [[ ! -x "${FLUTTER_ROOT}/bin/flutter" ]]; then
  mkdir -p "${FLUTTER_CACHE_DIR}"
  if [[ ! -f "${FLUTTER_ARCHIVE}" ]]; then
    curl --fail --location --show-error --silent "${FLUTTER_URL}" --output "${FLUTTER_ARCHIVE}"
  fi
  tar -xJf "${FLUTTER_ARCHIVE}" -C "${FLUTTER_CACHE_DIR}"
fi

export PATH="${FLUTTER_ROOT}/bin:${PATH}"

flutter --version
flutter pub get
flutter build web --release