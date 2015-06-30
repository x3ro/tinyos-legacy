#!/usr/bin/perl -w
use strict;

use FindBin;
use lib $FindBin::Bin;
use FindInclude;
use SlurpFile;

my %deps = ();
my $depnum = 1;


my @aa = &FindInclude::parse_include_opts( @ARGV );
@ARGV = ();
while (@aa) {
  my $opt = shift @aa;
  if( $opt =~ /^-/ ) {
    die "ERROR, bad command line option $opt, aborting.\n";
  } else {
    push( @ARGV, $opt );
  }
}

for (@ARGV) {
  my $file = &FindInclude::find_file( $_ );
  $deps{$file} = $depnum++ if defined($file);
}

my %unparsed = %deps;
while( (keys %unparsed) > 0 ) {
  my @files = sort {$unparsed{$a} <=> $unparsed{$b}} keys %unparsed;
  %unparsed = ();
  for my $file (@files) {
    my @ff = parse_file( $file );
    map { $unparsed{$_} = $depnum++ } @ff;
  }
  for my $dep (keys %deps) {
    delete $unparsed{$dep};
  }
  for my $unp (keys %unparsed) {
    $deps{$unp} = $unparsed{$unp};
  }
}

print join("\n",sort {$deps{$a} <=> $deps{$b}} keys %deps) . "\n";



sub parse_file {
  my $file = shift;
  my $text = &SlurpFile::scrub_c_comments( &SlurpFile::slurp_file( $file ) );
  my %files = ();
  for my $interface ($text =~ m/\binterface\s+(\w+)/g) {
    $files{"$interface.nc"} = 1;
  }
  while( $text =~ m/\bcomponents\s+([^;]+)/g ) {
    my $tt = $1;
    for my $component ($tt =~ /(\w+)/g) {
      $files{"$component.nc"} = 1;
    }
  }
  for my $include ($text =~ m/\bincludes\s+(\w+)/g) {
    $files{"$include.h"} = 1;
  }

  for my $include ($text =~ m/\b#include\s+[<"]([^>"]+)[>"]/g) {
    $files{$include} = 1;
  }
  my @full = ();
  for my $ff (keys %files) {
    my $fullff = &FindInclude::find_file( $ff );
    push( @full, $fullff ) if defined $fullff;
  }
  return @full;
}

