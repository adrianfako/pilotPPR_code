process DEEPVARIANT {
    tag "$sample_name"
    publishDir "${params.outdir}/small_variants", mode: 'copy'

    container 'google/deepvariant:1.9.0-gpu'
    containerOptions "${params.docker_gpu_opts}"

    input:
    tuple val(sample_name), path(bam_file), path(bai_file)
    path ref
    path ref_fai

    output:
    tuple val(sample_name), path("${sample_name}.deepvariant.vcf.gz"), emit: vcf
    tuple val(sample_name), path("${sample_name}.deepvariant.g.vcf.gz"), emit: gvcf

    script:
    """
    /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \
        --ref=${ref} \
        --reads=${bam_file} \
        --output_vcf=${sample_name}.deepvariant.vcf.gz \
        --output_gvcf=${sample_name}.deepvariant.g.vcf.gz \
        --num_shards=${task.cpus} \
        --intermediate_results_dir=dv_tmp \
        --make_examples_extra_args="min_mapping_quality=1,keep_legacy_allele_counter_behavior=true,normalize_reads=true"
    rm -rf dv_tmp
    """
}
