process VG_SURJECT {
    tag "$sample_name"
    publishDir "${params.outdir}/small_variants/intermediate", mode: params.publish_intermediate

    container 'quay.io/vgteam/vg:v1.52.0'

    input:
    tuple val(sample_name), path(gam_file), path(gbz_file)

    output:
    tuple val(sample_name), path("${sample_name}_surject.bam"), emit: bam
    path "${sample_name}_surject.log", emit: log

    // -i: consecutive GAM records are read pairs. The published run lacked it (typo '- i'),
    // producing 0% properly paired BAMs; see the pairing-fix benchmark report.
    script:
    def paths = ((1..22) + ['X', 'Y']).collect { "-p GRCh38#0#chr${it}" }.join(' ')
    """
    vg surject -x ${gbz_file} -b -i -t ${task.cpus} --prune-low-cplx \
        ${paths} \
        ${gam_file} > ${sample_name}_surject.bam 2> ${sample_name}_surject.log
    """
}
