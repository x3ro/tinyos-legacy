#!/usr/bin/perl

while (<>)
{
    chomp;
    if (/^module\s+(\w+)/) {
	$module = $1;
	$configuration = $module;
	$configuration =~ s/M$//;
    }
    if (/^\s*\/\/FN\s+(.*)/) {
	if (!defined $module) {
	    print STDERR "$ARGV:$.: Module name unknown.\n";
	    $module = $configuration = "unknown";
	    $error = 1;
	}
	$spec = $1;
	for (;;) {
	    $_ = <>;
	    last if !$_ || !/^\s*\/\/(.*)/;
	    $spec = "$spec\n$1";
	}
	$msg = 0;
	if ($spec =~ /^(:?[a-zA-Z][a-zA-Z0-9$_:?!]*):\s+((.|\n)*)$/) {
	    $fn = $1;
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
	undef $module;
    }
}

exit 2 if $error;

die unless open(ALLFNS, ">gen/allfns.vmsf");
foreach $fn (@functions) {
    print "$fn: numparams=$numparams{$fn} returnval=$returnval{$fn} desc=\"$help{$fn}\"\n";

    $cname = "m$fn";
    $cname =~ tr/A-Z/a-z/;
    $cname =~ s/[$:]/_/g;
    $cname =~ s/\?/p/g;
    $cname =~ s/!/b/g;

    print ALLFNS "<FUNCTION name=$cname>\n";

    die unless open (ODF, ">gen/OP$cname.odf");
    print ODF "<FUNCTION name=$cname opcode=$cname username=$fn numparams=$numparams{$fn} returnval=$returnval{$fn} desc=\"$help{$fn}\">\n";
    close ODF;
    die unless open (OPNC, ">gen/OP$cname.nc");
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
