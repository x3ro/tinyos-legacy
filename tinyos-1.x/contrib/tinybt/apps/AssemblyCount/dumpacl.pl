#!/usr/bin/perl -w

# Program to translate hcidump -a output to something easier to read. 
# Drops some packets that we do not care about

$SETCOLOR_ACLINPUT="echo -en '\033[0;32m'";
$SETCOLOR_INPUT="echo -en '\033[1;32m'";
$SETCOLOR_ACLOUTPUT="echo -en '\033[0;31m'";
$SETCOLOR_OUTPUT="echo -en '\033[1;31m'";
$SETCOLOR_YELLOW="echo -en '\033[1;33m'";
#$SETCOLOR_NORMAL="echo -en '\033[0;39m'";

$nextl = "";

while(<>) {
    $date = `date +"%H%M%S.%N"`;
    chop($date);
    if ($nextl ne "") {
	if (m/G\so\st\s*m/) {
	    system($SETCOLOR_YELLOW);
	}
	print $date."\t".$_;

	$nextl = "";
    }
    if (m/\< ACL/) {
	$nextl = "output";
	system($SETCOLOR_ACLOUTPUT);
	print $date."\t".$_;
	system($SETCOLOR_OUTPUT);
    }
    if (m/\> ACL/) {
	$nextl = "output";
	system($SETCOLOR_ACLINPUT);
	print $date."\t".$_;
	system($SETCOLOR_INPUT);
    }
}
