#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter_bin="${FLUTTER_BIN:-flutter}"
"$flutter_bin" pub get

# Flutter 3.44.2 can reuse a Web entrypoint registered for an older plugin set.
if [ -d .dart_tool/flutter_build ]; then
  find .dart_tool/flutter_build -type f -name web_entrypoint.stamp -delete
fi

"$flutter_bin" build web --release --no-web-resources-cdn "$@"
