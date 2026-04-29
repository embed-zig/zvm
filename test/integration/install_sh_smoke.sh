#!/bin/sh
set -eu

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
release_dir="${ZVM_RELEASE_DIR:-release}"
release_dir="$(cd "$release_dir" && pwd -P)"
work="${ZVM_INSTALL_SH_TEST_TMPDIR:-${TMPDIR:-/tmp}/zvm-install-sh.$$}"
if [ -n "${ZVM_INSTALL_SH_TEST_HOME:-}" ]; then
    home_dir="$ZVM_INSTALL_SH_TEST_HOME"
elif [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    home_dir="$HOME"
else
    home_dir="$work/home"
fi
install_root="$home_dir/.zvm"

cleanup() {
    rm -rf "$work"
}
trap cleanup EXIT INT TERM

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) zvm_exe="zvm.exe" ;;
    *) zvm_exe="zvm" ;;
esac

mkdir -p "$home_dir"
if [ "$home_dir" != "$HOME" ]; then
    export HOME="$home_dir"
fi

mkdir -p "$home_dir/.local/bin"
{
    echo '#!/bin/sh'
    echo 'echo shadow-zig'
} > "$home_dir/.local/bin/zig"
chmod +x "$home_dir/.local/bin/zig"

{
    echo "# zvm"
    echo "export PATH=\"$install_root/bin:\$PATH\""
    echo "export PATH=\"$home_dir/.local/bin:\$PATH\""
} > "$home_dir/.bashrc"

candidate_shell_files="
$home_dir/.zshrc
$home_dir/.zprofile
$home_dir/.bash_profile
$home_dir/.profile
$home_dir/.config/fish/config.fish
"

missing_before=""
for candidate in $candidate_shell_files; do
    if [ ! -e "$candidate" ]; then
        missing_before="$missing_before $candidate"
    fi
done

ZVM_ARTIFACT_DIR="$release_dir" \
ZVM_INSTALL_DIR="$install_root" \
sh "$release_dir/install.sh"

if ! grep "$install_root/bin" "$home_dir/.bashrc" >/dev/null 2>&1; then
    echo "install.sh did not add zvm to existing .bashrc" >&2
    exit 1
fi

if [ "$(awk -v bin_dir="$install_root/bin" 'index($0, bin_dir) { line = NR } END { print line + 0 }' "$home_dir/.bashrc")" -lt \
     "$(awk -v local_bin="$home_dir/.local/bin" 'index($0, local_bin) { line = NR } END { print line + 0 }' "$home_dir/.bashrc")" ]; then
    echo "install.sh did not move zvm PATH after later PATH entries" >&2
    exit 1
fi

for unexpected in $missing_before; do
    if [ -e "$unexpected" ]; then
        echo "install.sh unexpectedly created $unexpected" >&2
        exit 1
    fi
done

. "$home_dir/.bashrc"

zvm_path="$(command -v "$zvm_exe" || true)"
if [ "$zvm_path" != "$install_root/bin/$zvm_exe" ]; then
    echo "expected $zvm_exe from PATH at $install_root/bin/$zvm_exe, got $zvm_path" >&2
    exit 1
fi

sh "$script_dir/zvm_commands_smoke.sh"
