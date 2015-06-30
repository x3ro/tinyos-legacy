#!/usr/bin/perl

do "../tools.pm";

$received1 = recv_base(1);
($dest1, $amid1, $group1, $len1, @remainder1) = unpack_message($received1);

$received2 = recv_base(1);
($dest2, $amid2, $group2, $len2, @remainder2) = unpack_message($received2);

# We test for a distance of 3 because packets are occasionally lost
# (hopefully we won't hit a terribly lossy phase...)
if (!($dest1 == $BROADCAST && $dest2 == $BROADCAST &&
      (($remainder2[0] - $remainder1[0]) & 0xff) <= 3)) {
    print "destinations not broadcast and/or counts not consecutive\n";
    print "1: "; print_message($received1);
    print "\n2: "; print_message($received2);
    print "\n";
    exit 2;
}

exit 0;
