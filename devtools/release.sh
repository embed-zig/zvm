#!/bin/sh
set -eu

version="${1:-}"
if [ -z "$version" ]; then
    echo "usage: devtools/release.sh <version>" >&2
    exit 64
fi

if ! command -v zig >/dev/null 2>&1; then
    echo "release requires zig on PATH" >&2
    exit 1
fi

sha256_manifest() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$@"
    else
        shasum -a 256 "$@"
    fi
}

targets="
x86_64-linux
aarch64-linux
x86_64-macos
aarch64-macos
x86_64-windows
aarch64-windows
"

dist="dist/$version"
build_dir="$dist/build"
rm -rf "$dist"
mkdir -p "$build_dir"

for target in $targets; do
    echo "building $target"
    zig build -Doptimize=ReleaseSafe -Dtarget="$target" --prefix "$build_dir/$target"
    os="$(printf '%s' "$target" | awk -F- '{print $2}')"
    arch="$(printf '%s' "$target" | awk -F- '{print $1}')"
    exe="$build_dir/$target/bin/zvm"
    exe_name="zvm"
    if [ "$os" = "windows" ]; then
        exe="$exe.exe"
        exe_name="zvm.exe"
    fi
    cp "$exe" "$build_dir/$target/$exe_name"
    tar -C "$build_dir/$target" -czf "$dist/zvm-$os-$arch.tar.gz" "$exe_name"
done

awk -v release_version="$version" '
    $0 == "version=\"${ZVM_VERSION:-latest}\"" {
        print "version=\"${ZVM_VERSION:-" release_version "}\""
        next
    }
    { print }
' install.sh > "$dist/install.sh"
chmod +x "$dist/install.sh"
rm -rf "$build_dir"

(
    cd "$dist"
    sha256_manifest zvm-*.tar.gz install.sh > SHA256SUMS
)

echo "release artifacts written to $dist"
