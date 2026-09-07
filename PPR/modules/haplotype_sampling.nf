process HAPLOTYPE_SAMPLING {
    tag "$sample_name"
    publishDir "${params.outdir}/haplotype_sampling", mode: params.publish_intermediate

    container 'quay.io/vgteam/vg:v1.52.0'

    input:
    tuple val(sample_name), path(kff_file)
    path full_gbz
    path hapl

    output:
    tuple val(sample_name), path("${sample_name}.gbz"), emit: gbz

    script:
    """
    vg haplotypes -v 2 -t ${task.cpus} \
        --include-reference --diploid-sampling \
        -i ${hapl} \
        -k ${kff_file} \
        -g ${sample_name}.gbz \
        ${full_gbz}
    """
}
