#!/usr/bin/perl
@start = (1,2,3,4,5,6,7,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,24,25,1000);
$idx = 0;
while (<>) {
    $search =  @start[$idx];
    if (/^$search/) {
	print "\n\n" ;
	print  $_ ;
	$idx ++;
    } else {
	print $_ ;
    }

}
close OUTF;
