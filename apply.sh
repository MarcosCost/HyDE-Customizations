#!/usr/bin/env zsh
#
#   WARNING: This script may be Unreliable. Use at your own risk. It is recommended to review the code before running it.
#            It has not undergone ANY testing and may break your Arch + HyDE Installation.
#
# apply.sh
# Copies every file in this repo to the same relative path under $HOME,
# and every file under root/ to the same relative path under /,
# creating any missing directories along the way. Anything it's about to
# overwrite gets backed up first, so nothing is silently lost.
#
# Usage:
#   ./apply.sh          # copy files, with backups (asks to confirm first)
#   ./apply.sh --force  # skip the confirmation prompt

set -euo pipefail

REPO_DIR="${0:A:h}"
TARGET_HOME="${HOME}"
ROOT_SRC_DIR="${REPO_DIR}/root"
TARGET_ROOT="/"
BACKUP_DIR="${TARGET_HOME}/.hyde-customizations-backup/$(date +%Y%m%d-%H%M%S)"

FORCE=false

# Files/dirs at the repo root that should never be installed under $HOME.
# "root" is excluded here because it's handled separately, below.
EXCLUDES=(".git" ".gitignore" "README.md" "LICENSE" "apply.sh" "root")

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
[[ -d "$ROOT_SRC_DIR" ]] && echo "Also installing root/ -> $TARGET_ROOT (requires sudo)"
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

# install_file SRC SRC_ROOT DEST_ROOT BACKUP_SUBDIR USE_SUDO
install_file() {
    local src="$1" src_root="$2" dest_root="$3" backup_subdir="$4" use_sudo="$5"
    local rel="${src#"$src_root"/}"
    local dest="${dest_root}/${rel}"
    local dest_dir="${dest:h}"
    local sudo_cmd=()
    $use_sudo && sudo_cmd=(sudo)

    echo "-> $rel"

    "${sudo_cmd[@]}" mkdir -p "$dest_dir"

    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir_backup_dir_once
        local backup_target="${BACKUP_DIR}/${backup_subdir}/${rel}"
        mkdir -p "${backup_target:h}"
        "${sudo_cmd[@]}" mv "$dest" "$backup_target"
    fi

    "${sudo_cmd[@]}" cp -p "$src" "$dest"
}

count=0

# --- $HOME tree ---
files=("${(@f)$(find "$REPO_DIR" -type f -not -path "*/.git/*")}")
for file in "${files[@]}"; do
    [[ -z "$file" ]] && continue
    rel="${file#"$REPO_DIR"/}"
    is_excluded "$rel" && continue
    install_file "$file" "$REPO_DIR" "$TARGET_HOME" "home" false
    count=$((count + 1))
done

# --- / tree (root/ folder in the repo) ---
if [[ -d "$ROOT_SRC_DIR" ]]; then
    root_files=("${(@f)$(find "$ROOT_SRC_DIR" -type f)}")
    for file in "${root_files[@]}"; do
        [[ -z "$file" ]] && continue
        install_file "$file" "$ROOT_SRC_DIR" "$TARGET_ROOT" "root" true
        count=$((count + 1))
    done
fi

echo
echo "Done. $count file(s) processed."
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backups (if any) saved to: $BACKUP_DIR"
fi