#!/usr/bin/perl -w
#$Id: tb-prog.pl,v 1.2 2004/04/21 00:08:42 cssharp Exp $
#@author Jonathan Hui <jwhui@cs.berkeley.edu>
#@author Cory Sharp <cssharp@eecs.berkeley.edu>
use strict;
use FindBin; # "$FindBin::Bin"

my $platform = "mica2dot";
my @motes = ();
push @motes, { addr => "192.168.1.22", id => "1" };
push @motes, { addr => "192.168.1.23", id => "2" };
push @motes, { addr => "192.168.1.27", id => "3" };

my $setid = "set-mote-id";
my $programmer = "uisp";
my $programmer_part = "-dpart=ATmega128 --wr_fuse_e=ff";
my $programmer_flags = "-dprog=stk500 $programmer_part";
my $builddir = "build/$platform";
my $main_srec = "$builddir/main.srec";
my $mode = "all";
my $verbose = 0;

my %pids;

sub usage {
  print <<'EOF';
tb-erase.pl [options]
[options] are:
  --help           Display this message.
  --erase          Erase motes.
EOF
}

for my $arg (@ARGV) {
  if ($arg eq "-h" or $arg eq "--help") {
    &usage;
    exit(0);
  }
  elsif ($arg =~ /^-v$/ or $arg =~ /^--verbose$/) {
    $verbose = 1;
  }
  elsif ($arg =~ /^--erase$/) {
    $mode = "erase";
  }
}

sub pexec {
  my ($timeout, @commands) = @_;
  my $result = 1;
  foreach my $command (@commands) {
    my $pid;
    unless ($pid = fork) {
      if ($verbose) {
	exec "$command";      
      }
      else {
	exec "$command 2> /dev/null 1> /dev/null";
      }
    }
    $pids{ $pid } = $command;
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm clock restart" };
    alarm $timeout;
    while(keys(%pids) > 0) {
      my $waitpid = wait;
      if ($?) {
	$result = 0;
	print "ERROR: exited with code $?\n\t $pids{$waitpid}\n";
      }
      delete $pids{$waitpid};
    }
    alarm 0;
  };
  if ($@ and $@ =~ /alarm clock restart/) { 
    $result = 0;
    foreach my $pid (keys %pids) {
      print "FAILED: timeout expired\n\t$pids{$pid}\n";
      `kill -9 $pid`;
    }
  }

  return $result;
}

my @commands = ();

if ($mode =~ /erase/ or $mode =~ /all/) {
  # erase motes
  print "Erasing ... \n";
  foreach my $mote (@motes) {
    push @commands, "$programmer $programmer_flags -dhost=$mote->{'addr'} --erase";
  }
  if (pexec(5, @commands) == 0) {
    exit(0);
  }
}

if ($mode =~ /all/) {
  # upload
  print "Uploading ... \n";

  foreach my $mote (@motes) {
    `$setid $main_srec $main_srec.$mote->{'id'} $mote->{'id'}`;
  }
  @commands = ();
  foreach my $mote (@motes) {
    push @commands, "$programmer $programmer_flags -dhost=$mote->{'addr'} --upload if=$main_srec.$mote->{'id'}";
  }
  if (pexec(15, @commands) == 0) {
    exec(0);
  }
}

print "COMPLETE!\n";
