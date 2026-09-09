#!/usr/bin/env nextflow

nextflow.enable.dsl=2


if (params.help) {
log.info """
PGP PIPELINE
=============================================
help
"""
exit 1
}



/*
 * Define the module paths and include the elements
 */

subwork_folder = "${projectDir}/subworkflows"

include { print_sample_info; print_sample_info2 } from "${subwork_folder}/process_sample" 
include { getVersionsBwaSamtools; getVersionGatk3; getVersionGatk4 } from "${subwork_folder}/process_sample" 

include { make_bwa_index as bwa_index } from "${subwork_folder}/process_sample"
include { map_sample; call_gvcf; call_gvcf_parts } from "${subwork_folder}/process_sample"
include { download_sample; upload_sample; upload_sample2 } from "${subwork_folder}/process_sample"


// Reference
reference = file( params.reference, checkIfExists: true ) 

ref_indexes = Channel.fromPath(params.refindexes).toList()



// Workflows

// Program versions (pulling images if not available) 
workflow setup {
    getVersionsBwaSamtools()
    getVersionsBwaSamtools.out.view()
    getVersionGatk3()
    getVersionGatk3.out.view()
    getVersionGatk4()
    getVersionGatk4.out.view()
}


workflow {

    if(params.setup) {
        log.info 'Program versions.'
        setup()
    }

    if(params.bwa_index) {
    
        log.info "PGP INDEXING"
        log.info "============================================="
        log.info "reference           : ${params.reference}"
        log.info "refindexes          : ${params.refindexes}"
        

        dir = file(params.referenceDir)
        dir.mkdir()
        ref_out = bwa_index(reference)
    }

    if(params.sample_list != "") {

        log.info "PGP MAPPING"
        log.info "============================================="
        log.info "reference           : ${params.reference}"
        log.info "refindexes          : ${params.refindexes}"
        log.info "============================================="

        if(params.call_only) {
            sample_info = Channel.fromPath( file(params.sample_list) )
            .splitCsv(header: true, sep: '\t')
            .map{row ->
                def sample_id  = row['SampleID']
                def population = row['Population']
                def outpath    = row['Outpath']
                def alignedbam = row['Inbam']
                def alignedbai = row['Inbai']
                def single_sample = false;
                return [ sample_id, population, outpath, alignedbam, alignedbai, single_sample ]
            }
        } else {
            sample_info = Channel.fromPath( file(params.sample_list) )
            .splitCsv(header: true, sep: '\t')
            .map{row ->
                def sample_id  = row['SampleID']
                def population = row['Population']
                def inpath     = row['Inpath']
                def outpath    = row['Outpath']
                def single_sample = false;
                return [ sample_id, population, inpath, outpath, single_sample ]
            }
        }
    }
    else {
         if(params.call_only) {
            sample_info = [params.sample_id, params.population, params.outpath, params.alignedbam, params.alignedbai, true, params.platform]
         }
         else {
            sample_info = [params.sample_id, params.population, params.inpath, params.outpath, true, params.platform]
         }
    }

    if(params.print_samples) {
        if(params.call_only) {
            sample_info = print_sample_info2(sample_info)
        } else {
            sample_info = print_sample_info(sample_info)
        }
    }
    
    else if(params.download_only) {
        sample_infor = download_sample(sample_info)   
    } 

    else if(params.upload_only) {
        sample_id = upload_sample2(sample_info)   
    } 

    else if(params.call_only) {
        if(params.split_call) {
            gvcf_out = call_gvcf_parts(ref_indexes, sample_info)
        } else {
            gvcf_out = call_gvcf(ref_indexes, sample_info)
        }
        sample_id = upload_sample(gvcf_out)    
        
    }
    else if(params.all) {
    
        sample_info = download_sample(sample_info)
        bam_out = map_sample(ref_indexes, sample_info)

        if(params.split_call) {
            gvcf_out = call_gvcf_parts(ref_indexes, bam_out)
        } else {
            gvcf_out = call_gvcf(ref_indexes, bam_out)
        }
        
        sample_id = upload_sample(gvcf_out)    
    
    }
}


// Wrap up
workflow.onComplete { 
    println ( workflow.success ? "\nDone!\n" : "Oops .. something went wrong" )
}

