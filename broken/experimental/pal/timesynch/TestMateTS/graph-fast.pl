#!/usr/bin/perl

%samples;

while(<>) {
  @datum = split(/\s+/);
  print int($datum[0]/1000)/3600," ",abs($datum[8]),"\n";
}
