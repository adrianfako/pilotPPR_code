#!/bin/bash
# Pull this box's shard of samples.tsv from the ICDG RGW into $PPR/reads,
# or push results back. Needs AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in env.
# Usage: stage.sh pull <box> [samples.tsv]   |   stage.sh push <box>
set -euo pipefail
PPR=${PPR:-/var/lib/docker/ppr}
EP=${S3_ENDPOINT:-https://s3.icdg.auxilio.ai}
verb=$1; box=$2; tsv=${3:-$(dirname "$0")/samples.tsv}
case "$verb" in
  pull)
    awk -F'\t' -v b="$box" 'NR>1 && $5==b {print $3; print $4}' "$tsv" | while read -r key; do
        aws --endpoint-url "$EP" s3 cp "s3://icdg/$key" "$PPR/reads/$(basename "$key")" --only-show-errors
    done ;;
  push)
    aws --endpoint-url "$EP" s3 sync "$PPR/results/" "s3://icdg/pilot1/ppr/$box/" --only-show-errors ;;
  *) echo "usage: stage.sh pull|push <box> [samples.tsv]" >&2; exit 1 ;;
esac
