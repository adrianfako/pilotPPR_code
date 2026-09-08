#!/usr/bin/env nextflow

include { KMC_COUNT } from './modules/kmc'
include { HAPLOTYPE_SAMPLING } from './modules/haplotype_sampling'
include { VG_GIRAFFE } from './modules/vg_giraffe'
include { VG_PACK } from './modules/vg_pack'
include { VG_CALL } from './modules/vg_call'
include { COMPRESS_INDEX_VCF } from './modules/compress_index'
include { PANGENIE } from './modules/pangenie'
include { SMALLVARIANTS_DEEPVARIANT } from './subworkflows/smallvariants_deepvariant'

workflow {
    if (!params.reads)  error "Please provide a paired-read glob with --reads"
    if (!params.outdir) error "Please provide an output directory with --outdir"

    // Sample id = the part of the file name before the R1/R2 token; one tuple per sample.
    reads_ch = Channel.fromFilePairs(params.reads, checkIfExists: true)

    full_gbz = file(params.graph_gbz, checkIfExists: true)
    hapl     = file(params.graph_hapl, checkIfExists: true)
    ref      = file(params.reference_fasta, checkIfExists: true)
    ref_fai  = file("${params.reference_fasta}.fai", checkIfExists: true)

    KMC_COUNT(reads_ch)
    HAPLOTYPE_SAMPLING(KMC_COUNT.out.kff, full_gbz, hapl)
    VG_GIRAFFE(HAPLOTYPE_SAMPLING.out.gbz.join(reads_ch))

    // Every per-sample pairing goes through join(): with several samples in flight,
    // two independent queue channels would pair by arrival order, not by sample.
    gam_gbz = VG_GIRAFFE.out.gam.join(HAPLOTYPE_SAMPLING.out.gbz)

    // SV branch (vg pack / call) and DeepVariant branch run independently.
    VG_PACK(VG_GIRAFFE.out.gam, full_gbz)
    VG_CALL(VG_PACK.out.pack, full_gbz)
    COMPRESS_INDEX_VCF(VG_CALL.out.vcf)

    if (params.run_deepvariant) {
        SMALLVARIANTS_DEEPVARIANT(gam_gbz, ref, ref_fai)
    }

    // Third caller: k-mer genotyping of the HPRC panel straight from reads, no alignment.
    if (params.run_pangenie) {
        pangenie_index = Channel.fromPath("${params.pangenie_index}*", checkIfExists: true).collect()
        PANGENIE(reads_ch, pangenie_index)
    }
}
