#!/usr/bin/perl
@start = (102,103,104,105,106,107,108,109,110,111,99999);
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
