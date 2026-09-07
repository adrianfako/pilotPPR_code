process VG_GIRAFFE {
    tag "$sample_name"
    publishDir "${params.outdir}/alignment", mode: params.publish_intermediate

    container 'quay.io/vgteam/vg:v1.52.0'

    input:
    tuple val(sample_name), path(gbz_file), path(reads)

    output:
    tuple val(sample_name), path("${sample_name}.gam"), emit: gam
    path "${sample_name}_align.err", emit: log

    script:
    // giraffe writes its .dist/.min indexes next to the GBZ; keep them in this task dir,
    // not in the upstream task dir the staged symlink points at.
    """
    cp -L ${gbz_file} local.gbz
    vg giraffe -v 2 -p -t ${task.cpus} -Z local.gbz \
        -f ${reads[0]} \
        -f ${reads[1]} \
        > ${sample_name}.gam 2> ${sample_name}_align.err
    rm -f local.gbz
    """
}
