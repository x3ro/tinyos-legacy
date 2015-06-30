#!/usr/bin/perl

$usage = "mps_to_cfg.pl <mps file>\n";

$mps_file = shift @ARGV;

die $usage if (! defined $mps_file);
open FH, "$mps_file" or die "Can't open $mps_file\n";
$cfg_file = $mps_file;
$cfg_file =~ s/\.mps//;
$cfg_file .= ".cfg";
 
open FOUT,">$cfg_file" or die "Can't create output file $cfg_file\n";

print "Converting $mps_file to $cfg_file\n";

while(<FH>) {
	chomp;
	($id,$x,$y) = split;
	print FOUT "mote $id nohost $x $y\n";
}

