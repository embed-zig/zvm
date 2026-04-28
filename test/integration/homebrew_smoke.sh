#!/bin/sh
set -eu

case "$(uname -s)" in
    Darwin) ;;
    *)
        echo "homebrew smoke test only runs on macOS" >&2
        exit 1
        ;;
esac

if ! command -v brew >/dev/null 2>&1; then
    echo "homebrew smoke test requires brew" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
developer_mode_was_enabled=0
case "$(brew developer 2>/dev/null || true)" in
    *"Developer mode is enabled"*) developer_mode_was_enabled=1 ;;
esac

release_dir="${ZVM_RELEASE_DIR:-release}"
release_dir="$(cd "$release_dir" && pwd -P)"

case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    arm64|aarch64) arch="aarch64" ;;
    *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

asset="zvm-macos-$arch.tar.gz"
asset_path="$release_dir/$asset"
checksums="$release_dir/SHA256SUMS"

if [ ! -f "$asset_path" ]; then
    echo "missing release asset: $asset_path" >&2
    exit 1
fi

checksum="$(awk -v asset="$asset" '$2 == asset { print $1 }' "$checksums")"
if [ -z "$checksum" ]; then
    echo "SHA256SUMS does not contain $asset" >&2
    exit 1
fi

tap_name="zvm-ci/integration"
work="${ZVM_HOMEBREW_TEST_TMPDIR:-${TMPDIR:-/tmp}/zvm-homebrew.$$}"
cleanup() {
    brew uninstall --formula "$tap_name/zvm-integration" >/dev/null 2>&1 || true
    brew untap "$tap_name" >/dev/null 2>&1 || true
    if [ "$developer_mode_was_enabled" = "0" ]; then
        brew developer off >/dev/null 2>&1 || true
    fi
    rm -rf "$work"
}
trap cleanup EXIT INT TERM

mkdir -p "$work"
brew uninstall --formula "$tap_name/zvm-integration" >/dev/null 2>&1 || true
brew untap "$tap_name" >/dev/null 2>&1 || true
brew tap-new --no-git "$tap_name" >/dev/null

tap_dir="$(brew --repository "$tap_name")"
formula="$tap_dir/Formula/zvm-integration.rb"
cat > "$formula" <<EOF
class ZvmIntegration < Formula
  desc "Zig Version Manager"
  homepage "https://github.com/embed-zig/zvm"
  license "MIT"
  version "0.0.0-ci"
  url "file://$asset_path"
  sha256 "$checksum"

  def install
    bin.install "zvm"
  end

  test do
    assert_match "zvm", shell_output("#{bin}/zvm --version")
  end
end
EOF

brew install "$tap_name/zvm-integration"
brew test "$tap_name/zvm-integration"

zvm_bin="$(brew --prefix "$tap_name/zvm-integration")/bin/zvm"
ZVM_BIN="$zvm_bin" sh "$script_dir/zvm_commands_smoke.sh"
