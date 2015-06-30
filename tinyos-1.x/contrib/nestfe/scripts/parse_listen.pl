#!/usr/bin/perl

# Reads from StdIn the data and outputs:
# 1) number of Drip, Drain, and Deluge messages
# 2) pkts/sec
# 
# Usage: parse_listen.pl [seconds]
# [seconds] is the number of seconds between updates.  If it is
#           blank or 0, it outputs these statistics only after an end of
#           file is reached.
# 
# ex.  listen | tee log_file.txt | parse_listen.sh 1

use POSIX qw(ceil); #for ceiling function
use threads;
use threads::shared;

$DripStr = "^([A-F0-9]{2}\ ){4}FF FF FF FF 03 0A";
$DrainStr = "^([A-F0-9]{2}\ ){4}FF FF FF FF 04 0A";
$DelugeStr = "^([A-F0-9]{2}\ ){4}FF FF FF FF (A1)|(A2)|(A3) 0A";
$pktStr = "^([A-F0-9]{2}\ ){10}";

$timeItvl = $ARGV[0] || 0; #default to output only at the end
#Declare all "global" variables before the thread
my $moreInput : shared = 1; # a flag
my $pktCnt : shared = 0;
my $DripCnt : shared = 0;
my $DrainCnt : shared = 0;
my $DelugeCnt : shared = 0;

my $t = threads->create( printThread, ($timeItvl));

$startTime = time;
while (<STDIN>) {
#    print $_;
#    if (/^([A-F0-9]{2}\ ){4}FF FF FF FF 03 0A/) { # Drip String
    if (/$DripStr/) { # Drip String
	$DripCnt++;
    } elsif (/$DrainStr/) { # Drain String
	$DrainCnt++;
    } elsif (/$DelugeStr/) { # Deluge String
	$DelugeCnt++;
    } else { # Unknown String
	print "Unknown String:\n$_ \n";
    }
    if (/$pktStr/) { #ignores other types of lines, like comments
	$pktCnt++;
    }
}
$endTime = time;
$moreInput = 0;
$t->join;
# Print a final report
if ($timeItvl eq 0) {
    $runTime = ceil($endTime - $startTime);
    if ($runTime eq 0) {
	print "Ran program for less than 1 second.  Calculating data rates\n";
	print "assuming packets arrived over period of 1 second\n";
	$runTime = 1;
    }
    &printRpt($runTime);
}



#### Threads
sub printThread
{
    if ($_[0] ne 0) {
	while ($moreInput) {
	    sleep $_[0];
	    &printRpt($_[0]);
	    $DripCnt = 0;
	    $DrainCnt = 0;
	    $DelugeCnt = 0;
	    $pktCnt = 0;
	}
    }
}


# Last one may be inaccurate if input ends early
sub printRpt
{
    $pktRate = $pktCnt/$_[0];
    print "----------------------------------------\n";
    print "# Drip Pkts: $DripCnt\n";
    print "# Drain Pkts: $DrainCnt\n";
    print "# Deluge Pkts: $DelugeCnt\n";
    print "Pkts/sec: $pktRate\n";
#    printf("Pkts/sec: %.2f\n",$pktRate);
}
