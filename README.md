# nf-rMAP

**nf-rMAP**: Nextflow-powered microbial genomics pipeline for rapid antimicrobial resistance analysis. Implements rMAP's core functionality with cloud-native scalability, enhanced QC, & modular workflows. Processes Illumina data through assembly, annotation, AMR detection & phylogenetics. 

---

![Pipeline logo](nf-rMAP-logo.png)

---

### A scalable microbial genomics pipeline for comprehensive bacterial chracterization, virulence & antimicrobial resistance profiling

**nf-rMAP** is a Nextflow implementation of the original rMAP pipeline, offering:
- Cloud-native microbial genome analysis  
- Comprehensive AMR/Virulence factor detection
- Production-grade variant calling & phylogeny
- 10x faster processing through parallelization

**Key features**  
✔️ Full-stack analysis from raw reads to clinical reports  
✔️ Supports Illumina data  
✔️ Automated QC & MultiQC reporting  
✔️ One-click Azure/AWS/GCP deployment  


### Installation

```bash

# Install Nextflow (requires Java 11+)
curl -s https://get.nextflow.io | bash

# Install dependencies via Conda (optional)
conda env create -f nf-rMAP.yml

```

### Minimal run

```bash

nextflow run nf-rMAP/main.nf \
    --input "data/*_{1,2}.fastq.gz" \
    --outdir results \
    -profile docker
```

### Requirements

```bash

- Nextflow 21.10.3+
- Docker 20.10+ or Singularity 3.7+
- Conda/Mamba (Optional) 

```

### Install Nextflow


```bash

curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

```

### Set up Docker

```bash
sudo apt-get install docker.io
sudo systemctl start docker
sudo usermod -aG docker $USER

**Re-login to apply changes**


```

### Clone repository


```bash

git clone https://github.com/gmboowa/nf-rMAP.git

cd nf-rMAP

```

### Usage 


Basic analysis

```bash

nextflow run main.nf \
    --input "samples/*_R{1,2}.fastq.gz" \
    --outdir final_results \
    --amr \
    --cpus 16 \
    -with-report execution.html
```

### Advanced run

```bash

nextflow run main.nf \
    --input "s3://my-bucket/reads/*.fastq" \
    --reference data/ESKAPE_ref.gbk \
    --assembly shovill \
    --amr \
    --phylogeny \
    --pangenome \
    --outdir s3://results-bucket/ \
    -profile awsbatch \
    -resume
```
### Configuration parameters

Parameter	default	description

---

```bash

| Parameter       | Default      | Description                              |
|-----------------|--------------|------------------------------------------|
| `--input`       | **Required** | Input FASTQ path/pattern                 |
| `--outdir`      | `results`    | Output directory                         |
| `--reference`   | `None`       | Reference genome (`.gbk`/`.fasta`)       |
| `--assembly`    | `megahit`    | Assembler: `megahit` or `shovill`        |
| `--cpus`        | `4`          | Total CPUs to use                        |
| `--memory`      | `32.GB`      | Per-job memory allocation                |
| `--amr`         | `false`      | Enable AMR detection                     |
| `--phylogeny`   | `false`      | Build phylogenetic trees                 |

**View all parameters with** --help

```
### Output structure
---

```bash
results/
├── reports/               # Quality control reports
├── assembly/              # Draft genomes (FASTA)
├── annotation/            # Prokka annotations (GBK)
├── variant_calling/       # VCFs & SNP tables
├── resistance_genes/      # AMR/Virulence factors
├── phylogeny/             # Newick trees & alignments
└── multiqc_report.html    # Consolidated QC
```

### For **nf-rMAP** (Nextflow implementation of rMAP), you'll need to download and configure these essential biological databases.

### Antimicrobial resistance (AMR) databases

| Database   | Purpose                                      | Download Command/URL                   |
|------------|--------------------------------------------- |----------------------------------------|
| ResFinder  | Antibiotic resistance genes                  | `abricate --setupdb --db resfinder`    |
| CARD       | Comprehensive Antibiotic Resistance Database | `abricate --setupdb --db card`         |
| ARG-ANNOT  | Antibiotic Resistance Gene Annotation        | `abricate --setupdb --db argannot`     |
| MEGARES    | Antibiotic resistance hierarchy              | `MEGARES` *(manual download required)* |
| NCBI AMR   | NCBI's curated AMR database                  | `amrfinder --update`                   |

```
*chmod +x databases_setup_script.sh && ./databases_setup_script.sh*

*chmod +x MLST_schemes.sh && ./MLST_schemes.sh*

```


### Virulence & Mobile elements

| Database        | Purpose               | Download Command/URL                      |
|-----------------|-----------------------|-------------------------------------------|
| VFDB            | Virulence Factors     | `abricate --setupdb --db vfdb`            |
| PlasmidFinder   | Plasmid replicons     | `abricate --setupdb --db plasmidfinder`   |
| ISfinder        | Insertion Sequences   | `ISfinder` *(manual download required)*   |


### Taxonomic classification

| Database  | Purpose               | Installation Command                                          |
|-----------|-----------------------|---------------------------------------------------------------|
| GTDB-Tk   | Genome Taxonomy       | `gtdbtk download --data_dir /databases/gtdbtk`                |
| Kraken2   | Standard Kraken2 DB   | `kraken2-build --standard --db /databases/kraken2` 'bacterial'|

### Annotation databases

| Database | Purpose                 | Command                                                              |
|----------|-------------------------|----------------------------------------------------------------------|
| Prokka   | Prokaryotic Annotation  | Automatically included                                               |
| EggNOG   | Functional Annotation   | `download_eggnog_data.py -y -f --data_dir /databases/eggnog`         |

### Directory structure recommendation

```bash
/databases
├── amr
│   ├── card
│   ├── resfinder
│   └── megares
├── virulence
│   ├── vfdb
│   └── plasmidfinder
├── references
│   └── species_name
├── mlst
├── kraken2
└── gtdbtk

```

### Update frequency: run database updates regularly

```bash
amrfinder --update
abricate --update --datadir /databases/amr
mlst --update

```

### Contributing 

- We welcome contributions!
- Open an issue to discuss proposed changes
- Fork repository and create feature branch
- Submit PR with detailed description
- Follow original rMAP repository here **https://github.com/GunzIvan28/rMAP**


### Citation 

If you use nf-rMAP, please cite: 
> **Sserwadda, I. & Mboowa, G.** (2021).  
> **rMAP: the Rapid Microbial Analysis Pipeline for ESKAPE bacterial group whole-genome sequence data**.  
> *Microbial Genomics*, 7(6):000583. https://doi.org/10.1099/mgen.0.000583  
> PMID: [34110280](https://pubmed.ncbi.nlm.nih.gov/34110280) · PMCID: [PMC8461470](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8461470/)
