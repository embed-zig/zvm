#!/bin/sh
set -eu

repo="${ZVM_REPO:-embed-zig/zvm}"
version="${ZVM_VERSION:-latest}"
install_dir="${ZVM_INSTALL_DIR:-$HOME/.zvm}"
artifact_dir="${ZVM_ARTIFACT_DIR:-}"
bin_dir="$install_dir/bin"

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "zvm installer: missing required command: $1" >&2
        exit 1
    }
}

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        FreeBSD) echo "freebsd" ;;
        *) echo "zvm installer: unsupported OS: $(uname -s)" >&2; exit 1 ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        arm64|aarch64) echo "aarch64" ;;
        *) echo "zvm installer: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
    esac
}

download() {
    url="$1"
    output="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output"
    else
        echo "zvm installer: missing curl or wget" >&2
        exit 1
    fi
}

sha256_file() {
    file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo "zvm installer: missing sha256sum or shasum" >&2
        exit 1
    fi
}

need awk
os="$(detect_os)"
arch="$(detect_arch)"
asset="zvm-$os-$arch.tar.gz"
exe="zvm"
if [ "$os" = "windows" ]; then
    exe="zvm.exe"
fi

if [ "$version" = "latest" ]; then
    base_url="https://github.com/$repo/releases/latest/download"
else
    base_url="https://github.com/$repo/releases/download/$version"
fi

tmp="${TMPDIR:-/tmp}/zvm-install.$$"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT INT TERM

if [ -n "$artifact_dir" ]; then
    echo "Installing $asset from $artifact_dir"
    cp "$artifact_dir/$asset" "$tmp/$asset"
    cp "$artifact_dir/SHA256SUMS" "$tmp/SHA256SUMS"
else
    echo "Downloading $asset from $base_url"
    download "$base_url/$asset" "$tmp/$asset"
    download "$base_url/SHA256SUMS" "$tmp/SHA256SUMS"
fi

expected="$(awk -v asset="$asset" '$2 == asset { print $1 }' "$tmp/SHA256SUMS")"
if [ -z "$expected" ]; then
    echo "zvm installer: SHA256SUMS does not contain $asset" >&2
    exit 1
fi

actual="$(sha256_file "$tmp/$asset")"
if [ "$actual" != "$expected" ]; then
    echo "zvm installer: checksum mismatch for $asset" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
    exit 1
fi

mkdir -p "$bin_dir"
mkdir -p "$tmp/extract"
tar -xzf "$tmp/$asset" -C "$tmp/extract"
cp "$tmp/extract/$exe" "$bin_dir/$exe"
chmod 0755 "$bin_dir/$exe" 2>/dev/null || true

echo "Installed zvm to $bin_dir/$exe"
case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
        echo
        echo "Add zvm to PATH:"
        echo "  export PATH=\"$bin_dir:\$PATH\""
        ;;
esac
