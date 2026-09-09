process getVersionsBwaSamtools {

    output:
    stdout emit: out
    
    shell:
    """
    ( bwa-mem2 version | grep . | awk '{print "bwa-mem2 "\$0}' && samtools version ) | head -3

    """
}

process getVersionGatk3 {

    output:
    stdout emit: out
    
    shell:
    """
    gatk3 --version

    """
}

process getVersionGatk4 {

    label 'gatk4'

    output:
    stdout emit: out
    
    shell:
    """
    gatk --version 2> /dev/null

    """
}

process print_sample_info {
    tag { sample_id }
    echo true
    
    input:
    tuple val(sample_id), val(population), val(inpath), val(outpath), val(single_sample), val(platform)
    
    output:
    tuple val(sample_id), val(population), val(inpath), val(outpath), val(single_sample), val(platform)
    
    script:
    """
    printf "[sample_info] sample: ${sample_id}\tpop: ${population}\tinpath: ${inpath}\toutpath: ${outpath}\tsingle_sample: ${single_sample}\tpop: ${platform}\n"
    """
}


process print_sample_info2 {
    tag { sample_id }
    echo true

    input:
    tuple val(sample_id), val(population), val(outpath), val(alignedbam), val(alignedbai), val(single_sample)

    output:
    tuple val(sample_id), val(population), val(outpath), val(alignedbam), val(alignedbai), val(single_sample)

    script:
    """
    printf "[sample_info] sample: ${sample_id}\tpop: ${population}\toutpath: ${outpath}\talignedbam: ${alignedbam}\talignedbai: ${alignedbai}\tsingle_sample: ${single_sample}\n"
    """
}


process bwa_index {
    tag { reference }

    publishDir "${params.referenceDir}", mode: 'move', pattern: "${reference.simpleName}*"
    file(params.reference).copyTo(params.referenceDir)
    
    input:
    path(reference)

    output:
    path("${reference.simpleName}.*")
    

    script:    
    """
    bwa-mem2 index ${reference}
    samtools faidx ${reference}
    samtools dict ${reference} > "${reference.simpleName}.dict"
    """
}


process download_sample_allas {
    tag { sample_id }
    debug true

    input:
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)
        
    output:
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)

    script:    
    """
    module load allas/0.0.1
    mkdir -p "$params.datadir/${platform}/${pop}/${sample_id}"
    echo ${inpath} | sed 's/,/ /g' | xargs -n1 | while read path; do
      s3cmd ls \$path/ | grep gz  | while read a b c file; do
        s3cmd get --skip-existing -q \$file "$params.datadir/${platform}/${pop}/${sample_id}/"
      done
    done  
    """
}

process download_sample_allas_echo {
    tag { sample_id }
    debug true

    input:
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)
        
    output:
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)

    script:    
    """
    echo ${inpath} | sed 's/,/ /' | xargs -n1 | while read path; do
      echo "s3cmd ls \$path/" 
    done
    """
}


process upload_sample_allas {
    tag { sample_id }
    debug true
    errorStrategy 'finish'

    input:
    tuple val(sample_id), val(pop), val(outpath), path(gvcf_path), val(single_sample),val(platform)
        
    output:
    val(sample_id)
        
    script:
    
    """
    if [[ ${single_sample} == "false" ]]; then
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz"         "${outpath}/${pop}/${sample_id}/${sample_id}.gvcf.gz"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi"     "${outpath}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam"     "${outpath}/${pop}/${sample_id}/${sample_id}_markdup.bam"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai" "${outpath}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai"
    else
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz"         "${outpath}/${sample_id}.gvcf.gz"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi"     "${outpath}/${sample_id}.gvcf.gz.tbi"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam"     "${outpath}/${sample_id}_markdup.bam"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai" "${outpath}/${sample_id}_markdup.bam.bai"
    fi

    if [[ ${params.clean_files} == true ]]; then
        rm "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz"     "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi" \
           "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam" "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai"
    fi
    """
}

process upload_sample_allas2 {
    tag { sample_id }
    debug true
    
    input:
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)
    
    output:
    val(sample_id)
    
    script:
    
    """
    if [[ ${single_sample} == "false" ]]; then
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz" "${outpath}/${pop}/${sample_id}/${sample_id}.gvcf.gz"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi" "${outpath}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam" "${outpath}/${pop}/${sample_id}/${sample_id}_markdup.bam"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai" "${outpath}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai"
    else
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz" "${outpath}/${sample_id}.gvcf.gz"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi" "${outpath}/${sample_id}.gvcf.gz.tbi"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam" "${outpath}/${sample_id}_markdup.bam"
      s3cmd put -q "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai" "${outpath}/${sample_id}_markdup.bam.bai"
    fi

    if [[ ${params.clean_files} == true ]]; then
        rm "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz"     "$params.output/${platform}/${pop}/${sample_id}/${sample_id}.gvcf.gz.tbi" \
           "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam" "$params.output/${platform}/${pop}/${sample_id}/${sample_id}_markdup.bam.bai"
    fi
    """
}


