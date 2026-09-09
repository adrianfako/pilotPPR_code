---
type: Runbook
title: PPR fleet rerun on vast hosts
---

# PPR fleet rerun on vast hosts

One Nextflow run per vast host, local executor, no scheduler, no shared storage.
`samples.tsv` assigns the 48 pilot1 samples (24 patients, each on Aviti and Illumina) to the
six hosts, both instruments of a patient on the same host, balanced by bytes over cores and
free scratch. Per-sample chain is independent, so parallelism is
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
- Third caller `PANGENIE` (PanGenie 4.2.1): k-mer genotyping of the HPRC v1.1 panel
  (`hprc-v1.1-mc-grch38.vcf.gz`, vcfbub-filtered, 45 samples) straight from the reads, no
  alignment. One-time index per fleet: `graph/pangenie/build-index.sh` (PanGenie-index
  against the same chr-named GRCh38; panel and reference uncompressed). The published panel
  needs three fixes first, all in that script: drop the haploid CHM13 column, write single
  alleles on male chrX/chrY as g|g, keep only contigs the fasta has. Index: 36 min, 234 GB
  peak (build on a 377 GB host, copy elsewhere), 29 GB. Per sample the reads are
  decompressed into the task dir (~3x the gz size, transient). `--run_pangenie false` skips it.

## Pilot ICDG24 on R5, 2026-09-07 (36 cores, 18 threads per task)

| step | wall | peak RSS |
|---|---|---|
| KMC_COUNT | 5m 43s | 122 GB |
| HAPLOTYPE_SAMPLING | 6m 3s | 37 GB |
| VG_GIRAFFE | 1h 32m | 61 GB |
| VG_PACK | 17m 37s | 64 GB |
| VG_CALL | 39m 22s | 50 GB |
| VG_SURJECT (GBZ, -i) | 1h 51m | 14 GB |
| BAM_PREPROCESSING | 13m 56s | 80 GB |
| DEEPVARIANT (18 shards) | 3h 21m | 57 GB |
| PANGENIE (18 threads, incl. 20 min zcat) | 3h 3m | 78 GB |

Illumina pair of the same patient (24ICDG_S24, 60 GB, 780 M reads), 2026-09-08/09, DeepVariant on
the whole box: KMC 10m, haplotypes 7m, giraffe 2h 58m, pack 34m, call 46m, surject 5h 12m, sort
33m, DeepVariant 2h 40m (104 GB, 36 shards), PanGenie 3h 10m in parallel. 14h 51m wall, ~340 CPU
hours, 96.07% properly paired. Time scales with reads; one patient (both instruments) is about a
host-day with two samples in flight.

7h 11m wall, 146 CPU hours, 228 GB scratch. Final BAM 323.7 M reads, 95.91% properly
paired, 0 supplementary. DeepVariant VCF 4.61 M PASS. DeepVariant split: make_examples
2h 42m, call_variants 13m, postprocess 26m; the config now gives DEEPVARIANT the whole box.
Kaalia's nvidia runtime rewrites `NVIDIA_VISIBLE_DEVICES` to `void` inside the container
but still injects the requested card (CDI mode); `nvidia-smi -L` inside shows it.

