package main

import (
	"fmt"
	"io"
	"log"
	"strings"

	"github.com/alexflint/go-arg"
	"github.com/brentp/xopen"
	"github.com/mnsmar/fasta"
)

type orf struct {
	Start, End int
}

// Opts encapsulates common command line options.
type Opts struct {
	Input []string `arg:"positional,required" help:"input FASTA file/s (STDIN if -)"`
}

// Version returns the program version.
func (Opts) Version() string { return "orfs 0.1" }

// Description returns an extended description of the program.
func (Opts) Description() string {
	return "Find potential Open Reading Frames in the sequences in FASTA file/s. It prints the identified ORFs in BED format"
}

func main() {
	var opts Opts
	arg.MustParse(&opts)

	for _, file := range opts.Input {
		f, err := xopen.Ropen(file)
		if err != nil {
			log.Fatal(err)
		}

		r := fasta.NewReader(f)
		for {
			rec, err := r.Read()
			if err != nil {
				if err == io.EOF {
					break
				}
				log.Fatal(err)
			}

			seq := strings.ToUpper(string(rec.Seq()))
			orfs := findAll(seq)
			for i, orf := range orfs {
				fmt.Printf("%s\t%d\t%d\t%s:%d\t%d\t%s\n",
					rec.Name(), orf.Start, orf.End,
					rec.Name(), i, 0, "+")
			}
		}
	}
}

func findAll(seq string) (orfs []orf) {
START:
	for i := 0; i < len(seq)-2; i++ {
		if seq[i:i+3] == "ATG" {
			for j := i; j < len(seq)-2; j += 3 {
				cod := seq[j : j+3]
				if cod == "TAG" || cod == "TAA" || cod == "TGA" {
					orfs = append(orfs, orf{Start: i, End: j + 3})
					continue START
				}
			}
		}
	}
	return orfs
}
