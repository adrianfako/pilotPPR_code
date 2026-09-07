include { VG_SURJECT } from '../modules/vg_surject.nf'
include { BAM_PREPROCESSING } from '../modules/bam_preprocessing.nf'
include { DEEPVARIANT } from '../modules/deepvariant.nf'

workflow SMALLVARIANTS_DEEPVARIANT {
    take:
    gam_gbz     // tuple val(sample_name), path(gam), path(sampled_gbz)
    ref         // path(reference fasta)
    ref_fai     // path(reference fasta index)

    main:
    // vg surject reads the sampled GBZ directly; no vg view / vg index XG detour.
    VG_SURJECT(gam_gbz)
    BAM_PREPROCESSING(VG_SURJECT.out.bam)
    DEEPVARIANT(BAM_PREPROCESSING.out.bam, ref, ref_fai)

    emit:
    vcf = DEEPVARIANT.out.vcf
    gvcf = DEEPVARIANT.out.gvcf
    bam = BAM_PREPROCESSING.out.bam
}
