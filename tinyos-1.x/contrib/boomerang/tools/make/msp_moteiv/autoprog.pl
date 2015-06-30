#!/usr/bin/perl -w
use strict;
# $Id: autoprog.pl,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $
# @author Cory Sharp <cssharp@eecs.berkeley.edu>

my %Opt = ( 
  id => 1,
  cmd => 'make t reinstall,__ID__ bsl,__DEV__',
  #(map { /(.*?)(?:=(.*))/; $1 => (defined $2 ? $2 : 1) } split /\s+/, $ENV{AUTOPROG}),
  all => 1,
  dosleep => 1,
);

while (@ARGV && $ARGV[0] =~ /^-/) {
  my $opt = shift @ARGV;
  if( $opt eq "-cmd" ) { $Opt{cmd} = shift @ARGV; }
  elsif( $opt eq "-id" ) { $Opt{id} = shift @ARGV; }
  else { die "bad cmdline opt $opt\n"; }
}



if( $Opt{id} =~ /,/ ) {
  for my $devid (split /,/, $Opt{id}) {
    if( $devid =~ /(.*):(.*)/ ) {
      print "\nProgram DEVICE $1 with ID $2\n";
      upload( cmd=>$Opt{cmd}, dev=>$1, id=>$2 );
    }
  }
}
else {
  my %devthen = $Opt{all} ? () : map { $_ => 1 } motelist_glob();

  while (1) {
    my @devnow = motelist_glob();
    my @devnew = grep { !exists $devthen{$_} } @devnow;
    for my $dev (@devnew) {
      print "\nDetected $dev\n";
      upload( cmd=>$Opt{cmd}, id=>$Opt{id}, dev=>$dev );
      $Opt{id}++;
    }
    %devthen = map { $_ => 1 } @devnow;
    select(undef,undef,undef,0.1);  #sleep 0.1s
  }
}



sub upload {
  my %o = @_;
  my $cmd = $o{cmd};
  $cmd =~ s/__ID__/$o{id}/;
  $cmd =~ s/__DEV__/$o{dev}/;
  if( $Opt{dosleep} ) { sleep(1); } else { $Opt{dosleep}=0; }
  print "Cmd> $cmd\n";
  system("$cmd &") == 0 or die $@;
}

sub motelist_glob {
  my @dev = ();
  open my $fh, "motelist -c |" or die "error, could not run motelist, $!\n";
  while( <$fh> ) {
    my @f = split /,/;
    if( @f >= 2 && $f[1] =~ /^COM(\d+)|(^\/dev.*)/ ) {
      push( @dev, $1-1 ) if defined $1;
      push( @dev, $2 ) if defined $2;
    }
  }
  return @dev;
}



