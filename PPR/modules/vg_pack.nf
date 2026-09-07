process VG_PACK {
    tag "$sample_name"
    publishDir "${params.outdir}/SV_calling", mode: params.publish_intermediate

    container 'quay.io/vgteam/vg:v1.52.0'

    input:
    tuple val(sample_name), path(gam_file)
    path full_gbz

    output:
    tuple val(sample_name), path("${sample_name}.pack"), emit: pack

    script:
    """
    vg pack -x ${full_gbz} -g ${gam_file} -Q 5 -t ${task.cpus} -o ${sample_name}.pack
    """
}
