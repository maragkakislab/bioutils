#!/usr/bin/env perl

use Modern::Perl;
use Getopt::Long::Descriptive;

use GenOO::Data::File::FASTA;
use GenOO::Data::File::FASTQ;
use GenOO::Data::File::SAM;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o",
	["Measure nucleotide content for sequences in a FASTA/FASTQ/SAM file."],
	["The output is a tab delimited file that reports the percent that each"],
	["nucleotide is found in the input sequences."],
	["For FASTA and FASTQ the \"sequence\" method is used to extract the"],
	["read sequence. For SAM the \"query_seq\" method is used instead"],
	[],
	['input|i=s', 'input file. If not set use STDIN (-type is required).'],
	['type' => hidden => { one_of => [
		[ "fasta" => "input in FASTA format" ],
		[ "fastq" => "input in FASTQ format" ],
		[ "sam" => "input in SAM format" ],
	] } ],
	['verbose|v', "print progress"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;
if (!$opt->input and !$opt->type) {
	print "Input format is required when -input is empty\n\n";
	print($usage->text);
	exit;
}

warn "specifying input type\n" if $opt->verbose;
my $itype = uc($opt->type || guess_input($opt->input));
my $seq_accessor = sequence_accessor_for_itype($itype);

warn "opening input file\n" if $opt->verbose;
my $class = "GenOO::Data::File::".uc($itype);
my $fp = $class->new(file => $opt->input);

warn "Measuring nucleotide preference\n" if $opt->verbose;
my %counts;
while (my $r = $fp->next_record) {
	my $seq = &$seq_accessor($r);
	my @nts = split(//, uc($seq));
	map {$counts{$_}++} @nts;
};

my $seq_space;
map {$seq_space += $counts{$_}} keys %counts;

warn "Printing results\n" if $opt->verbose;
say join("\t", 'nt', 'count', 'percent');
foreach my $nt (keys %counts) {
	say join("\t", $nt, $counts{$nt}, ($counts{$nt} / $seq_space) * 100);
}

###########################################################################
sub guess_input {
	my ($file) = @_;

	if ($file =~ /\.fastq(.gz)*$/) {
		return 'FASTQ';
	}
	elsif ($opt->input =~ /\.fasta(.gz)*$/ or $opt->input =~ /\.fa(.gz)*$/) {
		return 'FASTA';
	}
	elsif ($opt->input =~ /\.sam(.gz)*$/) {
		return 'SAM';
	}
}

sub sequence_accessor_for_itype {
	my ($type) = @_;

	return sub {my $r = shift; $r->query_seq} if $type eq 'SAM';
	return sub {my $r = shift; $r->sequence};
}

