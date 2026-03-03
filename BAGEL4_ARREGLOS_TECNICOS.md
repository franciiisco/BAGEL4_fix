# BAGEL4 — Arreglos necesarios para instalación local

Documento técnico con todos los cambios realizados para hacer funcionar BAGEL4 v1.2
en una instalación local con Python 3.11 y el entorno conda `bacteriocin`.

---

## Prerequisitos

El entorno conda `bacteriocin` debe tener instalado:

```bash
conda install -n bacteriocin -c bioconda transtermhp
```

El resto de dependencias ya estaban presentes (`hmmsearch`, `blastp`, `glimmer3`, `rsvg-convert`, `perl-json`).

---

## Arreglo 1 — Pfam-A HMM database

La base de datos Pfam-A estaba almacenada comprimida. Hay que descomprimirla e indexarla:

```bash
gunzip -k /home/francisco/00_databases/BAGEL4/Pfam-A.hmm.gz
conda run -n bacteriocin hmmpress /home/francisco/00_databases/BAGEL4/Pfam-A.hmm
```

Genera: `Pfam-A.hmm.h3f`, `Pfam-A.hmm.h3i`, `Pfam-A.hmm.h3m`, `Pfam-A.hmm.h3p`

---

## Arreglo 2 — `bagel4.conf`: rutas de herramientas

**Problema:** rutas hardcodeadas al servidor original `/data/bagel4/tools/`

