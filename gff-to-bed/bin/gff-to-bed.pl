#!/usr/bin/env perl

use warnings;
use strict;

while (my $l = <>) {
	chomp $l;
	next if $l =~ /^#/;
	my @A = split(/\t/, $l);
	print join("\t", $A[0], --$A[3], $A[4], '.', 0, $A[6])."\n";
}
