*sra-to-sample* downloads SRA files, extracts the reads, merges multiple runs
and organizes them in a nice directory structure. The input to the script is a
JSON file which can be created manually or extracted from the GEO SOFT files
using `geo-soft-to-json.py`

Note that when multiple SRA codes are associated with a sample, as in the
first line of the example JSON, the files are concatenated in one fastq file.
Files `reads.2.fastq.gz` are only created if paired-end sequencing was used.

For example:

```json
{ "samples":[
    {"id": "sample_id_1", "name": "sample_name_1", "sra": ["SRRXXXXX", "SRRXXXXX"]},
    {"id": "sample_id_2", "name": "sample_name_2", "sra": ["SRRXXXXX"]}
]}
```

results in the following directory structure

```
sample_name_1
  |-fastq/reads.1.fastq.gz
  |-fastq/reads.2.fastq.gz
  README
sample_name_2
  |-fastq/reads.1.fastq.gz
  |-fastq/reads.2.fastq.gz
  README
```

