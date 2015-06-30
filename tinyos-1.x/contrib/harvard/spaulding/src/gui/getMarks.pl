#!/usr/bin/perl -w
use strict;

my $markerNbr = 0;
my $currMarkerY=6000;

while (<STDIN>) {
#    ($_ =~ s/( )+/\t/g);   # replace 1 or more consecutive whitespances with tab
    #print STDOUT $_;
    if ( $_ =~ m/globalTime= (\d+) markerName= (\w+)/ ) {
        my $x = $1/32768;
        my $y = 4096*7;
        if    ($markerNbr == 0) {$currMarkerY = 6*4096+1000;}
        elsif ($markerNbr == 1) {$currMarkerY = 6*4096+2000;}
        elsif ($markerNbr == 2) {$currMarkerY = 6*4096+3000;}
        else                    {$currMarkerY = 6*4096+4000;}

        print "set arrow nohead from $x,0 to $x,$y\n";
        print "set label \"$2\" at $x,$currMarkerY\n";
        $markerNbr = ($markerNbr+1) % 4;
    }
}
