#!/usr/bin/env perl

# Load modules
use Modern::Perl;
use Getopt::Long::Descriptive;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o [FILE]...",
	["Count the number of reads in a file."],
	[],
	['type' => hidden => { one_of => [
		[ "fasta"  => "input in FASTA format" ],
		[ "fastq"  => "input in FASTQ format" ],
		[ "sam"    => "input in SAM format" ],
		[ "bed"    => "input in BED format" ],
	] } ],
	['skip_unmapped', "for SAM: skip records that are unmapped"],
	['verbose|v', "print progress"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;

# If input is comming from a pipe
if (!-t STDIN) {
	if (!$opt->type) {
		say "Error: Input format is required when reading from STDIN";
		exit 1;
	}
	my ($cnt, $err) = count_reads(undef, $opt->type, $opt->skip_unmapped);
	if (defined $err) {
		warn "$err\n";
		exit;
	}
	say $cnt;
	exit;
}

# Loop on files and count
foreach my $file (@ARGV) {
	if (!file_exists($file)) {
		warn "$file: does not exist\n";
		next;
	}

	my ($cnt, $err) = count_reads($file, $opt->type, $opt->skip_unmapped);
	if (defined $err) {
		warn "$err\n";
		next;
	}
	say "$cnt\t$file";
}

###########################################################################
sub count_reads {
	my ($file, $type, $skip_unmapped) = @_;

	my $itype = $type || guess_input($file);

	if (lc($itype) eq 'fasta') {
		return count_reads_for_fasta($file);
	} elsif (lc($itype) eq 'fastq') {
		return count_reads_for_fastq($file);
	} elsif (lc($itype) eq 'sam') {
		return count_reads_for_sam($file, $skip_unmapped);
	} elsif (lc($itype) eq 'bed') {
		return count_reads_for_bed($file);
	}
	
	return undef, "$file: cannot specify type";
}

sub count_reads_for_fasta {
	my ($file) = @_;

	my $IN = get_filehandle($file);
	my $cnt = 0;
	while (my $l = <$IN>) {
		if ($l=~ /^>/) {
			$cnt++;
		}
	}
	close $IN;
	return $cnt;
}

sub count_reads_for_fastq {
	my ($file) = @_;

	my $IN = get_filehandle($file);
	my $cnt = 0;
	while (my $line = <$IN>) {
		if ($line =~ /^\@/) {
			$cnt++;
			<$IN>;
			<$IN>;
			<$IN>;
		}
	}
	close $IN;
	return $cnt;
}

sub count_reads_for_sam {
	my ($file, $skip_unmapped) = @_;

	my $IN = get_filehandle($file);
	my $cnt = 0;
	while (my $l = <$IN>) {
		if ($l =~ /^\@[A-Za-z][A-Za-z](\t[A-Za-z][A-Za-z0-9]:[ -~]+)+$/ or $l =~ /^\@CO\t.*/) {
			next; # skip header
		}
		if ($skip_unmapped) {
			my ($qname, $flag) = split(/\t/, $l);
			if ($flag & 4) {
				next;
			}
		}
		$cnt++;
	}
	close $IN;
	return $cnt;
}

sub count_reads_for_bed {
	my ($file) = @_;

	my $IN = get_filehandle($file);
	my $cnt = 0;
	while (my $l = <$IN>) {
		next if ($l =~ /^(track|browser)/);
		$cnt++;
	}
	close $IN;
	return $cnt;
}

sub get_filehandle {
	my ($file) = @_;

	my $read_mode;
	my $HANDLE;
	if (!defined $file) {
		open ($HANDLE, '<-', $file);
	}
	elsif ($file =~ /\.gz$/) {
		open($HANDLE, 'gzip -dc ' . $file . ' |');
	}
	else {
		open ($HANDLE, '<', $file);
	}

	return $HANDLE;
}

sub file_exists {
	my ($file) = @_;

	return 0 if !-e $file;
	return 1;
}

sub guess_input {
	my ($file) = @_;

	if ($file =~ /\.fastq(.gz)*$/) {
		return 'FASTQ';
	} elsif ($file =~ /\.fasta(.gz)*$/ or $file =~ /\.fa(.gz)*$/) {
		return 'FASTA';
	} elsif ($file =~ /\.sam(.gz)*$/) {
		return 'SAM';
	} elsif ($file =~ /\.bed(.gz)*$/) {
		return 'BED';
	}
}
