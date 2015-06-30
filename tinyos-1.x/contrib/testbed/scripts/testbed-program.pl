#!/usr/bin/perl
use strict;
use TinyOS::Util::TestBedConfig;
use Env;

#This is a wrapper to Alec and Terrence's intel-program.sh,
#which reads a file with the description of the testbed motes
#All the other arguments are passed to inte-program.sh unmodified

my $DEFAULT_PLATFORM = "mica2dot"; #default (may override in configuration)
my $platform = $DEFAULT_PLATFORM;
my @mote_ids;
my @mote_addrs;
my ($file,$mote);
my ($arg,@new_args);
my $RSCPATH = $ENV{'RSCPATH'};
my $cfg;

if (!defined $RSCPATH) {
  die "You didn't define your RSCPATH. Define the path and try me again\n";
}


#parse testbed and platform arguments, pass along others
undef $file;
for $arg (@ARGV) {
  if ($arg =~ /^--testbed=(.+)$/) {
    $file = $1;
  } elsif ($arg =~ /^--platform=(.+)$/) {
    $platform = $1;
  } else {
    push @new_args,$arg;
  }
}

if (!$file) {
  print STDERR "No testbed file specified!\n";
  &usage;
  exit(0);
}

$cfg = TinyOS::Util::TestBedConfig->new($file);

print "Read config file $file with ". $cfg->getNumberOfMotes() . " motes\n";

my @motes;

$cfg->getMotes(\@motes);
for $mote (@motes) {
  push @mote_addrs,$mote->{address};
  push @mote_ids, $mote->{id};
} 


if (!defined(@mote_ids) || !defined(@mote_addrs)) {
  die "Could not read mote info from file $file\n";
}

#set up environment for intel-program
print "platform is set to $platform\n";
$ENV{'RSC_PLATFORM'} = $platform;
$ENV{'RSC_MOTE_IDS'} = join ':',@mote_ids;
$ENV{'RSC_MOTE_ADDRS'} = join ':',@mote_addrs;

my $cmd;
$cmd = "intel-program.sh " . join " ", @new_args;
print "Issuing command $cmd\n";
system($cmd);




sub usage {
  my ($usage);
  $usage = "testbed-program [options]\n";
  $usage .= " where options are\n";
  $usage .= " --testbed=<file>          :testbed description file\n";
  $usage .= " [--platform=<platform>]   :platform. Optional (default=$DEFAULT_PLATFORM)\n";
  $usage .= " and all other options for intel-program.sh\n\n";
  $usage .= `$RSCPATH/intel-program.sh --help`;
  $usage .= "\n";
  print $usage;

}


