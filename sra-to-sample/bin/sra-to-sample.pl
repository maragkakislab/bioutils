#!/usr/bin/env perl

use warnings;
use strict;
use Getopt::Long::Descriptive;
use File::Path qw(make_path);
use JSON;

# Define and read command line options
my ($opt, $usage) = describe_options(
	'%c %o',
	['json=s', 'JSON file with samples', { required => 1}],
	['down-dir=s', 'directory for SRA download', { required => 1}],
	['o-dir=s', 'output dir for samples', { required => 1}],
	['skip-download', 'skip download of SRA files'],
	['help|h', 'print usage message and exit'],
);
print($usage->text), exit if $opt->help;

my ($json_file, $down_dir, $samples_dir) = ($opt->json, $opt->down_dir, $opt->o_dir);

my $json;
{
	local $/;
	open(my $json_fh, "<", $json_file) or die("Can't open $json_file\": $!\n");
	$json = <$json_fh>
};

my $data = decode_json($json);
my @samples = @{$data->{samples}};

# Create the output directory for the download.
make_path($down_dir);

# Download SRA.
if (!$opt->skip_download) {
	foreach my $s (@samples) {
		my @accessions = @{$s->{sra}};
		foreach my $a (@accessions) {
			system "fastq-dump --outdir $down_dir/ --gzip --skip-technical --dumpbase --split-files --clip $a";
		}
	}
}

# Create the output directory for the download.
make_path($samples_dir);

# Concatenate files.
my @all_cmds;
foreach my $s (@samples) {
	my $name = $s->{name};
	my @accessions = @{$s->{sra}};
	my $odir = "$samples_dir/$name/fastq/";
	make_path($odir);

	my (@read1_files, @read2_files);
	foreach my $a (@accessions) {
		my $f = $down_dir . "/" . $a . '_1.fastq.gz';
		if (-e $f) {
			push @read1_files, $f;
		}
		$f = $down_dir . "/" . $a . '_2.fastq.gz';
		if (-e $f) {
			push @read2_files, $f;
		}
	}

	my @cmds;
	if (@read1_files > 0) {
		push @cmds, "zcat " . join(" ", @read1_files) . " | gzip > $odir/reads.1.fastq.gz";
	}
	if (@read2_files > 0) {
		push @cmds, "zcat " . join(" ", @read2_files) . " | gzip > $odir/reads.2.fastq.gz";
	}
	push @all_cmds, @cmds;

	my $readme_f = "$samples_dir/$name/README";
	if (-e $readme_f) {
		die "error writing file $readme_f: file exists";
	}
	open(my $README, ">", $readme_f);
	print $README join("\n", @cmds)."\n";
	close $README;
}
my $cmds_string = join("\n", @all_cmds);
system "echo \"$cmds_string\" | xargs -P 8 -I COMMAND sh -c \"COMMAND\"";