process map_sort_sample {
    tag { sample_id }
    errorStrategy 'finish'
    debug true
    
    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(inpath), val(outpath), val(single_sample), val(platform)
    
    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_aligned.bam"), path("${sample_id}_aligned.bam.bai"), val(single_sample), val(platform)

    script:
    def refname = refindexes[0].simpleName
    def readgroup= "@RG\\tID:$sample_id\\tLB:Lib\\tSM:$sample_id\\tPL:Plfm"
    
    """    
    module load bwa-mem2/2.2
    module load samtools/1.16.1
    fastq1="\$(ls ${params.datadir}/${platform}/${pop}/${sample_id}/* | grep -F -e .1.fq.gz -e _1.fq.gz -e .1.fastq.gz -e _1.fastq.gz -e R1.fastq.gz -e _R1_001.fastq.gz )"
    fastq2="\$(ls ${params.datadir}/${platform}/${pop}/${sample_id}/* | grep -F -e .2.fq.gz -e _2.fq.gz -e .2.fastq.gz -e _2.fastq.gz -e R2.fastq.gz -e _R2_001.fastq.gz )"
    echo \${fastq1},\${fastq2}

    bwa-mem2 mem -R \"${readgroup}\" -t ${params.nr_threads} -K 100000000 -Y ${refname}.fa <(cat \${fastq1}) <(cat \${fastq2}) \
    | samtools view -h - | samtools fixmate -m -  "${sample_id}_mapped.bam"

    samtools sort -@ ${params.nr_threads} "${sample_id}_mapped.bam" -o "${sample_id}_sorted.bam"
    
    samtools view -h "${sample_id}_sorted.bam" | samtools view -h -O bam -o "${sample_id}_aligned.bam" && \
    samtools index -@ ${params.nr_threads} "${sample_id}_aligned.bam"
    
    if [[ ${params.clean_files} == true ]]; then
        rm \$fastq1 \$fastq2 "${sample_id}_mapped.bam" "${sample_id}_sorted.bam"
    fi
    """    
}

process realign_sample {
    tag { sample_id }
    errorStrategy 'finish'
    
    publishDir "${params.output}/${platform}/${pop}/${sample_id}", mode: 'move', pattern: "*bam*"

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_markdup.bam"), path("${sample_id}_markdup.bam.bai"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"
    
    """    
     gatk3 \
    -T RealignerTargetCreator \
    -R ${refname} \
    -I ${alignedbam} \
    -nt ${params.nr_threads} \
    -o targets.intervals
    
    gatk3 \
    -T IndelRealigner \
    -R ${refname} \
    -I ${alignedbam} \
    -targetIntervals targets.intervals \
    -o "${sample_id}_realigned.bam"

    samtools markdup "${sample_id}_realigned.bam" "${sample_id}_markdup.bam"
    samtools index "${sample_id}_markdup.bam"
    
    if [[ ${params.clean_files} == true ]]; then
        rm `readlink -f "${alignedbam}"` `readlink -f "${alignedbai}"` "${sample_id}_realigned.bam"
    fi
    """
}


process no_realign_sample {
    tag { sample_id }
    errorStrategy 'finish'
    
    publishDir "${params.output}/${pop}/${sample_id}", mode: 'move', pattern: "*bam*"

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_markdup.bam"), path("${sample_id}_markdup.bam.bai"), val(single_sample)

    script:
    def refname = "${refindexes[0].simpleName}.fa"
    
    """    
    samtools markdup ${alignedbam} "${sample_id}_markdup.bam"
    samtools index "${sample_id}_markdup.bam"
    
    if [[ ${params.clean_files} == true ]]; then
        rm `readlink -f "${alignedbam}"` `readlink -f "${alignedbai}"`
    fi
    """
}

process call_sample {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'
    
    publishDir "${params.output}/${pop}/${sample_id}", mode: 'move', pattern: "*gvcf.gz*"

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}.gvcf.gz*"), val(single_sample)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx30g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}.gvcf.gz" \
    -ERC GVCF
    """
}

process call_sample_part1 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_1.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_1.gvcf.gz" \
    -L ${params.refpart1} \
    -ERC GVCF
    """
}
process call_sample_part2 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_2.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_2.gvcf.gz" \
    -L ${params.refpart2} \
    -ERC GVCF
    """
}

process call_sample_part3 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_3.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_3.gvcf.gz" \
    -L ${params.refpart3} \
    -ERC GVCF
    """
}

process call_sample_part4 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_4.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_4.gvcf.gz" \
    -L ${params.refpart4} \
    -ERC GVCF
    """
}

process call_sample_part5 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_5.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_5.gvcf.gz" \
    -L ${params.refpart5} \
    -ERC GVCF
    """
}

process call_sample_part6 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_6.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_6.gvcf.gz" \
    -L ${params.refpart6} \
    -ERC GVCF
    """
}

process call_sample_part7 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_7.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_7.gvcf.gz" \
    -L ${params.refpart7} \
    -ERC GVCF
    """
}

process call_sample_part8 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_8.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_8.gvcf.gz" \
    -L ${params.refpart8} \
    -ERC GVCF
    """
}

process call_sample_part9 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_9.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_9.gvcf.gz" \
    -L ${params.refpart9} \
    -ERC GVCF
    """
}

