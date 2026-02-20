#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-Anchor_demo_AI.mov}"
OUTPUT="${2:-Anchor_demo_AI_compressed.mp4}"

# Requires ffmpeg installed.
# Example:
#   ./scripts/compress_onboarding_video.sh AnchorApp/Resources/Anchor_demo_AI.mov AnchorApp/Resources/Anchor_demo_AI.mp4
ffmpeg -i "$INPUT" -vf "scale='min(720,iw)':-2" -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -crf 28 -preset medium -an "$OUTPUT"
