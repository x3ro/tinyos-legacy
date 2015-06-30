#! /usr/bin/perl
use TinyOS::Util::TestBedConfig;
use FindBin qw($Bin);

$BASEDIR = $Bin."../..";

#Sends the get_id command to all motes 

$config_file = $ENV{'TOS_TESTBED_CONFIG'};
$TESTBED_PORT_BASE = 9100;
$HOST = "mirage.berkeley.intel-research.net";
#$TESTBED_PORT_BASE = 54000;
#$HOST = "motelab.eecs.harvard.edu" ;

#Try argv
if (scalar(@ARGV) == 1) {
  $config_file = @ARGV[0];
}

if (!defined $config_file) {
  die "No testbed config file! \n Please provide a config file either through the environment TOS_TESTBED_CONFIG or \n".
      "by the command line as testbed_start_sf.pl <config_file>\n";
}

$cfg = TinyOS::Util::TestBedConfig->new($config_file);

print "Read config file $config_file with ". $cfg->getNumberOfMotes() . " motes\n";

#get info about the motes
$BVR_HOME = $BASEDIR;
$current_id_file = "$BVR_HOME/apps/.ident_install_id";
$id = `cat $current_id_file`;

$RETRIES = 3;
$cfg->getMotes(\@motes);
for $mote (@motes) {
  	$port = $TESTBED_PORT_BASE + $mote->{id};
	$retries = $RETRIES;
	$i = $mote->{id};
	$ident = -1;
	while ($retries && ($ident==-1)) {
		$cmd = "MOTECOM=sf\@$HOST:$port java net.tinyos.bvr.BVRCommandInject 0xd $i get_id";

		print $cmd."\n";
		$result = `$cmd`;
		
		($ident) = $result =~ /install_id=(0x[0-9a-fA-F]+)/m or (-1);
		$retries--;
	}
	$ident{$i} = hex $ident;
}

print "Current id = $id\n";
for $i (sort {$a <=> $b} keys %ident) {
	print "id for mote $i: $ident{$i}\n";
}
	

