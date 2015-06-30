#!/usr/bin/perl -w
use strict;

my $filter_group = 0;

while(<>) {
  $_ = lc;
  s/^data://;
  s/,/ /g;
  #print "LINE = $_";
  next unless /^7e /i;
  my @a = split /\s+/;
  next if $filter_group && $a[3] ne "74";
  my $msglen = hex $a[4];
  my $text = "";
  $text .= join(" ",@a[0..4]) . " : " . join(" ",@a[5..(4+$msglen)]);
  my $protocol = $a[4+$msglen];
  if( $protocol eq "01" ) {
    my $x = signed( hex "$a[6]$a[5]" ) / 256;
    my $y = signed( hex "$a[8]$a[7]" ) / 256;
    $text = sprintf( "%-76s %4.2f:x %4.2f:y", $text, $x, $y );
  }
  if( $protocol eq "c9" ) {
    my $x = hex2float( @a[5..8] );
    my $y = hex2float( @a[9..12] );
    my $z = hex2float( @a[13..16] );
    $text = sprintf( "%-76s %4.2f:x %4.2f:y %4.2f:z", $text, $x, $y, $z );
  }
  print "$text\n";
}

sub signed {
  my $v = shift;
  my $n = 2**(4*length($v)-1);
  $v -= 2*$n if $v >= $n;
  return $v;
}

sub hex2float {
  my @b = @_;
  for (@b) { $_ = hex; }
  return unpack( "f", pack( "C4", @b ) );
}

