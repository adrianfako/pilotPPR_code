---
type: Runbook
title: PPR fleet rerun on vast hosts
---

# PPR fleet rerun on vast hosts

One Nextflow run per vast host, local executor, no scheduler, no shared storage.
`samples.tsv` assigns the 48 pilot1 samples (24 Aviti, 24 Illumina) to the six hosts,
weighted by cores and free scratch. Per-sample chain is independent, so parallelism is
samples across hosts plus two samples in flight per host (each heavy task takes half the cores).

## Host layout

`/var/lib/docker/ppr/` on the 2-4 TB data disk: `PPR/` (this repo dir), `graph/` (HPRC v1.1
gbz + hapl from s3://human-pangenomics), `ref/` (GRCh38 chr-named Ensembl primary assembly +
fai, from genomics-01), `reads/`, `work/`, `results/`.

Host prerequisites: docker with the `nvidia` runtime (present on vast hosts), openjdk 17,
nextflow. `--gpus all` is refused by the vast docker; the pipeline passes `--runtime=nvidia`.

## Run

```bash
stage.sh pull <box>     # reads for this box's shard (needs RGW reachable from the host)
run.sh                  # resumable; pins DeepVariant to the least-used GPU
stage.sh push <box>     # results to s3://icdg/pilot1/ppr/<box>/
```

Wrap `run.sh` in `nohup` or tmux. `nextflow clean -f` after a successful push frees scratch.

## Differences from the published pipeline

- Multi-sample: sample id comes from the read file names, no `--sample_name`.
- DeepVariant branch no longer waits for `vg call`; both branches run independently.
- `vg surject` reads the sampled GBZ directly; `vg view` and `vg index -x` steps removed.
- Intermediates published as symlinks, finals copied.
- Graph and reference are staged task inputs, no bind mounts.
- `vg surject -i` (interleaved pairs) restored: the published call had `- i`, a no-op, so BAMs were 0% properly paired and DeepVariant ran without insert-size signal. `<sample>.flagstat.txt` in `small_variants/` shows the properly-paired rate. This fix is the reason for the rerun.
- KMC memory follows the task memory instead of a fixed 120 GB.
