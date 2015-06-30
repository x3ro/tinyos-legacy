#!/usr/bin/perl

$FNAME = $ARGV[0];
if (!$FNAME) { $FNAME = "build/mica/main.exe"; }

$specials{"_output_compare0_"} = "HPLClock";
$specials{"_output_compare2_"} = "ChannelMonC";
$specials{"_adc_"} = "HPLADCC";
$specials{"_uart_recv_"} = "HPLUARTM";
$specials{"_uart_trans_"} = "HPLUARTM";
$specials{"_spi_"} = "SpiByteFifoC";
$specials{"received"} = "AMPromiscuous";
$specials{"main"} = "** TinyOS";

$proc = 0;

$cmd = "avr-nm --size-sort $FNAME |";
open(CMD, $cmd) || die "Can't run $cmd\n";
while (<CMD>) {
  $proc = 0;
  if (/^(\S+) (\S+) ([^\.]+)\.(\S+)/) {
    $cursize = hex($1);
    $curpkg = $3;
    $proc = 1;
  } elsif (/^(\S+) (\S+) (\S+)/) {
    $cursize = hex($1);
    $curpkg = "** Runtime";
    $curfn = $3;

    if ($specials{$curfn}) {
      $curpkg = $specials{$curfn};
    } elsif ($curfn =~ /^TOS/) {
      $curpkg = "** TinyOS";
    }  

#printf "$curpkg: %-30s  %s\tsize %d\n", $curfn, 
#(($2 eq "t" || $2 eq "T")?"text":"data"), $cursize;
    $proc = 1;
  }

  if ($proc) {
    if ($2 eq "t" || $2 eq "T") {
      $textsize{$curpkg} += $cursize;
      $allpkgs{$curpkg} = 1;
    } else {
      $datasize{$curpkg} += $cursize;
      $allpkgs{$curpkg} = 1;
    }
  }
}
close(CMD);

#printf "%30s\t\t%s\t%s\n", "Package", "text", "data";

$total = 0;
foreach $pkg (sort keys %allpkgs) {
#printf "%30s\t\t%d\t%d\n", $pkg, $textsize{$pkg}, $datasize{$pkg};
  printf "%-25s  &          & %8d & %8d \\\\\n", "\\kw{$pkg}", $textsize{$pkg}, $datasize{$pkg};
  $totaltext += $textsize{$pkg};
  $totaldata += $datasize{$pkg};
}

print "\n";
#printf "%30s\t\t%d\t%d\n", "Totals:", $totaltext, $totaldata;
print "Totals:\t\t & & $totaltext & $totaldata \\\\\n";



