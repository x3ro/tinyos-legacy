#!/usr/bin/perl
#******************************************************************
#  LZ77 uncompress tools                                          *
#  input: Logger data produced by AclLZToLog component,with the   *
#         first filling line trimmed.                             *
#  output: Accel reading                                          *
#  Author: Ning Xu(nxu@usc.edu)                                   *
#          May 19,2003                                            *
#******************************************************************
if (($#ARGV+1) !=2) {
print "Usage: lz <infile> <outfile>\n";
exit;
}
open(IN,"<$ARGV[0]");
open(OUT,">$ARGV[1]");
print "in=$ARGV[0],out=$ARGV[1]\n";
$in_count=0;
$out_count=0;
while ($line=<IN>){
   if ($line=~/^7e/) {
      $line=~/(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+(\w+)\W+/;
      $a[0]=hex $8.$9;
      $a[1]=hex $10.$11;
      $a[2]=hex $12.$13;
      $a[3]=hex $14.$15;
      $a[4]=hex $16.$17;
      $a[5]=hex $18.$19;
      $a[6]=hex $20.$21;
      $a[7]=hex $22.$23;
      $sum=0;
      for ($i=0;$i<8;$i++) {$sum+=$a[$i];}
      if ($sum != 0){
                      for ($i=0;$i<8;$i++) {$lz[$in_count++]=$a[$i];}
      } else {
                while($lz[$in_count-1]==(hex "4444")) {
                      $in_count--;
                }
                $c=0;
                while ($c<$in_count){
                    if ($lz[$c]<(hex "8000")){
                                              $b[$out_count] = $lz[$c];
                                              print OUT "$b[$out_count] ";
                                              $out_count++;
                                              if ($out_count%20 ==0) { print OUT "\n";}
                    } else {
                                              $len=($lz[$c]>>8)-128;
                                              for ($l=0;$l<$len;$l++){
                                                   $f=$out_count-$lz[$c]+($lz[$c]>>8)*256+$l;
                                                   $b[$out_count]=$b[$f]; 
                                                   print OUT "$b[$out_count] ";
                                                   $out_count++;
                                                   if ($out_count%20 ==0) { print OUT "\n";}
                                              }
                    }
                    $c++;
                }
       $in_count=0;
       $out_count=0;
       print OUT "**********************************************************************************\n";
      }
  }
}
close(IN);
close(OUT);
