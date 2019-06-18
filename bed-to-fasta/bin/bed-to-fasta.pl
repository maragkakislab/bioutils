#!/usr/bin/env perl

# Load modules
use Modern::Perl;
use autodie;
use Getopt::Long::Descriptive;
use File::Path qw(make_path);

# Load GenOO library
use GenOO::Data::File::FASTA;
use GenOO::Data::File::BED;

# Define and read command line options
my ($opt, $usage) = describe_options(
	'%c %o',
	['bed=s', 'BED file with features'],
	['refs=s', 'fasta file with reference sequences'],
	['refs-in-memory', 'keep reference sequences in memory for faster access'],
	['ref-dir=s', 'alternative to --refs; directory with reference fasta files; one sequence per file'],
	['chr_dir=s', 'directory with chromosome fasta files', { hidden => 1}],
	['help|h', 'print usage message and exit'],
);
print($usage->text), exit if $opt->help;

# For backwards compatibility: handles the deprecated chr_dir option.
if (defined $opt->chr_dir) {
	if (defined $opt->ref_dir) {
		die "Cannot specify both \'chr_dir\' and \'ref-dir\' options\n";
	}
	$opt->{'ref_dir'} = $opt->chr_dir;
}

# Check proper use of ref-dir and refs options.
if (defined $opt->ref_dir and defined $opt->refs) {
	die "Cannot specify both \'ref-dir\' and \'refs\' options\n";
}

my $ref_dir = $opt->ref_dir;
my $refs = $opt->refs;

my $fp = GenOO::Data::File::BED->new(file => $opt->bed);

# Read reference sequences in memory if asked.
my %ref_seqs;
if (defined $opt->refs_in_memory and defined $refs) {
	my $fp = GenOO::Data::File::FASTA->new(file => $refs);
	while (my $r= $fp->next_record) {
		$ref_seqs{$r->header} = $r->sequence;
	}
}

my $prev_rname = '';
my $rname_seq = '';
while(my $r = $fp->next_record) {
	my $rname = $r->rname;
	if ($rname ne $prev_rname) {
		if (exists $ref_seqs{$rname}) {
			$rname_seq = $ref_seqs{$rname};
		} elsif (defined $refs) {
			$rname_seq = rname_seq_from_file($refs, $rname);
		} elsif (defined $ref_dir) {
			my $f = $ref_dir . $rname . '.fa';
			if (-e $f.'.gz') {
				$rname_seq = rname_seq_from_file($f.'.gz', $rname);
			} elsif (-e $f){
				$rname_seq = rname_seq_from_file($f, $rname);
			} else {
				warn "skipping $rname: file not found in $ref_dir\n";
				next;
			}
		}

		if (!defined($rname_seq)) {
			die "error: could not find sequence for $rname\n";
		}
		$prev_rname = $rname;
	}

	my $r_seq = region_sequence_from_seq(
		\$rname_seq, $r->strand, $r->rname, $r->start, $r->stop, 0);
	if (!defined $r_seq) {
		die "error: could not extract sequence for " . $r->location . "\n";
	}
	say '>'.$r->location."\n".$r_seq;
}

##############################
sub rname_seq_from_file {
	my ($f, $rname) = @_;

	my $fp = GenOO::Data::File::FASTA->new(file => $f);
	while (my $r= $fp->next_record) {
		if ($r->header ne $rname) {
			next;
		}
		return $r->sequence;
	}
}

sub region_sequence_from_seq {
	my ($seq_ref, $strand, $rname, $start, $stop, $flank) = @_;

	#out of bounds
	return if ($start - $flank < 0);
	return if ($stop + $flank > length($$seq_ref) - 1);

	if ($strand == 1) {
		return substr($$seq_ref, $start-$flank, 2*$flank+$stop-$start+1);
	}
	else {
		my $seq = reverse(
			substr($$seq_ref, $start-$flank, 2*$flank+$stop-$start+1));
		if ($seq =~ /U/i) {
			$seq =~ tr/ATGCUatgcu/UACGAuacga/;
		}
		else {
			$seq =~ tr/ATGCUatgcu/TACGAtacga/;
		}
		return $seq;
	}
}
