#!/usr/bin/perl

# Author: Phoebus Chen
# $Id: tb_start_sf_matlab.pl,v 1.1 2004/10/07 18:41:34 phoebusc Exp $
# Based off of testbed_start_sf.pl

use TinyOS::Util::TestBedConfig;

$config_file = $ENV{'TOS_TESTBED_CONFIG'};
$conn_string_file = $ENV{'TESTBED_CURRENT_CONN_FILE'};
$TESTBED_PORT_BASE = 9100;
$GUI = "-no-gui";
$verbose = 0;

$usage .= "$0 - Starts Serial Forwarder and simultaneously dumps strings\n";
$usage .= "naming open connections to a text file for access by MATLAB.\n";
$usage .= "\n";
$usage .= "Usage: $0 [-f config_file] [-o out_file] [-v] [--gui|--nogui]";
$usage .= " [moteID1 ...]\n";
$usage .= "\n";
$usage .= "-f  file containing the configuration of motes in your testbed.\n";
$usage .= "    Otherwise, defaults to \$TOS_TESTBED_CONFIG.\n";
$usage .= "\n";
$usage .= "-o  file for dumping connection strings.  Otherwise defaults to \n";
$usage .= "    \$TESTBED_CURRENT_CONN_FILE.\n";
$usage .= "\n";
$usage .= "-v  verbose output (defaults to non-verbose)\n";
$usage .= "\n";
$usage .= "--gui serial forwarder started with a gui\n";
$usage .= "--nogui serial forwarder started with no gui\n";
$usage .= "\n";
$usage .= "moteID1 ... arbitrary length list of moteIDs that you wish to\n";
$usage .= "    connect to.  Can use - to specify ranges (ex. 1-10\n";
$usage .= "    specifies all of motes 1 thru 10) and can mix and combine\n";
$usage .= "    them (ex. 1 2-4 13-17)..  If none are specified,\n";
$usage .= "    connects to all motes in the configuration file.\n";
$usage .= "\n";
$usage .= "NOTE: uses TinyOS Perl packages.  Also, default behavior\n";
$usage .= "assumes that the environment variable\n";
$usage .= "\$TESTBED_CURRENT_CONN_FILE is defined to point to where you\n";
$usage .= "wish to dump the connection strings.\n";


#Argument processing
while (@ARGV) {
    last unless $ARGV[0] =~ /^-/;
    $opt = lc shift;
    if ($opt eq "-f") {defined($config_file = shift) or die $usage;}
    elsif ($opt eq "-o") {defined($conn_string_file = shift) or die $usage;}
    elsif ($opt eq "-v") {$verbose = 1;}
    elsif ($opt eq "--gui") {$GUI = "";}
    elsif ($opt eq "--nogui") {$GUI = "-no-gui";}
    elsif ($opt eq "--help" || $opt eq "-h") {die  $usage;}
    else {die "$usage\nUnknown option: $opt \n"}
}

@moteList = @ARGV;
if (scalar(@moteList) == 0) {$process_all = 1;} else {$process_all = 0;}
#parsing ranges in moteList
undef $process_motes;
foreach $moteRange (@moteList) {
    if ($moteRange =~ /-/) {
	for ($i = $`; $i <= "$'"; $i++) { #quote $' for proper syntax highlight
	    $i =~ s/^0*//g; #remove 0s in beginning of string
	    $process_motes{$i} = 1;
	}
    } elsif ($moteRange =~ /\d+/) {
	$moteRange =~ s/^0*//g; #remove 0s in beginning of string
	$process_motes{$moteRange} = 1;
    } else { die "Invalid mote id input.  Must be a number or a range."}
}

if (!defined $conn_string_file) {
    die "You have not speci fied where to dump the connection strings,\n".
	"either through the -o option, or through the environment variable\n".
	"\$TESTBED_CURRENT_CONN_FILE.  Aborting...\n";
}

if (!defined $config_file) {
  die "No testbed config file! \n".
      "Please provide a config file either through the environment variable\n".
      "\$TOS_TESTBED_CONFIG or by the command line (type $0 --help\n".
      "for more info)\n";
}





$cfg = TinyOS::Util::TestBedConfig->new($config_file);

print "Read config file $config_file with ".$cfg->getNumberOfMotes().
      " motes\n";
print "Starting serial forwarders...\n";
!$verbose && print "connected to ports: ";
$cfg->getMotes(\@motes);
for $mote (@motes) {
    $idfield = $mote->{'id'};
    $idfield =~ s/^0*//g; #remove 0s in beginning of string to match user input
    if ($process_all || $process_motes{$idfield}) {
	$port = $TESTBED_PORT_BASE + $mote->{id};
	$verbose && print "Serial forwarder for id $mote->{id}".
	    "($mote->{address}) at port $port\n";
	!$verbose && print "$port ";
	$cmd .= "java net.tinyos.sf.SerialForwarder $GUI -comm network\@".
	    $mote->{address}.":10002 -port $port &\n";
	$conn_strings .= "sf\@localhost:$port\n";
    }
}

system($cmd); #executes command

open(CONNFILE,">$conn_string_file");
print CONNFILE "$conn_strings";
close(CONNFILE);

$verbose && print $cmd;
!$verbose && print "\n";
print "done.\n";
