#!/usr/bin/env bash
set -u

sanitize() {
    printf '%s' "$1" | tr '\t\r\n' '   '
}

count_lines() {
    awk 'NF { count++ } END { print count + 0 }'
}

emit_generic_df() {
    local include_btrfs="$1"

    df -B1 -P -T 2>/dev/null | awk -v include_btrfs="$include_btrfs" '
        NR == 1 { next }
        {
            source=$1
            type=$2
            size=$3
            used=$4
            avail=$5
            pct=$6

            $1=$2=$3=$4=$5=$6=""
            sub(/^[[:space:]]+/, "", $0)
            target=$0

            if (type == "btrfs" && include_btrfs != "1")
                next

            gsub(/\t/, " ", source)
            gsub(/\t/, " ", type)
            gsub(/\t/, " ", target)
            sub(/%$/, "", pct)

            printf "GENERIC\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                source, type, size, used, avail, pct, target
        }
    '
}

usage_value() {
    local key="$1"
    local data="$2"

    printf '%s\n' "$data" | awk -v key="$key" '
        {
            line=$0
            sub(/^[[:space:]]+/, "", line)
            prefix=key ":"

            if (index(line, prefix) != 1)
                next

            sub(/^[^:]*:[[:space:]]*/, "", line)

            if (match(line, /^[0-9]+/)) {
                print substr(line, RSTART, RLENGTH)
                exit
            }
        }
    '
}

if ! command -v btrfs >/dev/null 2>&1 || ! command -v findmnt >/dev/null 2>&1; then
    emit_generic_df 1
    exit 0
fi

emit_generic_df 0

mapfile -t btrfs_targets < <(findmnt -rn -t btrfs -o TARGET 2>/dev/null)
((${#btrfs_targets[@]} > 0)) || exit 0

declare -A seen_pool
declare -A pool_mount
declare -A pool_uuid
declare -A pool_source

# UUID identifies the real Btrfs filesystem. This deliberately merges mounts
# such as / and /home when they are subvolumes of the same Btrfs partition.
for target in "${btrfs_targets[@]}"; do
    [[ -n "$target" && -e "$target" ]] || continue

    uuid="$(findmnt -n -T "$target" -o UUID 2>/dev/null | head -n 1 || true)"
    source="$(findmnt -n -T "$target" -o SOURCE 2>/dev/null | head -n 1 || true)"

    # findmnt may report /dev/nvme0n1p2[/@home]. Keep the backing device.
    source="${source%%\[*}"

    if [[ -n "$uuid" ]]; then
        key="uuid:$uuid"
    elif [[ -n "$source" ]]; then
        key="source:$source"
    else
        fsid="$(stat -f -c '%i' -- "$target" 2>/dev/null || true)"
        [[ -n "$fsid" ]] || continue
        key="fsid:$fsid"
    fi

    if [[ -z "${seen_pool[$key]+x}" ]]; then
        seen_pool[$key]=1
        pool_mount[$key]="$target"
        pool_uuid[$key]="$uuid"
        pool_source[$key]="$source"
    elif [[ "$target" == "/" ]]; then
        # Prefer / as the representative mount when this filesystem contains it.
        pool_mount[$key]="/"
    fi
done

for key in "${!seen_pool[@]}"; do
    target="${pool_mount[$key]}"
    uuid="${pool_uuid[$key]}"
    source="${pool_source[$key]}"

    usage="$(btrfs filesystem usage -b "$target" 2>/dev/null || true)"
    device_size="$(usage_value "Device size" "$usage")"
    allocated="$(usage_value "Device allocated" "$usage")"
    unallocated="$(usage_value "Device unallocated" "$usage")"
    used="$(usage_value "Used" "$usage")"
    free_estimated="$(usage_value "Free (estimated)" "$usage")"

    # If Btrfs-specific accounting cannot be read, gracefully fall back to a
    # conventional filesystem card for the representative mount.
    if [[ -z "$device_size" ]]; then
        df -B1 -P -T "$target" 2>/dev/null | awk '
            NR == 2 {
                source=$1
                type=$2
                size=$3
                used=$4
                avail=$5
                pct=$6

                $1=$2=$3=$4=$5=$6=""
                sub(/^[[:space:]]+/, "", $0)
                target=$0
                sub(/%$/, "", pct)

                printf "GENERIC\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                    source, type, size, used, avail, pct, target
            }
        '
        continue
    fi

    label="$(btrfs filesystem label "$target" 2>/dev/null || true)"
    subvolume_count="$(btrfs subvolume list "$target" 2>/dev/null | count_lines)"

    mapfile -t snapshots < <(
        btrfs subvolume list -s "$target" 2>/dev/null \
            | sed -n 's/^.* path //p'
    )
    snapshot_count="${#snapshots[@]}"

    printf 'BTRFS_POOL\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(sanitize "$key")" \
        "$(sanitize "$uuid")" \
        "$(sanitize "$label")" \
        "$(sanitize "$target")" \
        "$(sanitize "$source")" \
        "${device_size:-0}" \
        "${allocated:-0}" \
        "${unallocated:-0}" \
        "${used:-0}" \
        "${free_estimated:-0}" \
        "${subvolume_count:-0}" \
        "${snapshot_count:-0}"

    for snapshot in "${snapshots[@]}"; do
        [[ -n "$snapshot" ]] || continue
        printf 'BTRFS_SNAPSHOT\t%s\t%s\n' \
            "$(sanitize "$key")" \
            "$(sanitize "$snapshot")"
    done
done
