#!/usr/bin/perl -w
use strict;

while (<STDIN>) {
#    ($_ =~ s/( )+/\t/g);   # replace 1 or more consecutive whitespances with tab
    print STDOUT $_;
    if ( $_ =~ m/globalTime= (\d+) markerName= (\w+)/ ) {
        print "==> " . $1 . ", " . $2 . "\n";
    }
}
