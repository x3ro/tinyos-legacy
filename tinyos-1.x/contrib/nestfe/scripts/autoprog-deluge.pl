#!/usr/bin/perl -w
use strict;
# $Id: autoprog-deluge.pl,v 1.1 2005/08/25 19:03:33 gtolle Exp $
# @author Cory Sharp <cssharp@eecs.berkeley.edu>

my %Opt = ( 
  devglob => '/dev/usb/tts/*',
  id => 1,
#  cmd => 'make telosb reinstall,__ID__ bsl,__DEV__',
  cmd => './install-gi.sh',
);

while (@ARGV && $ARGV[0] =~ /^-/) {
  my $opt = shift @ARGV;
  if( $opt eq "-cmd" ) { $Opt{cmd} = shift @ARGV; }
  elsif( $opt eq "-id" ) { $Opt{id} = shift @ARGV; }
  else { die "bad cmdline opt $opt\n"; }
}

my %devthen; # = map { $_ => 1 } motelist_glob(); #glob $Opt{devglob};
my %moteaddr;

my @id;

open(MAP, "wired-testbed.txt");
foreach my $line (<MAP>) {
    my ($addr, $usb) = ($line =~ /mote (.*?) (\w+)/);
    $moteaddr{$usb} = $addr;

    print "$addr -> $usb\n";
}

#while (1) {
  
  my @devnow = motelist_glob(); #glob $Opt{devglob};
  my @devnew = grep { !exists $devthen{$_} } @devnow;

  my $i = 0;
  for my $dev (@devnew) {
      $Opt{id} = $id[$i];
      print "\n$Opt{id} on COM$dev detected\n";
      my $cmd = $Opt{cmd};
      $cmd =~ s/__ID__/$Opt{id}/;
      $cmd =~ s/__DEV__/$dev/;
      $cmd .= " COM$dev 9$dev";
      print "Cmd> $cmd\n";
      system("$cmd &") == 0 or die $@;
      sleep(1);
      $Opt{id}++;
      $i++;
  }

  %devthen = map { $_ => 1 } @devnow;

#  select(undef,undef,undef,0.1);  #sleep 0.1s
#}

sub motelist_glob {
  my @dev = ();
  open my $fh, "motelist -c |" or die "error, could not run motelist, $!\n";
  while( <$fh> ) {
    my @f = split /,/;
    if( @f >= 2 && $f[0] =~ /^UC2/ && $f[1] =~ /^COM(\d+)/) {
	my $comm = $moteaddr{$f[0]};
	push( @dev, $1);
	push( @id, $moteaddr{$f[0]});
    }
  }
  return @dev;
}

