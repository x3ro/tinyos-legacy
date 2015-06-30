#!/usr/bin/perl -w

# Script to convert output of channel lines into data gnuplot can
# use.

$fileprefix = shift(@ARGV);
$numnodes = shift(@ARGV);

if (!defined $numnodes || "" eq $numnodes) {
    print STDERR "Usage: $0 <fileprefix> <numnodes>\n";
    exit -1;
}

for ($i = 0; $i < $numnodes; $i++) {
    $DATAFILE{$i} = "DATAFILE$i";
}


# Open all datafiles
for ($i = 0; $i < $numnodes; $i++) {
    open ($DATAFILE{$i}, ">$fileprefix.$i") || die "Could not open output file\n";
}


# Set lasts values
for ($i = 0; $i < $numnodes; $i++) {
    $last{$i} = 0;
}


while(<>) {
    # if (m/slot (\d+)\)\:.*\=(\d\d) (\d+)^/) {
    if (m/slot (\d+)\)\:.*\=(\d+)\s+(\d+)/) {
	# Check for two points pr. slot...
	if ($last{$3} == $1) {
	    $last{$3} = $1 + 0.5; 
	} else {
	    $last{$3} = $1; 
	}
	print { $DATAFILE{$3} } "$last{$3} $2\n";
    } else {
	print STDERR "No match for $_";
    }
}

for ($i = 0; $i < $numnodes; $i++) {
    close ($DATAFILE{$i}) || die "Could not close output file\n";
}


print "quickplot --no-lines --same-scale --point-size 2 ";
for ($i = 0; $i < $numnodes; $i++) {
    print "$fileprefix.$i ";
}
print "\n";

