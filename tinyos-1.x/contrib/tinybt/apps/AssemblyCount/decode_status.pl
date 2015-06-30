#!/usr/bin/perl -w

# This script decodes a status error for the assembly component. 
# It does so by scanning the source to AssemblyM.nc, which should
# be located in the directory where the script is executed.
# Some values are hardcoded directly into this script.

# This program is far from perfect, but is a good help when debugging.

# Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Some constants
$component = "debug.h";


# Hardcoded, needs to be changed manually
$bterror{0}="OK";
$bterror{1}="UNKNOWN_PTYPE";
$bterror{2}="UNKNOWN_PTYPE_DONE";
$bterror{3}="EVENT_PKT_TOO_LONG";
$bterror{4}="ACL_PKT_TOO_LONG";
$bterror{5}="UNKNOWN_EVENT";
$bterror{6}="UNKNOWN_CMD_COMPLETE";
$bterror{7}="HW_ERROR";
$bterror{8}="UNABLE_TO_HANDLE_EVENTS";
$bterror{9}="HCIPACKET_SEND_OVERFLOW";

sub usage() {
    print STDERR "Usage: $0 <--debug code | num1 [num2 ...]>\n";
    exit -1;
}

# Read all the defines, etc 
sub prepare() {
    open(INPUT, "<$component")
	|| die("Unable to open $component");
    $fail_sub = "FIRST";
    # Match on all the defines
    while(<INPUT>) {
	if (m/DECODE\:FAIL\_([^\s]*)/) {
	    $fail_sub = "FAIL_$1";
#	    print STDERR "DECODE: $fail_sub\n";
	} elsif (m/^\#define (FAIL\_[^\s]+)\s*(\d+)/) {
#	    print "Got one, -$1-==-$2-\n";
	    if (!defined $$fail_sub{$2}) { 
		$$fail_sub{$2} = $1;
	    } else {
		$$fail_sub{$2} .= ", ".$1;
	    }
	} elsif (m/^\#define (DEBUG\_[^\s]+)\s*(\d+)/) {
	    if (!defined $DEBUG{$2}) {
		$DEBUG{$2} = "    ".$1."\n";
	    } else {
		$DEBUG{$2} = $DEBUG{$2}."    ".$1."\n";
	    }
	} elsif (m/^\s+(cs[^\s=]*)\s*\=\s*(\d+)/) {
	    $childStates{$2} = $1;
#	    print "GOT childstate: -$1- == -$2-\n";
	} elsif (m/^\s+(ps[^\s=]*)\s*\=\s*(\d+)/) {
	    $parentStates{$2} = $1;
#	    print "GOT childstate: -$1- == -$2-\n";
	}
    }
    close(INPUT);
}

prepare();

# Read the args, so on.
@args = @ARGV;
$arg1 = shift(@ARGV);
if (!defined $arg1 || "" eq $arg1) {
    usage();
}

print "Decoding @args\n";

# Check debug
if ("--debug" eq $arg1) {
    $arg2 = shift(@ARGV);
    if (!defined $arg2 || "" eq $arg2) {
	usage();
    }
    if (!defined $DEBUG{$arg2}) {
	print "  UNKNOWN DEBUG MSG FOR : $arg2\n";
    } else {	
	print "  event is one of:\n".$DEBUG{$arg2};
    }
    exit;
}

######################################################################
# Get the first arg, check if we encode stuff in the 0 bit.
$btdev = "";
$btdevs = "";
if ($arg1 >= 4 && $arg1 <= 13) {
    if ((0x1 & $arg1) == 0) {
	$btdev  = 0;
	$btdevs = " for BT_DEV_0";
    } else {
	$arg1--;
	$btdev  = 1;
	$btdevs = " for BT_DEV_1";
    }
}

$base = $FIRST{$arg1};
if (!defined $base) {
    print "UNKNOWN BASE FAILURE CODE: $arg1\n";
    exit -1;
}
# Print the base/first arg
print $FIRST{$arg1}.$btdevs."\n";


########################################################################
# Now, check the second arg, special case STATEFAIL and BT
$next_arg = shift(@ARGV);
if(defined $next_arg && "" ne $next_arg) {
    if ("FAIL_STATEFAIL" ne $base && "FAIL_BT" ne $base) {
	if (!defined $$base{$next_arg}) {
	    print "  UNKNOWN SUBTYPE : $next_arg\n";
	} else {
	    print "  ".($$base{$next_arg})."\n";
	}
    } else {
	# Do something special
	if ("FAIL_STATEFAIL" eq $base) {
	    # statefail, second arg is childstate or parent state, depending on 
	    # btdevice
	    if (0 == $btdev) {
		if (!defined $childStates{$next_arg}) {
		    print "  UNKNOWN CHILD STATE : $next_arg\n";
		} else {
		    print "  state was: ".$childStates{$next_arg}."\n";
		}
	    } else {
		if (!defined $parentStates{$next_arg}) {
		    print "  UNKNOWN PARENT STATE : $next_arg\n";
		} else {
		    print "  state was: ".$parentStates{$next_arg}."\n";
		}
	    }
	} else {
	    #btfail
	    if (!defined $bterror{$next_arg}) {
		print "  UNKNOWN BTERROR : $next_arg\n";
	    } else {
		print "  code is: ".$bterror{$next_arg}."\n";
	    }
	}
    }
}

######################################################################
# Now, the remaining, special case STATEFAIL and BT
$next_arg = shift(@ARGV);
while(defined $next_arg && "" ne $next_arg) {
    if ("FAIL_STATEFAIL" eq $base) {
	if (!defined $DEBUG{$next_arg}) {
	    print "  UNKNOWN DEBUG MSG FOR : $next_arg\n";
	} else {	
	    print "  event is one of:\n".$DEBUG{$next_arg};
	}
    } else {
	printf "    0x%x", $next_arg;
	if (defined $$base{$next_arg}) {
	    print " / ".($$base{$next_arg})."\n";
	} else {
	    print "\n";
	}
	
    }
    $next_arg = shift(@ARGV);
}


#print %FIRST;
#print "\n";
#print %DEBUG;
#print "\n";
