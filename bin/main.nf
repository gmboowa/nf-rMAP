#!/usr/bin/env nextflow

params.adapters = file(params.adapters)
params.sra_list = file(params.sra_list)

workflow {
    if(params.config) {
        run_config
    }
    if(params.download) {
        run_download
    }
    main_analysis()
}

def run_config() {
    process install_dependencies {
        conda "bioconda::r-rmarkdown=2.11"
        conda "bioconda::r-kableextra=1.3.4"
        conda "bioconda::r-plotly=4.10.0"
        conda "biay/bioconda::deviaTE=1.0.2"

        script:
        """
        Rscript -e 'install.packages(c("ggtree", "rmarkdown"))'
        pip install pbr
        wget ftp://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/ORFfinder/linux-i64/ORFfinder.gz
        gunzip ORFfinder.gz
        chmod +x ORFfinder
        """
    }
}

def run_download() {
    process download_sra {
        input:
        path sra_list
        
        output:
        path "SRA_READS/*", emit: reads
        
        script:
        """
        mkdir -p SRA_READS
        for sra in \$(cat ${sra_list}); do
            fastq-dump --split-files --gzip \$sra -O SRA_READS
        done
        """
    }
}

def main_analysis() {
    input_ch = Channel.fromPath("${params.input_dir}/*_{1,2}.fastq*")
        .map { it -> [it.baseName.replaceAll(/_[12]$/, ''), it] }
        .groupTuple()
        .ifEmpty { error "No input files found in ${params.input_dir}" }

    input_ch
        .branch {
            raw: it[1][0].toString().endsWith('.fastq')
            trimmed: true
        }
        .set { branched_input }

    workflow quality_control {
        take: raw
        
        process fastqc {
            tag "$sample"
            cpus params.cpus
            
            input:
            tuple val(sample), path(reads)
            
            output:
            path "fastqc/${sample}_*", emit: qc_reports
            
            script:
            """
            mkdir -p fastqc
            fastqc -o fastqc -t ${task.cpus} ${reads}
            """
        }
        
        process multiqc {
            tag "MultiQC"
            
            input:
            path qc_reports
            
            output:
            path "multiqc_report.html", emit: report
            
            script:
            "multiqc . -f -o ."
        }
    }

    workflow trimming {
        take: raw
        
        process trimmomatic {
            tag "$sample"
            cpus params.cpus
            
            input:
            tuple val(sample), path(reads)
            path adapters
            
            output:
            tuple val(sample), path("trimmed/${sample}*.fastq.gz"), emit: trimmed
            
            script:
            """
            mkdir -p trimmed
            trimmomatic PE -threads ${task.cpus} ${reads} \
                trimmed/${sample}_1.fastq.gz /dev/null \
                trimmed/${sample}_2.fastq.gz /dev/null \
                ILLUMINACLIP:${adapters}:2:30:10 \
                LEADING:${params.quality} TRAILING:${params.quality} \
                MINLEN:${params.min_len}
            """
        }
    }

    workflow assembly {
        take: reads
        
        process run_assembly {
            tag "$sample"
            cpus params.cpus
            
            input:
            tuple val(sample), path(reads)
            
            output:
            path "assembly/${sample}.fa", emit: assembly
            
            script:
            if(params.assembly == 'shovill') {
                """
                shovill --R1 ${reads[0]} --R2 ${reads[1]} \
                    --cpus ${task.cpus} --outdir ${sample}_asm
                mv ${sample}_asm/contigs.fa assembly/${sample}.fa
                """
            } else {
                """
                megahit -1 ${reads[0]} -2 ${reads[1]} \
                    -o ${sample}_asm -t ${task.cpus}
                mv ${sample}_asm/final.contigs.fa assembly/${sample}.fa
                """
            }
        }
    }

    workflow annotation {
        take: assembly
        
        process prokka {
            tag "$sample"
            cpus params.cpus
            
            input:
            path assembly
            
            output:
            path "annotation/${sample}.gff", emit: gff
            
            script:
            """
            prokka --prefix ${sample} --cpus ${task.cpus} \
                --outdir annotation ${assembly}
            """
        }
    }

    workflow amr_detection {
        take: assembly
        
        process abricate {
            tag "$sample"
            cpus params.cpus
            
            input:
            path assembly
            
            output:
            path "amr/${sample}.tsv", emit: amr
            
            script:
            """
            abricate --db resfinder ${assembly} > amr/${sample}.tsv
            """
        }
    }

    workflow {
        // Main workflow execution
        if(params.quality) {
            quality_control(branched_input.raw)
        }
        if(params.trim) {
            trimming(branched_input.raw)
        }
        
        assembly(input_ch)
        annotation(assembly.out.assembly)
        
        if(params.amr) {
            amr_detection(assembly.out.assembly)
        }
    }
}
