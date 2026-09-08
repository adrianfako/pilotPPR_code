process PANGENIE {
    tag "$sample_name"
    publishDir "${params.outdir}/pangenie", mode: 'copy'

    container 'quay.io/biocontainers/pangenie:4.2.1--h077b44d_0'

    input:
    tuple val(sample_name), path(reads)
    path index_files

    output:
    tuple val(sample_name), path("${sample_name}_pangenie_genotyping.vcf.gz"), path("${sample_name}_pangenie_genotyping.vcf.gz.tbi"), emit: vcf
    path "${sample_name}_pangenie.log", emit: log

    script:
    // PanGenie reads only uncompressed FASTQ; the concatenated copy lives in this task dir and dies with it.
    """
    zcat ${reads} > reads.fq
    PanGenie -f ${params.pangenie_index} -i reads.fq -s ${sample_name} \
        -o ${sample_name}_pangenie -t ${Math.min(task.cpus, 24)} -j ${task.cpus} \
        > ${sample_name}_pangenie.log 2>&1
    rm -f reads.fq
    bgzip -@ ${task.cpus} ${sample_name}_pangenie_genotyping.vcf
    tabix -p vcf ${sample_name}_pangenie_genotyping.vcf.gz
    """
}
