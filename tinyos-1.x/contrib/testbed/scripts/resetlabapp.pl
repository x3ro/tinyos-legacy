#!/usr/bin/perl

use TinyOS::Util::TestBedConfig;

$config_file = $ENV{'TOS_TESTBED_CONFIG'};
$TESTBED_PORT_BASE = 9100;

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

$cfg->getMotes(\@motes);
for $mote (@motes) {
  $m = $mote->{address};
  `uisp -dprog=stk500 -dhost=$m -dpart=ATmega128 --wr_fuse_e=ff &`;
} 
