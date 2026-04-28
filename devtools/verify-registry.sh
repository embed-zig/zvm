#!/bin/sh
set -eu

registry_dir="${1:-registry}"
failed=0
required_targets="macos-x86_64 macos-aarch64 linux-x86_64 linux-aarch64 windows-x86_64 windows-aarch64"

if [ ! -d "$registry_dir" ]; then
    echo "registry directory not found: $registry_dir" >&2
    exit 1
fi

for file in "$registry_dir"/*.zon; do
    [ -e "$file" ] || continue
    name="$(basename "$file" .zon)"

    case "$name" in
        *[!0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.+-]*|"")
            echo "$file: invalid version filename" >&2
            failed=1
            ;;
    esac

    if ! awk -v version="$name" '
        $1 == ".version" && $2 == "=" {
            gsub(/[",]/, "", $3)
            found = ($3 == version)
        }
        END { exit(found ? 0 : 1) }
    ' "$file"; then
        echo "$file: .version does not match filename" >&2
        failed=1
    fi

    if ! awk '
        $1 == ".sha256" && $2 == "=" {
            value = $3
            gsub(/[",]/, "", value)
            if (value !~ /^[0-9a-f]{64}$/) bad = 1
        }
        END { exit(bad ? 1 : 0) }
    ' "$file"; then
        echo "$file: sha256 must be 64 lowercase hex characters" >&2
        failed=1
    fi

    for target in $required_targets; do
        if ! awk -v target="$target" '
            $1 == ".target" && $2 == "=" {
                value = $3
                gsub(/[",]/, "", value)
                if (value == target) found = 1
            }
            END { exit(found ? 0 : 1) }
        ' "$file"; then
            echo "$file: missing required target $target" >&2
            failed=1
        fi
    done
done

exit "$failed"
