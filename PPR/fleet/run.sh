#!/bin/bash
# Run the PPR pipeline on this host over every read pair present in $PPR/reads.
# Usage: run.sh [extra nextflow args]   (PPR=/var/lib/docker/ppr by default)
set -euo pipefail
PPR=${PPR:-/var/lib/docker/ppr}
# DeepVariant gets the card with the least memory in use (renters hold the others).
GPU=$(nvidia-smi --query-gpu=index,memory.used --format=csv,noheader,nounits | sort -t, -k2 -n | head -1 | cut -d, -f1)
cd "$PPR"
exec nextflow run "$PPR/PPR/main.nf" -resume -work-dir "$PPR/work" \
    --reads "$PPR/reads/*_{R1_val_1,R2_val_2,r1_val_1,r2_val_2}.fq.gz" \
    --outdir "$PPR/results" --gpu "$GPU" "$@"
