#!/usr/bin/env zsh
#
# apply.sh
# Copies every file in this repo to the same relative path under $HOME,
# creating any missing directories along the way. Anything it's about to
# overwrite gets backed up first, so nothing is silently lost.
#
# Usage:
#   ./apply.sh          # copy files, with backups (asks to confirm first)
#   ./apply.sh --force  # skip the confirmation prompt

set -euo pipefail

REPO_DIR="${0:A:h}"
TARGET_HOME="${HOME}"
BACKUP_DIR="${TARGET_HOME}/.hyde-customizations-backup/$(date +%Y%m%d-%H%M%S)"

FORCE=false

# Files/dirs at the repo root that should never be installed
EXCLUDES=(".git" ".gitignore" "README.md" "LICENSE" "apply.sh")

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

is_excluded() {
    local rel="$1"
    for ex in "${EXCLUDES[@]}"; do
        [[ "$rel" == "$ex" || "$rel" == "$ex/"* ]] && return 0
    done
    return 1
}

echo "Repo:   $REPO_DIR"
echo "Target: $TARGET_HOME"
echo

if ! $FORCE; then
    read -r "reply?Proceed applying customizations onto $TARGET_HOME? [y/N] "
    [[ "$reply" == [Yy] ]] || { echo "Aborted."; exit 1; }
fi

mkdir_backup_dir_once() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
    fi
}

install_file() {
    local src="$1"
    local rel="${src#"$REPO_DIR"/}"
    local dest="${TARGET_HOME}/${rel}"
    local dest_dir="${dest:h}"

    echo "-> $rel"

    mkdir -p "$dest_dir"

    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir_backup_dir_once
        local backup_target="${BACKUP_DIR}/${rel}"
        mkdir -p "${backup_target:h}"
        mv "$dest" "$backup_target"
    fi

    cp -p "$src" "$dest"
}

count=0
files=("${(@f)$(find "$REPO_DIR" -type f)}")
for file in "${files[@]}"; do
    [[ -z "$file" ]] && continue
    rel="${file#"$REPO_DIR"/}"
    is_excluded "$rel" && continue
    install_file "$file"
    count=$((count + 1))
done

echo
echo "Done. $count file(s) processed."
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backups (if any) saved to: $BACKUP_DIR"
fi
