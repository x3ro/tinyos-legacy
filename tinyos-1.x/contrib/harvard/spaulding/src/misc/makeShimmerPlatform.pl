#!/usr/bin/perl
use strict;

print "********** Preparing SHIMMER **********\n";
my @cmds = ('ln -s $SPAULDINGSRC/misc/platform/shimmer $TOSROOT/tos/platform/shimmer',
            'ln -s $SPAULDINGSRC/misc/make/shimmer.target $TOSROOT/tools/make/shimmer.target',
            'cp $SPAULDINGSRC/misc/make/all.target $TOSROOT/tools/make/all.target');

foreach (@cmds) {
    print " --> $_ \n";
    system($_);
}
