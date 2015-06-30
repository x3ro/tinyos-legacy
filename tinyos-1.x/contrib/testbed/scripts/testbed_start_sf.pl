#!/usr/bin/perl

use TinyOS::Util::TestBedConfig;

$config_file = $ENV{'TOS_TESTBED_CONFIG'};
$TESTBED_PORT_BASE = 9100;
$GUI = "-no-gui";

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

print "Starting serial forwarders...\n";

$cfg->getMotes(\@motes);
for $mote (@motes) {
  $port = $TESTBED_PORT_BASE + $mote->{id};
  print "Serial forwarder for id $mote->{id} ($mote->{address}) at port $port\n";
  #$cmd .= "java net.tinyos.sf.SerialForwarder -no-gui -comm network\@".$mote->{address}.":10002 -port $port &";
  $cmd .= "java net.tinyos.sf.SerialForwarder $GUI -comm network\@".$mote->{address}.":10002 -port $port &";
}
print $cmd . "\n";
  system($cmd);


