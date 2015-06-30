#!/usr/bin/perl
#
# Copyright (c) 2004-2005 Intel Corporation
# All rights reserved.
#
# This file is distributed under the terms in the attached INTEL-LICENSE     
# file. If you do not find these files, copies can be found by writing to
# Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
# 94704.  Attention:  Intel License Inquiry.

if ($ARGV[0] eq "-scheme") {
    shift;
    $scheme = true;
}

$target = shift @ARGV;

$dir = `dirname $target`;
chomp $dir;

while (<>)
{
    chomp;
    if (/^module\s+(\w+)/) {
	$configuration = $1;
	$configuration =~ s/M$//;
    }
    if (/^configuration\s+(\w+)/) {
	$configuration = $1;
    }
    if (/^\s*\/\/FN\s+(.*)/) {
	if (!defined $configuration) {
	    print STDERR "$ARGV:$.: Component name unknown.\n";
	    $configuration = "unknown";
	    $error = 1;
	}
	$spec = $1;
	for (;;) {
	    $_ = <>;
	    last if !$_ || !/^\s*\/\/(.*)/;
	    $spec = "$spec\n$1";
	}
	$msg = 0;
	if ($spec =~ /^([!\$%&*\/:<=>?~_^a-zA-Z][!\$%&*\/:<=>?~_^a-zA-Z0-9.+-]*|[+]|[-]|[|]):\s+((.|\n)*)$/) {
	    $fn = $1;
	    unless ($scheme) {
		$fn =~ s/->/2/g;
		$fn =~ s/-/_/g;
	    }
	    $help = $2;

	    push @functions, $fn;
	    $help{$fn} = $help;
	    $configuration{$fn} = $configuration;

	    if ($help =~ /^([a-zA-Z0-9\. ]+|)\s*->\s*([a-zA-Z0-9]*)\s*\./) {
		$args = $1;
		$result = $2;
		if ($args =~ /\.\.\./) {
		    $numparams{$fn} = -1;
		}
		else {
		    $numparams{$fn} = split /\s+/, $args;
		}
		$returnval{$fn} = $result ne "" ? "true" : "false";

		if (/command\s+result_t\s+(\w+)\s*\.\s*execute\s*\(\s*uint8_t/) {
		    $interface{$fn} = $1;
		}
		elsif (/interface\s+MateBytecode\s+as\s+(\w+)\s*;/) {
		    $interface{$fn} = $1;
		}
		else {
		    $msg = "command for $fn not found on next line";
		}
	    }
	    else {
		$msg = "Invalid signature";
	    }
	}
	else {
	    $msg = "Invalid function specification";
	}
	if ($msg) {
	    print STDERR "$ARGV:$.: $msg:\n  $spec\n";
	    $error = 1;
	}
    }
}
# this magic resets $. for us...
continue {
    if (eof) {
	close ARGV;
	undef $configuration;
    }
}

exit 2 if $error;

mkdir $dir;

die unless open(ALLFNS, ">$target");
foreach $fn (@functions) {
    $help = $help{$fn};
    #$help =~ s/\n/\\n\\\n/g;
    print "$fn: numparams=$numparams{$fn} returnval=$returnval{$fn} desc=\"$help\"\n";

    $cname = "mf_$fn";
    $cname =~ tr/A-Z/a-z/;
    $cname =~ s/->/2/g;
    $cname =~ s/[-\$]/_/g;
    $cname =~ s/\?/p/g;
    $cname =~ s/!/b/g;
    $cname =~ s/</_lt/g;
    $cname =~ s/>/_gt/g;
    $cname =~ s/=/_eq/g;
    $cname =~ s/[+]/_plus/g;
    $cname =~ s/[*]/_times/g;
    $cname =~ s/\//_slash/g;
    $cname =~ s/[|]/_bar/g;
    $cname =~ s/&/_ampersand/g;
    $cname =~ s/[\^]/_caret/g;

    print ALLFNS "<FUNCTION name=$cname>\n";

    die unless open (ODF, ">$dir/OP$cname.odf");
    print ODF "<FUNCTION name=$cname opcode=$cname username=\"$fn\" numparams=$numparams{$fn} returnval=$returnval{$fn} desc=\"$help\">\n";
    close ODF;
    die unless open (OPNC, ">$dir/OP$cname.nc");
    print OPNC <<CONF;
configuration OP$cname {
  provides interface MateBytecode;
}
implementation {
  components $configuration{$fn};
 
  MateBytecode = $configuration{$fn}.$interface{$fn};
}
CONF
    close OPNC;
}
close ALLFNS;
