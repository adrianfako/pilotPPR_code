process COMPRESS_INDEX_VCF {
    tag "$sample_name"
    publishDir "${params.outdir}/SV_calling", mode: 'copy'

    container 'quay.io/biocontainers/samtools:1.17--h00cdaf9_0'

    input:
    tuple val(sample_name), path(vcf_file)

    output:
    tuple val(sample_name), path("${sample_name}_vgcall.vcf.gz"), path("${sample_name}_vgcall.vcf.gz.tbi"), emit: vcf_gz

    script:
    """
    bgzip -c ${vcf_file} > ${sample_name}_vgcall.vcf.gz
    tabix -p vcf ${sample_name}_vgcall.vcf.gz
    """
}
