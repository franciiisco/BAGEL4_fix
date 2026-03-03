# Guía de uso de BAGEL4 (instalación local)

**BAGEL4** detecta **bacteriocinas** en secuencias genómicas usando HMMs y BLAST.  
Versión local configurada en `/home/francisco/03_Scripts/BAGEL4/`

---

## Inicio rápido

```bash
cd /home/francisco/03_Scripts/BAGEL4

# Un solo genoma FASTA
./run_bagel4.sh -s /tmp/mi_sesion -query /ruta/al/genoma.fna

# Carpeta con múltiples genomas .fna
./run_bagel4.sh -s /tmp/mi_sesion -query /ruta/carpeta/ -r '.*\.fna$'
```

> El entorno conda `bacteriocin` se activa automáticamente mediante `run_bagel4.sh`.

---

## Parámetros

| Parámetro | Descripción | Ejemplo |
|---|---|---|
| `-s` | Directorio de sesión (se crea si no existe) | `-s /tmp/bagel4_sesion` |
| `-query` | Fichero FASTA **o** carpeta con FASTAs | `-query /data/genomas/` |
| `-r` | Regex para filtrar ficheros en una carpeta | `-r '.*\.fna$'` |

---

## Estructura del output

Todos los resultados se guardan en el directorio de sesión (`-s`):

```
mi_sesion/
├── bagel4.conf.json              # Configuración usada
├── BAGEL_wrapper.log             # Log del proceso
├── 00.OverviewGeneTables.html    # Tabla resumen en HTML ⭐
├── 00.OverviewGeneTables.json    # Tabla resumen en JSON
├── <queryname>.AOI.table         # AOIs detectadas (TSV)
├── <queryname>.AOI.fna           # Secuencias DNA de las AOIs
├── <queryname>.GeneTables        # Genes anotados en las AOIs
├── <queryname>.GeneTable.html    # Tabla de genes por AOI
└── <queryname>.*.json            # Datos para visualización
```

**El fichero más importante es `00.OverviewGeneTables.html`** — ábrelo en un navegador.

---

## Ejemplos de uso

### 1. Analizar un genoma completo
```bash
./run_bagel4.sh \
  -s /tmp/sesion_lactococcus \
  -query /data/genomas/Lactococcus_cremoris_MG1363.fna
```

### 2. Analizar todos los genomas en una carpeta
```bash
./run_bagel4.sh \
  -s /tmp/sesion_batch \
  -query /data/genomas/ \
  -r '.*\.fna$'
```

### 3. Analizar ficheros `.fasta` (en vez de `.fna`)
```bash
./run_bagel4.sh \
  -s /tmp/sesion_fasta \
  -query /data/genomas/ \
  -r '.*\.fasta$'
```

---

## Bases de datos disponibles

| Base de datos | Ubicación | Uso |
|---|---|---|
| HMMs propios de bacteriocinas | `db_hmm/` | Identificación de AOIs y anotación |
| Proteínas clase I, II, III | `db_proteins/` | BLAST de bacteriocinas |
| Pfam-A HMM (indexado) | `/home/francisco/00_databases/BAGEL4/Pfam-A.hmm` | Anotación de contexto |
| Pfam-A FASTA (BLAST) | `/home/francisco/00_databases/BAGEL4/Pfam-A.fasta` | Anotación de contexto |

---

## Ajuste de parámetros (`bagel4.conf`)

```ini
cpu = 1                        # Aumentar para genomas grandes (e.g. 4 u 8)
domT = 25                      # Umbral HMM. Bajar (e.g. 15) para más sensibilidad
contextsize = 20000            # Tamaño de las AOIs en bp
blast_evalue_bacteriocinI = 1E-05
```

> Edita `/home/francisco/03_Scripts/BAGEL4/bagel4.conf` y vuelve a ejecutar.

---

## Resultado de una AOI típica

Cuando BAGEL4 detecta una AOI, el `.AOI.table` contiene:

```
NC_009004.AOI_1  start  end  strand  Class  Method
```

Y el HTML muestra los genes coloreados por función:
- 🟢 Verde: bacteriocina estructural (clase I/II/III)
- 🟦 Azul claro: contexto (UniProt/Pfam)
- 🟩 Verde oscuro: hit HMM de bacteriocina

---

## Notas importantes

> [!NOTE]
> Si el pipeline termina con "0 AOIs found", puede ser biológicamente correcto. Algunos genomas no tienen bacteriocinas detectables con los umbrales por defecto. Prueba reduciendo `domT = 15` en `bagel4.conf`.

> [!NOTE]
> BAGEL4 detecta bacteriocinas vía dos métodos complementarios:
> - **HMM**: busca dominios Pfam en la traducción en 6 frames del genoma
> - **BLAST**: busca similitud con la base de datos de bacteriocinas conocidas
> Si alguno de los dos detecta una región, se genera una AOI.

> [!TIP]
> Para genomas grandes (>5 Mb), aumenta `cpu = 4` o más en `bagel4.conf` para acelerar los análisis de hmmsearch y blastp.
