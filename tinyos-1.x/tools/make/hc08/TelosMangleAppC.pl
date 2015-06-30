#!/usr/bin/perl -w
#$Id: TelosMangleAppC.pl,v 1.2 2004/01/09 10:17:47 cssharp Exp $
# @author Cory Sharp <cssharp@eecs.berkeley.edu>

use strict;

my $absolute_address = undef;
my $absolute_address_count = 0;

while(<>) {
  
  # If on the first line, print some header.  It's in the while loop so if
  # this script is invoked with -i, the correct things still happen.
  if( $. == 1 ) {
    print <<"EOF";
#define MANGLED_NESC_APP_C
#pragma MESSAGE DISABLE C1106  //disable bitfield warnings
#pragma MESSAGE DISABLE C1420  //stupid ass warning, "Result of function-call is ignored"
#pragma MESSAGE DISABLE C4002  //... and its jackass cousin, "Result not used"
#pragma MESSAGE DISABLE C4301  //they're so proud of themselves, "Inline expansion done for function call"
#include "hcs08gb60_interrupts.h"

EOF
  }

  # disable file and line number preprocessor commands
  s{^(# \d+|#line)}{//$1};

  # replace inline keywords with inline pragmas
  s{^(.*\binline\b.*)}{ (my $t=$1) =~ s/\b(inline)\b/\/*$1*\//; "#pragma INLINE\n$t" }e;

  # replace $ in symbols with __
  s{([\w\$]+)}{ (my $t=$1) =~ s/\$/__/g; $t }ge if /\$/;

  # hide debug enums that are out of range
  s{^(.* 1ULL << (\d+).*)}{ ($2>=15) ? "//$1" : "$1" }e;

  # map gcc interrupts back to hc08 macro interrupts
  s{^void\s*__attribute\(\(interrupt\)\)\s+signal_(\w+)\(void\)}{HC08_SIGNAL($1)};

  # map gcc noinline attribute to hc08 noinline pragma
  s{^(.*)(__attribute\(\(noinline\)\))(.*)}{#pragma NO_INLINE\n$1/*$2*/$3};

  # unmangled names with absolute addresses to HC08 compiler directives
  if( /^struct __hc08_absolute_address__(\S+)/ ) {
    $absolute_address = $1;
    $absolute_address_count = 4;
  }
  if( $absolute_address_count > 0 ) {
    if( $absolute_address_count == 1 ) {
      s/^(volatile) (\w+) (\w+);$/$1 $2 $3 \@$absolute_address;/;
    } else {
      s/^/\/\// unless /^\/\//;
    }
    $absolute_address_count--;
  }

  print;
}

