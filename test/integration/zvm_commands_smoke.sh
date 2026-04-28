#!/bin/sh
set -eu

work="${ZVM_TEST_TMPDIR:-${TMPDIR:-/tmp}/zvm-integration.$$}"
zvm_home="${ZVM_COMMANDS_HOME:-}"
registry_dir="$work/registry"
archive_dir="$work/archives"

cleanup() {
    rm -rf "$work"
}
trap cleanup EXIT INT TERM

sha256_file() {
    file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    else
        shasum -a 256 "$file" | awk '{print $1}'
    fi
}

file_size() {
    file="$1"
    if stat -c %s "$file" >/dev/null 2>&1; then
        stat -c %s "$file"
    else
        stat -f %z "$file"
    fi
}

zvm_path() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) cygpath -m "$1" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

target_tag() {
    case "$(uname -s)" in
        Darwin) os="macos" ;;
        Linux) os="linux" ;;
        MINGW*|MSYS*|CYGWIN*) os="windows" ;;
        *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64) arch="aarch64" ;;
        *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac

    printf '%s-%s\n' "$os" "$arch"
}

zig_name() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) echo "zig.exe" ;;
        *) echo "zig" ;;
    esac
}

make_archive() {
    version="$1"
    target="$2"
    name="$(zig_name)"
    src="$work/src/$version"
    archive="$archive_dir/$version.tar.gz"

    mkdir -p "$src"
    {
        echo '#!/bin/sh'
        echo "echo $version"
    } > "$src/$name"
    chmod +x "$src/$name"

    tar -C "$src" -czf "$archive" "$name"
    checksum="$(sha256_file "$archive")"
    size="$(file_size "$archive")"
    archive_url_path="$(zvm_path "$archive")"

    cat > "$registry_dir/$version.zon" <<EOF
.{
    .version = "$version",
    .channel = "integration",
    .platforms = .{
        .{
            .target = "$target",
            .url = "file://$archive_url_path",
            .sha256 = "$checksum",
            .size = $size,
        },
    },
}
EOF
}

assert_eq() {
    actual="$1"
    expected="$2"
    label="$3"
    if [ "$actual" != "$expected" ]; then
        echo "$label: expected '$expected', got '$actual'" >&2
        exit 1
    fi
}

mkdir -p "$registry_dir" "$archive_dir"
target="$(target_tag)"
registry_dir_arg="$(zvm_path "$registry_dir")"

if command -v zvm >/dev/null 2>&1; then
    zvm_cmd="zvm"
elif command -v zvm.exe >/dev/null 2>&1; then
    zvm_cmd="zvm.exe"
else
    echo "zvm is not on PATH" >&2
    exit 1
fi

if [ -n "$zvm_home" ]; then
    zvm_home_arg="$(zvm_path "$zvm_home")"
else
    zvm_home_arg=""
fi

make_archive "0.15.2" "$target"
make_archive "0.15.2-esp.r4" "$target"

run_zvm() {
    if [ -n "$zvm_home_arg" ]; then
        ZVM_HOME="$zvm_home_arg" "$zvm_cmd" "$@"
    else
        "$zvm_cmd" "$@"
    fi
}

run_zvm_with_registry() {
    if [ -n "$zvm_home_arg" ]; then
        ZVM_HOME="$zvm_home_arg" ZVM_REGISTRY_DIR="$registry_dir_arg" "$zvm_cmd" "$@"
    else
        ZVM_REGISTRY_DIR="$registry_dir_arg" "$zvm_cmd" "$@"
    fi
}

run_zvm --version
ZVM_REGISTRY_DIR="$registry_dir_arg" "$zvm_cmd" list-remote

run_zvm_with_registry install 0.15.2
run_zvm_with_registry install '0.15.2-esp.*'

run_zvm use 0.15.2
assert_eq "$(run_zvm current)" "0.15.2" "current after use 0.15.2"

run_zvm use '0.15.2-esp.*'
assert_eq "$(run_zvm current)" "0.15.2-esp.r4" "current after use 0.15.2-esp.*"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *)
        if [ -n "$zvm_home_arg" ]; then
            assert_eq "$(PATH="$zvm_home/bin:$PATH" zig)" "0.15.2-esp.r4" "zig through zvm bin"
        else
            assert_eq "$(zig)" "0.15.2-esp.r4" "zig through configured PATH"
        fi
        ;;
esac

run_zvm doctor
