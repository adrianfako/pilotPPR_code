process KMC_COUNT {
    tag "$sample_name"
    publishDir "${params.outdir}/kmc", mode: params.publish_intermediate

    container 'quay.io/biocontainers/kmc:3.2.4--h5ca1c30_4'

    input:
    tuple val(sample_name), path(reads)

    output:
    tuple val(sample_name), path("${sample_name}.kff"), emit: kff

    script:
    def mem_gb = Math.max(8, task.memory.toGiga() - 8)
    """
    printf '%s\n' ${reads} > kmc_input.txt
    mkdir -p kmc_tmp
    kmc -k29 -m${mem_gb} -okff -t${task.cpus} -hp @kmc_input.txt ${sample_name} kmc_tmp
    rm -rf kmc_tmp
    """
}
