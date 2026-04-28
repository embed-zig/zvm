#!/bin/sh
set -eu

cat >&2 <<'EOF'
update-registry.sh is intentionally conservative.

Add or update registry/<version>.zon files manually, then run:
  ./devtools/verify-registry.sh

Use upstream release metadata as the source of truth:
  - https://ziglang.org/download/index.json
  - https://api.github.com/repos/embed-zig/esp-zig-bootstrap/releases
EOF
