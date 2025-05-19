#!/bin/bash
set -e

echo "🔧 Creating database directory..."
sudo mkdir -p /databases
sudo chmod 777 /databases

echo "📦 Setting up AMR databases..."
abricate --setupdb --db resfinder --datadir /databases/amr/resfinder
abricate --setupdb --db card --datadir /databases/amr/card
amrfinder --update --database /databases/amr/ncbi

echo "🧬 Setting up virulence databases..."
abricate --setupdb --db vfdb --datadir /databases/virulence/vfdb
abricate --setupdb --db plasmidfinder --datadir /databases/virulence/plasmidfinder

echo "🧬 Downloading GTDB-Tk taxonomic reference..."
gtdbtk download --data_dir /databases/gtdbtk --force

echo "🐛 Downloading Kraken2 bacterial database..."
kraken2-build --download-taxonomy --db /databases/kraken2
kraken2-build --download-library bacteria --db /databases/kraken2
kraken2-build --build --threads 32 --db /databases/kraken2

echo "🧬 Updating MLST schemes..."
mlst --update --datadir /databases/mlst

echo "✅ All databases set up successfully!"
