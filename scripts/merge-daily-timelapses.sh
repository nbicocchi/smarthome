#!/usr/bin/env bash
set -Eeuo pipefail

FFMPEG_IMAGE="jrottenberg/ffmpeg:latest"
TODAY=$(date +%Y%m%d)
export LC_ALL=C

DELETE_ORIGINALS=false
DIRECTORY_SET=false
while (( $# )); do
    case "$1" in
    --help)
    cat <<EOF
Usage: $0 [--delete] DIRECTORY
       $0 --help

Merge each day's timelapse videos without re-encoding, excluding today.
Existing daily videos are skipped.

  --delete  Delete original videos after a successful merge.
  --help    Show this help message and exit.
EOF
    exit 0
    ;;
    --delete) DELETE_ORIGINALS=true ;;
    -*) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    *)
        if [[ $DIRECTORY_SET == true ]]; then
            echo "ERROR: only one directory may be specified" >&2
            exit 1
        fi
        DIRECTORY=$1
        DIRECTORY_SET=true
        ;;
    esac
    shift
done

if [[ $DIRECTORY_SET == false ]]; then
    echo "ERROR: directory is required. Usage: $0 [--delete] DIRECTORY" >&2
    exit 1
fi
[[ -d "$DIRECTORY" ]] || { echo "ERROR: directory not found: $DIRECTORY" >&2; exit 1; }
DIRECTORY=$(cd -- "$DIRECTORY" && pwd -P)
command -v docker >/dev/null || { echo "ERROR: docker not found in PATH" >&2; exit 1; }
command -v flock >/dev/null || { echo "ERROR: flock not found in PATH" >&2; exit 1; }

exec 9>"$DIRECTORY/.unisci-timelapse.lock"
flock -n 9 || { echo "ERROR: script already running" >&2; exit 1; }

LIST=""
TEMP_VIDEO=""
cleanup() {
    [[ -z "$LIST" ]] || rm -f -- "$LIST"
    [[ -z "$TEMP_VIDEO" ]] || rm -f -- "$TEMP_VIDEO"
}
trap cleanup EXIT

shopt -s nullglob
declare -A days=()
for video in "$DIRECTORY"/tlapse_video_????????_??????.mp4; do
    name=${video##*/}
    if [[ $name =~ ^tlapse_video_([0-9]{8})_[0-9]{6}\.mp4$ ]]; then
        day=${BASH_REMATCH[1]}
        [[ $day == "$TODAY" ]] || days["$day"]=1
    fi
done

for day in $(printf '%s\n' "${!days[@]}" | sort); do
    output="$DIRECTORY/tlapse_${day}.mp4"
    if [[ -e "$output" ]]; then
        continue
    fi

    LIST=$(mktemp "$DIRECTORY/.tlapse-list.XXXXXXXX")
    TEMP_VIDEO=$(mktemp "$DIRECTORY/.tlapse-video.XXXXXXXX.mp4")
    originals=()
    for video in "$DIRECTORY"/tlapse_video_"$day"_??????.mp4; do
        name=${video##*/}
        [[ $name =~ ^tlapse_video_[0-9]{8}_[0-9]{6}\.mp4$ ]] || continue
        originals+=("$video")
        printf "file '%s'\n" "$name" >> "$LIST"
    done

    docker run --rm --user "$(id -u):$(id -g)" \
        -v "$DIRECTORY:$DIRECTORY" "$FFMPEG_IMAGE" \
        -nostdin -v error -f concat -safe 1 -i "$LIST" -map 0 -c copy -y "$TEMP_VIDEO"
    ln -- "$TEMP_VIDEO" "$output"
    rm -f -- "$TEMP_VIDEO"
    rm -f -- "$LIST"
    LIST=""
    TEMP_VIDEO=""
    if [[ $DELETE_ORIGINALS == true ]]; then
        rm -- "${originals[@]}"
    fi
    echo "Created: $output"
done
