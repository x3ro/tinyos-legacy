#!/usr/bin/perl
use strict;
use Cwd;
use File::Basename;

my $node = @ARGV[0];
if ($node eq "") {
    my $progName = basename($0);
    print "Usage: $progName <nodeID>\n\n";
    print "  Example: ./$progName 10 \n";
    print "  Example: ./$progName 11\n";
    exit(1);
}

system("cd samplingSessions");

# (1) - Read in all files in current directory
opendir(DIR, '.') || die "Cannot open . for reading\n";
my @subDirs = sort( grep(/200/ && -d $_, readdir(DIR)) );
closedir(DIR);

# (2) - Run the plotting and displaying
my $lastDir = @subDirs[$#subDirs];
#my $gsview = "/cygdrive/c/Utilities/Ghostscript/Ghostgum/gsview/gsview32.exe";
my $gsview = "/cygdrive/c/Office/Ghostscript/Ghostgum/gsview/gsview32.exe";

system("cd $lastDir && ../../genPlot.pl && $gsview plot-${node}.eps");
