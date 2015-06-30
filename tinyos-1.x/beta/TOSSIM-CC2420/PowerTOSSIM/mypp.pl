#!/usr/bin/perl -w 

# A script to preprocess the code that's been run through cilly before
# compiling it.  Fixes the number of basic blocks in several places

$usage = "Usage: mypp.pl file.c\n";
# Output is file.mypp.c

die $usage unless $ARGV[0]; 

$infile = $ARGV[0];
$outfile = $infile;
$outfile =~ s/\.c$/.mypp.c/;

die "ERROR: Not a .c file specified\n$usage" if($infile eq $outfile);

open (INPUT, $infile) || die "can't open $infile: $!";

$max = 0;
while(<INPUT>) {
    if(/^\s*bb_count\[42\]\[(\d+)\]/) {
	$max = $1 if ($1 > $max);
    }
}

$max++;  # Since things start with 0
print STDERR "There are $max basic blocks\n";
close INPUT;

# Now max contains the number of basic blocks
open (INPUT, $infile) || die "can't open $infile: $!";
open (OUTPUT, ">$outfile") || die "can't open $outfile: $!";

while(<INPUT>) {
    if(/int POWERPROF_BB_EXEC_COUNT/) {
	# Skip the declaration
	print OUTPUT $_;
	next; 
    }
	

    s/bb_count\[10000\]\[0\]/bb_count\[10000\]\[$max\]/;

    s/bb_count\[42\]/bb_count\[tos_state.current_node\]/g;

    s/int POWERPROF_NUM_BBS/int POWERPROF_NUM_BBS = $max/;    

    s/POWERPROF_BB_EXEC_COUNT/bb_count\[mote\]\[bb\]/g;

    print OUTPUT $_;
}