**Fichero:** [`bagel4.conf`](file:///home/francisco/03_Scripts/BAGEL4/bagel4.conf)

```diff
-blast = blastall
+blast = blastp

-glimmerpath = /data/bagel4/tools/glimmer3.02/bin
+glimmerpath = /home/francisco/miniconda3/envs/bacteriocin/bin

-hmmsearch = /data/bagel4/tools/hmmsearch/binaries
+hmmsearch = /home/francisco/miniconda3/envs/bacteriocin/bin

-MOODS = /data/bagel4/tools/MOODS-python-1.9.3
+MOODS = /home/francisco/miniconda3/envs/bacteriocin

-transtermHP = /data/bagel4/tools/transterm_hp_v2.09
+transtermHP = /home/francisco/miniconda3/envs/bacteriocin/bin

+pfam_db = /home/francisco/00_databases/BAGEL4
```

---

## Arreglo 3 — Script de lanzamiento `run_bagel4.sh` (nuevo)

**Problema:** Los scripts Perl tienen `use lib "/data/bagel4/lib"` y `use lib "/data/molgentools/lib"` hardcodeados. Modificar todos los ficheros sería frágil. La solución es exportar `PERL5LIB` antes de ejecutar.

**Fichero nuevo:** [`run_bagel4.sh`](file:///home/francisco/03_Scripts/BAGEL4/run_bagel4.sh)

```bash
#!/usr/bin/env bash
BAGEL4_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONDA_BASE="$(conda info --base)"
source "${CONDA_BASE}/etc/profile.d/conda.sh"
conda activate bacteriocin
export PERL5LIB="${BAGEL4_DIR}/lib:${PERL5LIB:-}"
exec perl "${BAGEL4_DIR}/bagel4_wrapper.pl" "$@"
```

```bash
chmod +x run_bagel4.sh
```

---

## Arreglo 4 — `lib/anne_genomics.pm`: dependencias opcionales

**Problema:** BioPerl (`Bio::Seq`, etc.) y `DBI` no están disponibles. Son solo usados por funciones legacy de PostgreSQL y GenBank que BAGEL4 standalone no necesita.

**Fichero:** [`lib/anne_genomics.pm`](file:///home/francisco/03_Scripts/BAGEL4/lib/anne_genomics.pm)

```diff
-use Bio::Seq ;
-use Bio::Tools::pICalculator;
-use Bio::SearchIO ;
-use Bio::SeqIO ;
-use DBI ;
+eval { require Bio::Seq; Bio::Seq->import(); };   # opcional, solo para funciones legacy
+eval { require DBI; DBI->import(); };              # opcional, solo para PostgreSQL legacy
```

Además, el `$codontablefile` estaba hardcodeado. Corregido con ruta dinámica:

```diff
-my $codontablefile = '/data/molgentools/genomics/codon_table.txt';
+my $codontablefile = do {
+    use File::Basename;
+    my $lib_dir = dirname(__FILE__);
+    "$lib_dir/../tables/codon_table.txt";
+};
```

---

## Arreglo 5 — `lib/bagel4_functions.pm` y `lib/bagel4_blast.pm`: LWP opcional

**Problema:** `LWP::Simple` no está instalado en el entorno `bacteriocin`. Solo se usa para consultas web a UniProt (función opcional).

**Ficheros:** [`lib/bagel4_functions.pm`](file:///home/francisco/03_Scripts/BAGEL4/lib/bagel4_functions.pm) y [`lib/bagel4_blast.pm`](file:///home/francisco/03_Scripts/BAGEL4/lib/bagel4_blast.pm)

```diff
-use LWP::Simple;
+eval { require LWP::Simple; LWP::Simple->import(); };
```

---

## Arreglo 6 — `bagel4_wrapper.pl`: 4 bugs

**Fichero:** [`bagel4_wrapper.pl`](file:///home/francisco/03_Scripts/BAGEL4/bagel4_wrapper.pl)

### Bug A — mkdir antes que conf2json

```diff
+mkdir $sessiondir ;
 my $command = "$program_dir/bagel4_conf_2_json.pl -s $sessiondir" ;
 system($command);
-mkdir $sessiondir ;
```

### Bug B — modo standalone no encontraba ficheros de entrada

El wrapper buscaba en `$sessiondir/queryfolder/` en vez de en el path pasado con `-query`:

```diff
-my @all_filenames = anne_files::get_files_from_subdirs_v2("$sessiondir/queryfolder", $regex);
+my @all_filenames;
+if (-f $query) {
+    @all_filenames = ($query);          # fichero único
+} else {
+    @all_filenames = anne_files::get_files_from_subdirs_v2($query, $regex);  # carpeta
+}
```

### Bug C — comandos no se ejecutaban (solo se imprimían)

```diff
-my $debug = 1 ;  # para webserver: 1=solo imprime, 0=ejecuta
-$debug = 0 if ($webserver) ;
+my $debug = 0 ;  # standalone siempre ejecuta
```

### Bug D — sub-scripts con rutas hardcodeadas

Todos los `system_command("/data/bagel4/script.pl ...")` cambiados a `"$program_dir/script.pl ..."`:

```diff
-system_command("/data/bagel4/bagel4_AOI_identification_blast_bacteriocins.pl ...");
+system_command("$program_dir/bagel4_AOI_identification_blast_bacteriocins.pl ...");
# (idem para bagel4_AOI_merge, bagel4_AOI_annotation, bagel4_promoterprediction,
#  bagel4_transterm, bagel4_promoter_term_2_json, bagel4_GeneTable_2_json,
#  bagel4_clean_tmpfiles)
```

---

## Arreglo 7 — `bagel4_AOI_identification_hmm_rules.pl`: límite 100K de HMMER 3.3+

**Problema:** HMMER 3.3+ tiene un límite duro de 100K aminoácidos por secuencia. Las traducciones en 6 frames de genomas completos (~766K aa cada una) superan el límite y dan `Aborted (core dumped)`.

**Fichero:** [`bagel4_AOI_identification_hmm_rules.pl`](file:///home/francisco/03_Scripts/BAGEL4/bagel4_AOI_identification_hmm_rules.pl)

**Solución:** dividir las secuencias en chunks de 90K aa con solapamiento de 5K, pasar los chunks a hmmsearch y remap las coordenadas al frame original.

El código de la función `hmmsearch()` en ese fichero contiene la lógica completa de chunking y remapeo.

También se corrigió un typo en la clave de configuración:
```diff
-$conf{HMMs_folder\t}   # tab literal en la clave — falla en hash lookup
+$hmm_folder = $conf{HMMs_folder};
+$hmm_folder =~ s/\s+$//;  # eliminar whitespace trailing
```

---

## Arreglo 8 — Wrapper `formatdb` (nuevo)

**Problema:** `formatdb` es el comando de BLAST legacy para indexar bases de datos. Ya no existe en BLAST+ 2.x (se reemplazó por `makeblastdb`).

**Fichero nuevo:** `/home/francisco/miniconda3/envs/bacteriocin/bin/formatdb`

```bash
#!/usr/bin/env bash
# Wrapper que traduce formatdb a makeblastdb
INPUTFILE=""; DBTYPE="prot"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) INPUTFILE="$2"; shift 2 ;;
        -p) [[ "$2" == "F" ]] && DBTYPE="nucl" || DBTYPE="prot"; shift 2 ;;
        *) shift ;;
    esac
done
exec makeblastdb -in "$INPUTFILE" -dbtype "$DBTYPE"
```

```bash
chmod +x /home/francisco/miniconda3/envs/bacteriocin/bin/formatdb
```

---

## Verificación

```bash
rm -rf /tmp/bagel4_test/session
/home/francisco/03_Scripts/BAGEL4/run_bagel4.sh \
  -s /tmp/bagel4_test/session \
  -query /tmp/bagel4_test/LlMG1363.fna 2>&1

# Resultado esperado:
# ✅ 18 HMMs analizados sin "Aborted"
# ✅ BLAST database creada (makeblastdb)
# ✅ "Analysis done"
```
