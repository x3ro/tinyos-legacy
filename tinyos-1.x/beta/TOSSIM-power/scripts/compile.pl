#!/usr/bin/perl -w

# Script to compile an TinyOS app with CPU profiling support.  
# Must be run from the base directory of the project (where the main 
# makefile is)
# The 'make pc' and 'make mica2' commands should behave the same as with 
# the TinyOS sample apps: create app.c and main.exe in the build/{platform} 
# directories.

# cilly must be in your path.

use Cwd;

if($ARGV[0] eq "--nomake") {
    $make = 0;
} else {
    $make = 1;
}

$ROOT = $ENV{"TOSDIR"}."/..";

$SCRIPTDIR="$ROOT/tools/scripts/PowerTOSSIM";
$BASEDIR = getcwd();
$CYCLECOUNTS = "$SCRIPTDIR/cycle_counts.txt";
$CILLY = "$SCRIPTDIR/cilly.asm.exe";


# system() returns 0 on success, hence the &&s

if($make) {
    system("make pc") && die "Can't compile base app for pc!\n";

    system("make mica2") && die "Can't compile base app for mica2!\n";
}

system("cd build/pc && $CILLY --doCounter --out app.cil.c app.c > bb_line_tmp") && die "cilly error\n"; 

# print "cwd = ", getcwd(), "\n";

system("$SCRIPTDIR/fixnames.pl build/pc/bb_line_tmp > build/pc/bb_linenum_map") && die "fixnames.pl error\n";

chdir("build/pc") || die "Can't chdir: $!\n";

system("$SCRIPTDIR/mypp.pl app.cil.c") && die "mypp.pl error\n";

print "****************************\n";
print "$SCRIPTDIR/bb2asm.pl $BASEDIR  $CYCLECOUNTS bb_linenum_map ../mica2/main.exe bb_cycle_map\n";
print "****************************\n";

system("$SCRIPTDIR/bb2asm.pl $BASEDIR  $CYCLECOUNTS bb_linenum_map ../mica2/main.exe bb_cycle_map") && die "bb2asm.pl error\n";
 
system("gcc -O3 -o a.out app.cil.mypp.c -lpthread");

# Clean up
system("rm bb_line_tmp") && die "rm failed\n";

