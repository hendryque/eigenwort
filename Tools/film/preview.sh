#!/bin/bash
# Renders the App Store preview at the three sizes App Store Connect may ask
# for and encodes each to Apple's spec: H.264 High at 10 Mbps, 256 kbps
# stereo AAC (silent), the index at the front. Output in out/preview/.
set -euo pipefail
cd "$(dirname "$0")"
/bin/mkdir -p out/preview
for size in Preview:886x1920 PreviewMedium:1206x2622 PreviewLarge:1320x2868; do
    id="${size%%:*}"; name="${size##*:}"
    # Apple's level 4.0 covers 886 × 1920; the device sizes need 5.1.
    level=4.0; [ "$name" = 886x1920 ] || level=5.1
    npx remotion render "$id" "out/preview/$name-silent.mp4" --codec=h264 --crf=14
    ffmpeg -y -v error -i "out/preview/$name-silent.mp4" -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 \
        -c:v libx264 -profile:v high -level:v "$level" -pix_fmt yuv420p -b:v 10M -maxrate 12M -bufsize 20M -r 30 -vf setsar=1 \
        -c:a aac -b:a 256k -ar 44100 -ac 2 -movflags +faststart -shortest "out/preview/eigenwort-preview-$name.mp4"
    /bin/rm "out/preview/$name-silent.mp4"
done
