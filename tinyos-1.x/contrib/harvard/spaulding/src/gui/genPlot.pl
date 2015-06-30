#!/usr/bin/perl
use strict;
use Cwd;
use File::Basename;
use Switch;


my $NBR_CHANS = 6;
my $MAX_SAMPLE_VAL = 4096;

# ======================= Main ==================================
my @nodeIDs = getNodes();
my $gnuplotScriptFile = genGnuplotScript(@nodeIDs);

# # Call gnuplot to generate plot
my $cmd = "gnuplot < \"$gnuplotScriptFile\"";
print "$cmd\n";
system($cmd);

# my $ret = getChanName(7);
# print "Chan name: $ret \n";


# ======================= Functions ==================================

# Returns an array of node ID from the current directory
# @nodeIDs bandFilterNodes();
sub getNodes 
{
    # (1) - Read in all files in current directory
    opendir(DIR, '.') || die "Cannot open . for reading\n";
    my @subdirs = sort( grep(-f $_, readdir(DIR)) );
    closedir(DIR);
    
    # (2) - Bandpass-filter each file of type node-xxx.filtered
    # (a) Get nodes for which we have .filtered files
    my @nodes;
    foreach my $file (@subdirs) {
        if ($file =~ /^node\-(\d+).samples/) {
            my $nodeID = int($1);
            push(@nodes, $nodeID);
        }
    }
    
    return @nodes;
}

sub getChanName
{
    (my $chanIndex) = @_;
    
    switch ($chanIndex) {
        case 0  { return "Acc X"; }
        case 1	{ return "Acc Y"; }
        case 2	{ return "Acc Z"; }
        case 3  { return "Gyro X"; }
        case 4	{ return "Gyro Y"; }
        case 5	{ return "Gyro Z"; }
        else	{ return "Chan $chanIndex"; }
    }
}


# Generates a gnuplot script for the given nodes to plot
# scriptFileName genGnuplotScript(@nodeIDs);
sub genGnuplotScript
{
    my @nodes = @_;
    my $scriptFile = "plotChans.gp";
    open(GPLOT, ">$scriptFile") || die "plotBandFilt.gp\n";

#     my $eventDate = basename(cwd());
#     $eventDate =~ s/_/\\\\_/;
#     print GPLOT "set title\"" . $eventDate . "\\n(timeOffset= $timeOffset)\"\n";
    print GPLOT "set xlabel \"Global time (sec)\"\n";
#     print GPLOT "set ylabel \"NodeID (relative distance)\"\n";
#    print GPLOT "set grid\n";
#     print GPLOT "set xrange[20:45]\n";
    print GPLOT "set yrange[0:" . ($NBR_CHANS * $MAX_SAMPLE_VAL) . "]\n";
    print GPLOT "set terminal postscript eps enhanced color solid\n";


    #set ytics ("213" 0, "208" 1, "206" 2, "209" 3, "201" 4, "202" 5, "205" 6, "210" 7)
    # the ytics
    for (my $c = 0; $c < $NBR_CHANS; $c++) {
        if ($c == 0) {print GPLOT "\nset ytics (";}
        else         {print GPLOT ", ";}
        my $yOffset = $c * $MAX_SAMPLE_VAL + $MAX_SAMPLE_VAL / 2.0;
        my $chanName = getChanName($c);
        print GPLOT "\"$chanName\" $yOffset";
    }
    print GPLOT ")\n";


    for (my $i = 0; $i <= $#nodes; $i++) {
        my $node = $nodes[$i];
        print GPLOT "\n\nset output \"plot-${node}.eps\"";

        for (my $c = 0; $c < $NBR_CHANS; $c++) {
            if ($c == 0) {print GPLOT "\nplot ";}
            else         {print GPLOT ", \\\n     ";}
            my $col = $c+2;
            my $yOffset = $c * $MAX_SAMPLE_VAL;
            print GPLOT "\"node-${node}.samples\" using 1:(\$$col+${yOffset}) notitle with lines";
        }
    }

    print GPLOT "\n";
    close(GPLOT);

    return $scriptFile;
}
