# Measure sequence nucleotide content

Measure the nucleotide content of the input sequences. Input format can be any
of the standard sequence format files (FASTA, FASTQ, SAM).

## Example
```
cat reads.sam | dev/nt-content.pl --sam > out.tab
```
