process COMPRESS_INDEX_VCF {
    tag "$sample_name"
    publishDir "${params.outdir}/${subdir}", mode: 'copy'

    container 'quay.io/biocontainers/samtools:1.17--h00cdaf9_0'

    input:
    tuple val(sample_name), path(vcf_file)
    val subdir

    output:
    tuple val(sample_name), path("${vcf_file.baseName}.vcf.gz"), path("${vcf_file.baseName}.vcf.gz.tbi"), emit: vcf_gz

    script:
    """
    bgzip -@ ${task.cpus} -c ${vcf_file} > ${vcf_file.baseName}.vcf.gz
    tabix -p vcf ${vcf_file.baseName}.vcf.gz
    """
}
