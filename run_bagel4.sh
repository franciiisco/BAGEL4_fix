#!/usr/bin/env bash
# run_bagel4.sh — Lanzador de BAGEL4 usando el entorno conda 'bacteriocin'
# Uso: ./run_bagel4.sh -s <sessiondir> -query <fasta_folder> [opciones adicionales]

set -euo pipefail

BAGEL4_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONDA_ENV="bacteriocin"
CONDA_BASE="$(conda info --base 2>/dev/null || echo /home/francisco/miniconda3)"

# Activar conda en scripts no interactivos
source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

# Exportar la librería Perl de BAGEL4 (resuelve los 'use lib /data/bagel4/lib' hardcodeados)
export PERL5LIB="${BAGEL4_DIR}/lib:${PERL5LIB:-}"

# Asegurar que los binarios del entorno tienen prioridad
export PATH="${CONDA_BASE}/envs/${CONDA_ENV}/bin:${PATH}"

echo "========================================"
echo "  BAGEL4 launcher"
echo "  Dir: ${BAGEL4_DIR}"
echo "  Conda: ${CONDA_ENV}"
echo "  PERL5LIB: ${PERL5LIB}"
echo "========================================"

exec perl "${BAGEL4_DIR}/bagel4_wrapper.pl" "$@"
