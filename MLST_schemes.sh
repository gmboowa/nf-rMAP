#!/bin/bash
set -e

# Install PubMLST schemes
mkdir -p /databases/mlst
cd /databases/mlst
git clone https://github.com/tseemann/mlst.git || echo "Repo already cloned."
mlst --update