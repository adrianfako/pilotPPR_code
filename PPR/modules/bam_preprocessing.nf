process BAM_PREPROCESSING {
    tag "$sample_name"
    publishDir "${params.outdir}/small_variants", mode: 'copy'

    container 'quay.io/biocontainers/samtools:1.17--h00cdaf9_0'

    input:
    tuple val(sample_name), path(bam_file)

    output:
    tuple val(sample_name), path("${sample_name}_chr_named_rg.bam"), path("${sample_name}_chr_named_rg.bam.bai"), emit: bam
    path "${sample_name}.flagstat.txt", emit: flagstat

    script:
    def mem_per_thread = Math.max(1, (task.memory.toGiga() * 0.6 / task.cpus).intValue())
    """
    samtools sort -@ ${task.cpus} -m ${mem_per_thread}G -o ${sample_name}.sorted.bam ${bam_file}
    samtools view -H ${sample_name}.sorted.bam | sed 's/SN:GRCh38#0#chr/SN:chr/' > new_header.sam
    samtools reheader new_header.sam ${sample_name}.sorted.bam > ${sample_name}_chr_named.bam
    rm -f ${sample_name}.sorted.bam
    samtools addreplacerg --threads ${task.cpus} \
        -r '@RG\tID:${sample_name}\tSM:${sample_name}\tPL:ILLUMINA\tLB:lib1\tPU:unit1' \
        -o ${sample_name}_chr_named_rg.bam ${sample_name}_chr_named.bam
    rm -f ${sample_name}_chr_named.bam
    samtools index -@ ${task.cpus} ${sample_name}_chr_named_rg.bam
    samtools flagstat -@ ${task.cpus} ${sample_name}_chr_named_rg.bam > ${sample_name}.flagstat.txt
    """
}
