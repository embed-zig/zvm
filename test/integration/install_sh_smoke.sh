#!/bin/sh
set -eu

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
release_dir="${ZVM_RELEASE_DIR:-release}"
release_dir="$(cd "$release_dir" && pwd -P)"
work="${ZVM_INSTALL_SH_TEST_TMPDIR:-${TMPDIR:-/tmp}/zvm-install-sh.$$}"
install_root="$work/zvm"

cleanup() {
    rm -rf "$work"
}
trap cleanup EXIT INT TERM

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) zvm_exe="zvm.exe" ;;
    *) zvm_exe="zvm" ;;
esac

ZVM_ARTIFACT_DIR="$release_dir" \
ZVM_INSTALL_DIR="$install_root" \
sh "$release_dir/install.sh"

zvm_bin="$install_root/bin/$zvm_exe"
"$zvm_bin" --version

PATH="$install_root/bin:$PATH" \
ZVM_BIN="$zvm_bin" \
sh "$script_dir/zvm_commands_smoke.sh"
