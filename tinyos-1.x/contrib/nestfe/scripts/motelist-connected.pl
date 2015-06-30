#!/usr/bin/perl

$usage .= "$0 - Checks which motes in config_file are not connected via a \n";
$usage .= "COM port.  Assumes output of motelist is piped in as standard in.\n";
$usage .= "\n";
$usage .= "Usage: motelist | $0 config_file [-f FTDI_field] [config_file ...]\n";
$usage .= "FTDI_field is indexed starting from 0\n";
$usage .= "\n";


while (@ARGV) {
    last unless $ARGV[0] =~ /^-/;
    $opt = lc shift;
    if ($opt eq "-f") {defined($FTDI_field = shift) or die $usage;}
    elsif ($opt eq "--help" || $opt eq "-h") {die  $usage;}
    else {die "$usage\nUnknown option: $opt \n"}
}

if (!defined $FTDI_field) {
    $FTDI_field = 0; 
    print "Using field 0 as default FTDI field in config_file\n";
}

@configFiles = @ARGV;

%cfgMotes = ();
foreach $cfgFile (@configFiles) {
    open(CFGFILE,$cfgFile);
    @fileLines = <CFGFILE>;
    foreach $line (@fileLines) {
	@lineArr = split(/\s/,$line);
	if ($line =~ /^mote/) {
	    $FTDI_id = $lineArr[$FTDI_field];
	    $cfgMotes{$FTDI_id} = $line;
	}
    }
    close(CFGFILE);
}

# while (($key, $value) = each (%cfgMotes)) {
#     print "$key     :     $value\n";
# }

open(STDIN,'-');
%moteList = {};
while (<STDIN>) {
    @line = split;
    if (/COM/) {
	$FTDI_id = $line[0];
	$moteList{$FTDI_id} = $_;
    }
}
close(STDIN);

foreach $FTDI_id (keys %cfgMotes) {
    $printflag = 1;
    foreach $moteListLine (values %moteList) {
	if ($moteListLine =~ /$FTDI_id/) {
	    $printflag = 0;
	}
    }
    if ($printflag == 1) {
	print "Missing $cfgMotes{$FTDI_id}\n";
    }
}
