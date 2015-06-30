#!/usr/bin/perl

%samples;
$file = $ARGV[0];
open(DATA_FILE, "$file") or die "file $file not found";
$startMoteTime = 0;
$modulus = (65536 * 65536);
$lastTime = 0;
$count = 0;

while(<DATA_FILE>) {

  @datum = split(/\s+/);
  $realTime = $datum[7];
  if ($realTime < $lastTime) {
    $count++;
  }
  $lastTime = $realTime;
  $realTime += $modulus * $count;
  $datum[7] = $realTime;
  $moteTime = int(1000 * $datum[7] / 32768);
  $datum[1] = $moteTime;
  if ($startMoteTime == 0) {
    $startMoteTime = $datum[1];
  }

  $datum[8] = $datum[0] - $datum[1] + $startMoteTime;
  
  for ($i = 0; $i < 9; $i++) {
    print $datum[$i]," "
  }
  print "\n"; 
}
