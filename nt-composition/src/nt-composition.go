package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"sort"
	"strings"

	"github.com/biogo/biogo/alphabet"
	"github.com/biogo/biogo/io/seqio"
	"github.com/biogo/biogo/io/seqio/fasta"
	"github.com/biogo/biogo/io/seqio/fastq"
	"github.com/biogo/biogo/seq/linear"
	"github.com/docopt/docopt-go"
)

type Key struct {
	Pos int
	Let string
}

func main() {
	usage := `
Measure nucleotide composition along the sequences in a FASTA/FASTQ file.  The
output is a tab delimited file that reports the percent of each nucleotide
for each position in the sequences. If <file> is - it reads from STDIN.

Usage:
	nt-composition [options] (--fastq | --fasta) <file>

Options:
	-h --help  Show this screen.
	--fastq    Input file is in FASTQ format.
	--fasta    Input file is in FASTA format.`

	// Read command options
	args, err := docopt.Parse(usage, nil, true, "", false)
	if err != nil {
		panic(err)
	}

	// Get a seqio reader
	r, err := readerFrom(args)
	if err != nil {
		panic(err)
	}

	// Loop on the sequences
	maxPos := 0
	letters := make([]string, 0)
	count := make(map[Key]int)
	for {
		seq, err := r.Read()
		if err != nil {
			if err == io.EOF {
				break
			} else {
				panic(err)
			}
		}
		seqString := ""
		for i := 0; i < seq.Len(); i++ {
			seqString = seqString + strings.ToUpper(string(seq.At(i).L))
		}

		for i := 0; i < len(seqString); i++ {
			s := string(seqString[i])
			count[Key{i, s}]++
			if !stringInSlice(s, letters) {
				letters = append(letters, s)
			}
			if i > maxPos {
				maxPos = i
			}
		}
	}
	sort.Strings(letters)

	fmt.Print("pos\tnt\tcount\ttotal_count\n")
	for pos := 0; pos <= maxPos; pos++ {
		totalCnt := 0
		for _, l := range letters {
			totalCnt += count[Key{pos, l}]
		}
		for _, l := range letters {
			fmt.Printf("%d\t%s\t%d\t%d\n", pos, l, count[Key{pos, l}], totalCnt)
		}
	}
}

func stringInSlice(b string, letters []string) bool {
	for _, l := range letters {
		if b == l {
			return true
		}
	}
	return false
}

func readerFrom(args map[string]interface{}) (seqio.Reader, error) {
	var ri io.Reader

	file, _ := args["<file>"].(string)
	if file == "-" {
		ri = bufio.NewReader(os.Stdin)
	} else {
		r, err := os.Open(file)
		if err != nil {
			return nil, err
		}
		ri = bufio.NewReader(r)
	}

	if args["--fastq"] == true {
		return fastq.NewReader(ri, linear.NewSeq("", nil, alphabet.DNA)), nil
	} else if args["--fasta"] == true {
		return fasta.NewReader(ri, linear.NewSeq("", nil, alphabet.DNA)), nil
	}

	return nil, errors.New("Unknown file format")
}
