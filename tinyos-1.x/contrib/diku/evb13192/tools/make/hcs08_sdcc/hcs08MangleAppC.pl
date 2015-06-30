#!/usr/bin/perl -w
#$Id: hcs08MangleAppC.pl,v 1.3 2005/07/18 11:39:58 janflora Exp $
# @author Cory Sharp <cssharp@eecs.berkeley.edu>
# Modified by Mads Bondo Dydensborg <madsdyd@diku.dk>

use strict;

my $absolute_address = undef;
my $absolute_address_count = 0;

while(<>) {
  
  # If on the first line, print some header.  It's in the while loop so if
  # this script is invoked with -i, the correct things still happen.
  # NOTE: This was broken by SMAC!
  if( $. == 1 ) {
    print <<"EOF";

#define MANGLED_NESC_APP_C
#include "hcs08gt60_interrupts.h"
EOF
  }

  # disable file and line number preprocessor commands
  s{^(# \d+|#line)}{//$1};

  # replace inline keywords with inline pragmas
  s{^(.*\binline\b.*)}{ (my $t=$1) =~ s/\b(inline)\b/\/*$1*\//; "/*#pragma INLINE*/\n$t" }e;

  # MBD: Seems gcc sometimes do a __inline - no idea if it is the same!
  s{^(.*\b__inline\b.*)}{ (my $t=$1) =~ s/\b(__inline)\b/\/*$1*\//; "/*#pragma INLINE*/\n$t" }e;

  # replace $ in symbols with __
  s{([\w\$]+)}{ (my $t=$1) =~ s/\$/__/g; $t }ge if /\$/;

  # hide debug enums that are out of range
  s{^(.* 1ULL << (\d+).*)}{ ($2>=15) ? "//$1" : "$1" }e;

  # map gcc interrupts back to hcs08 macro interrupts
  # Wrap all interrupt routines to ensure that registers are properly saved and restored
  s{^void\s*__attribute\(\(interrupt\)\)\s+signal_(\w+)\(void\)$}{SDCC_INTERRUPT_WRAPPER($1)\nHCS08_SIGNAL($1)};
  # Also fix forward declarations
  s{^void\s*__attribute\(\(interrupt\)\)\s+signal_(\w+)\(void\);}{HCS08_SIGNAL($1);};

  # Fix variable naming.
  s{(\W)(data\W)}{$1_$2}g; 

  # fix asm syntax
  s{^\s*__asm\s*\(\"(.+)\"\)\;}{_asm\n$1\n_endasm\;};
  
  # fix wierd TOS_Msg error.
  s{^(\s*)struct TOS_Msg(.*)}{$1TOS_Msg$2};
  
  # Fix offsetof.
  s{^(.*)\(struct\s*(.+)\s*\*\)0(.*)}{$1\($2 \*\)0$3};
  
  # map gcc noinline attribute to hcs08 noinline pragma
  s{^(.*)(__attribute\(\(noinline\)\))(.*)}{#pragma NO_INLINE\n$1/*$2*/$3};

  # MBD: Fix packet attribute. I do not think there is a CW equiv?
  s{^(.*)(__attribute\(\(packed\)\))(.*)}{$1/*$2*/$3};
  s{^(.*)(__attribute__\(\(packed\)\))(.*)}{$1/*$2*/$3};

  # MBD: Fix empty struct in OscopeMsg.h - this sucks bigtime.
  s/struct\s+OscopeResetMsg\s*\{/struct OscopeResetMsg{ int foo\;/;

  # unmangled names with absolute addresses to HCS08 compiler directives
  if( /^struct __hcs08_absolute_address__(\S+)/ ) {
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
if (defined $ENV{"ENVIRONMENT"}) {
	if ("FFD" eq $ENV{"ENVIRONMENT"} ||
	    "FFDNB" eq $ENV{"ENVIRONMENT"} ||
	    "FFDNBNS" eq $ENV{"ENVIRONMENT"} ||
	    "FFDNGTS" eq $ENV{"ENVIRONMENT"} ||
	    "RFD" eq $ENV{"ENVIRONMENT"} ||
	    "RFDNB" eq $ENV{"ENVIRONMENT"} ||
	    "RFDNBNS" eq $ENV{"ENVIRONMENT"}) {

		print "// #pragma DATA_SEG NV_RAM_POINTER\n";
		print "// NB: You are _NOT_ to move this somewhere else.\n";
		print "// The freescale 802.15.4 libraries expect it to be there\n";
		#print "volatile NV_RAM_Struct_t * NV_RAM_ptr \@0x0000107E;\n";
		print "xdata at 0x107E volatile NV_RAM_Struct_t *NV_RAM_ptr;\n";
		print "// #pragma DATA_SEG default\n";

	}
#	if ($ENV{"ENVIRONMENT"} eq "SimpleMac") {
#		print "/* ********************************************************************** */\n";
#		print "/* Definitions needed by SMAC during linking, we place them last to\n";
#		print "   make sure that the types are defined. This is hackish, kids! */\n";
#		print "\n";
#		print "#ifndef byte\n";
#		print "#define byte uint8_t\n";
#		print "#endif\n";
#		print "\n";
#		print "#ifndef word\n";
#		print "#define word uint16_t\n";
#		print "#endif\n";
#		print "\n";
#		print "/*** IRQSC - Interrupt Request Status and Control Register; 0x00000014 ***/\n";
#		print "data at 0x0014 volatile byte _IRQSC;\n";
#		print "\n";
#		print "/*** SPI1S - SPI1 Status Register; 0x0000002B ***/\n";
#		print "data at 0x002B volatile byte _SPI1S;\n";
#		print "\n";
#		print "/*** SPI1D - SPI1 Data Register; 0x0000002D ***/\n";
#		print "data at 0x002D volatile byte _SPI1D;\n";
#		print "\n";
#		print "/*** PTBD - Port B Data Register; 0x00000004 ***/\n";
#		print "data at 0x0004 volatile byte _PTBD;\n";
#		print "\n";
#		print "/*** PTCD - Port C Data Register; 0x00000008 ***/\n";
#		print "data at 0x0008 volatile byte _PTCD;\n";
#		print "\n";
#		print "/*** PTED - Port E Data Register; 0x00000010 ***/\n";
#		print "data at 0x0010 volatile byte _PTED;\n";
#		print "\n";
#		print "// Stuff from mcu_init and MC13192_init\n";
#		print "\n";
#		print "/*** SOPT - System Options Register; 0x00001802 ***/\n";
#		print "data at 0x1802 volatile byte _SOPT;\n";
#		print "\n";
#		print "/*** TPM1SC - TPM 1 Status and Control Register; 0x00000030 ***/\n";
#		print "data at 0x0030 volatile byte _TPM1SC;\n";
#		print "\n";
#		print "// NB: WORD!\n";
#		print "/*** TPM1CNT - TPM 1 Counter Register; 0x00000031 ***/\n";
#		print "data at 0x0031 volatile word _TPM1CNT;\n";
#		print "\n";
#		print "/*** PTBDD - Data Direction Register B; 0x00000007 ***/\n";
#		print "data at 0x0007 volatile byte _PTBDD;\n";
#		print "\n";
#		print "/*** PTCDD - Data Direction Register C; 0x0000000B ***/\n";
#		print "data at 0x000B volatile byte _PTCDD;\n";
#		print "\n";
#		print "/*** PTCPE - Pullup Enable for Port C; 0x00000009 ***/\n";
#		print "data at 0x0009 volatile byte _PTCPE;\n";
#		print "\n";
#		print "/*** PTEDD - Data Direction Register E; 0x00000013 ***/\n";
#		print "data at 0x0013 volatile byte _PTEDD;\n";
#		print "\n";
#		print "/*** SPI1C1 - SPI1 Control Register 1; 0x00000028 ***/\n";
#		print "data at 0x0028 volatile byte _SPI1C1;\n";
#		print "\n";
#		print "/*** SPI1C2 - SPI1 Control Register 2; 0x00000029 ***/\n";
#		print "data at 0x0029 volatile byte _SPI1C2;\n";
#		print "\n";
#		print "/*** SPI1BR - SPI1 Baud Rate Register; 0x0000002A ***/\n";
#		print "data at 0x002A volatile byte _SPI1BR;\n";
#		print "\n";
#		print "// Used by use_external_clock\n";
#		print "\n";
#		print "/*** ICGC1 - ICG Control Register 1; 0x00000048 ***/\n";
#		print "data at 0x0048 volatile byte _ICGC1;\n";
#		print "\n";
#		print "/*** ICGS1 - ICG Status Register 1; 0x0000004A ***/\n";
#		print "data at 0x004A volatile byte _ICGS1;\n";
#		print "\n";
#		print "/*** ICGC2 - ICG Control Register 2; 0x00000049 ***/\n";
#		print "data at 0x0049 volatile byte _ICGC2;\n";
#		print "\n";
#		print "/* End SMAC required but undocumented definitions. */\n";
#		print "/* ********************************************************************** */\n";
#	}
}