process call_sample_part10 {
    tag { sample_id }
    label 'gatk4'
    errorStrategy 'finish'

    input:
    path(refindexes)
    tuple val(sample_id), val(pop), val(outpath), path(alignedbam), path(alignedbai), val(single_sample), val(platform)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}_10.gvcf.gz"), val(single_sample), val(platform)

    script:
    def refname = "${refindexes[0].simpleName}.fa"

    """
    gatk --java-options '-Xmx4g' HaplotypeCaller \
    -R ${refname} \
    -I "${params.output}/${platform}/${pop}/${sample_id}/${alignedbam}" \
    -O "${sample_id}_10.gvcf.gz" \
    -L ${params.refpart10} \
    -ERC GVCF
    """
}


process merge_gvcfs {
    tag { sample_id }
    errorStrategy 'finish'

    publishDir "${params.output}/${platform}/${pop}/${sample_id}", mode: 'move', pattern: "${sample_id}.gvcf.gz*"

    input:
    tuple val(sample_id), val(pop), val(outpath), path(gvcf1), val(single_sample), val(platform)
    tuple val(sample_id2), val(pop2), val(outpath2), path(gvcf2), val(single_sample2), val(platform2)
    tuple val(sample_id3), val(pop3), val(outpath3), path(gvcf3), val(single_sample3), val(platform3)
    tuple val(sample_id4), val(pop4), val(outpath4), path(gvcf4), val(single_sample4), val(platform4)
    tuple val(sample_id5), val(pop5), val(outpath5), path(gvcf5), val(single_sample5), val(platform5)
    tuple val(sample_id6), val(pop6), val(outpath6), path(gvcf6), val(single_sample6), val(platform6)
    tuple val(sample_id7), val(pop7), val(outpath7), path(gvcf7), val(single_sample7), val(platform7)
    tuple val(sample_id8), val(pop8), val(outpath8), path(gvcf8), val(single_sample8), val(platform8)
    tuple val(sample_id9), val(pop9), val(outpath9), path(gvcf9), val(single_sample9), val(platform9)
    tuple val(sample_id10), val(pop10), val(outpath10), path(gvcf10), val(single_sample10), val(platform10)

    output:
    tuple val(sample_id), val(pop), val(outpath), path("${sample_id}.gvcf.gz*"), val(single_sample), val(platform)

    script:

    """
    bcftools concat -Oz -o "${sample_id}.gvcf.gz" "${gvcf1}" "${gvcf2}" "${gvcf3}" "${gvcf4}" "${gvcf5}" "${gvcf6}" "${gvcf7}" "${gvcf8}" "${gvcf9}" "${gvcf10}"
    tabix "${sample_id}.gvcf.gz" 
    """
}

workflow make_bwa_index {
    take: reference
    
    main:
        ref_file = file(reference)
        if( !ref_file.exists() ) exit 1, "Missing ${reference} file!"
        out = bwa_index(reference)

    emit:
        out
}

workflow map_sample {

    take: 
        refindexes
        sample_data

    main:
        bam1_out = map_sort_sample(refindexes,sample_data)
        if(params.do_realignment) {
            bam2_out = realign_sample(refindexes,bam1_out)
        } else {
            bam2_out = no_realign_sample(refindexes,bam1_out)
        }    
    emit:
        bam2_out
}

workflow call_gvcf {

    take: 
        refindexes
        sample_data

    main:
        gvcf_out = call_sample(refindexes,sample_data)
    emit:
        gvcf_out
}

workflow call_gvcf_parts {

    take:
        refindexes
        sample_data

    main:
        gvcf_out1 = call_sample_part1(refindexes,sample_data)
        gvcf_out2 = call_sample_part2(refindexes,sample_data)
        gvcf_out3 = call_sample_part3(refindexes,sample_data)
        gvcf_out4 = call_sample_part4(refindexes,sample_data)
        gvcf_out5 = call_sample_part5(refindexes,sample_data)
        gvcf_out6 = call_sample_part6(refindexes,sample_data)
        gvcf_out7 = call_sample_part7(refindexes,sample_data)
        gvcf_out8 = call_sample_part8(refindexes,sample_data)
        gvcf_out9 = call_sample_part9(refindexes,sample_data)
        gvcf_out10 = call_sample_part10(refindexes,sample_data)

	    gvcf_out = merge_gvcfs(gvcf_out1,gvcf_out2,gvcf_out3,gvcf_out4,gvcf_out5,gvcf_out6,gvcf_out7,gvcf_out8,gvcf_out9,gvcf_out10)
    emit:
        gvcf_out
}

workflow download_sample {

    take: 
        sample_data

    main:
        sample_data = download_sample_allas(sample_data)
    emit:
        sample_data
}

workflow upload_sample {

    take: 
        gvcf_out 
        
    main:
        sample_id = upload_sample_allas(gvcf_out)
        
    emit:
        sample_id
}

workflow upload_sample2 {

    take: 
        sample_data 
        
    main:
        sample_id = upload_sample_allas2(sample_data)
        
    emit:
        sample_id
}
