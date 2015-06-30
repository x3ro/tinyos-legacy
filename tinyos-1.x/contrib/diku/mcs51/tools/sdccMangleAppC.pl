#!/usr/bin/perl -w
#$Id: sdccMangleAppC.pl,v 1.1 2006/04/07 12:49:54 mleopold Exp $
# @author Cory Sharp <cssharp@eecs.berkeley.edu>
# Modified by Mads Bondo Dydensborg <madsdyd@diku.dk>
# Adopted for sdcc and mcs51 by Martin Leopold <leopold@diku.dk>

use strict;
use Getopt::Long;

my $KEIL = '';
my $SDCC = '';
my $file = '';

my $absolute_address = undef;
my $absolute_address_count = 0;
my $multi_match = 0;
my $enum_match = 0;

GetOptions(
	'KEIL' => \$KEIL,
	'SDCC' => \$SDCC,
	'file=s' => \$file,
);

if ( ! $KEIL && ! $SDCC || ! $file) {
	die "no valid arg (KEIL, SDCC or file)\n";
}

open(FILE,"<$file") or die "no such file $file\n";
while(<FILE>) {
  # If on the first line, print some header.  It's in the while loop so if
  # this script is invoked with -i, the correct things still happen.
  # NOTE: This was broken by SMAC!
  if( $. == 1 ) {
    print <<"EOF";

#define MANGLED_NESC_APP_C
EOF
  }

  # Replace sfr related definitions with sdcc dialect
  # typdef will be removed
  # sfr * =  0x80 // P0
  # (sfr*) 0x80 -> (sfr at
  s{^(typedef int sfr;)}{//$1};
# This line is used with sdcc
if ( $SDCC ) {
  s{sfr\s*__attribute\(\((.*)\)\)}{sfr at 0$1};
}
# This line is used with Keil
if ( $KEIL ) {
  s{sfr\s*__attribute\(\((.*)\)\) (.*);}{sfr $2 = 0$1;};
}

  # Replace sbit related definitions with sdcc dialect
  s{^(typedef int sbit;)}{//$1};
# This line is used with sdcc
if ( $SDCC ) {
  s{sbit\s*__attribute\(\((.*)\)\)}{sbit at 0$1};
}
# This line is used with Keil
if ( $KEIL ) {
  s{sbit\s*__attribute\(\((.*)\)\) (.*);}{sbit $2 = 0$1;};

# Keil: Trim
  s{#define dbg\(mode, format, ...\) \(\(void\)0\)}{#define dbg(mode, format) ((void)0)};
  s{#define dbg_clear\(mode, format, ...\) \(\(void\)0\)}{#define dbg_clear(mode, format) ((void)0)};
  
# Keil: Remove 'DBG_'
  $enum_match = 1 if /enum(.*)__nesc_unnamed4247.*/;
  if ( $enum_match && /\}/ ) {
    $enum_match = 0;
    next;
  }
  next if $enum_match;
    
# Keil: Remove 'void __vector_#(void) interrupt #;'
  next if /void(.*)__vector_4(.*);/;
  next if /void(.*)__vector_5(.*);/;
  next if /void(.*)__vector_8(.*);/;
}
    
  # replace keyword data with something else
  # If a storrage class specifier shows up this will be replaced as well
  s{data}{_data};

  # disable file and line number preprocessor commands (sdcc/cw doesn't support it)
  s{^(# \d+|#line)}{//$1};

  # replace inline keywords with inline pragmas
  # sdcc does not support inline neither as keyword nor pragma
  #s{^(.*\binline\b.*)}{ (my $t=$1) =~ s/\b(inline)\b/\/*$1*\//; "#pragma INLINE\n$t" }e;
  s{^(.*\binline\b.*)}{ (my $t=$1) =~ s/\b(inline)\b/\/*$1*\//; "$t" }e;
  #s{^(.*\bstatic\b.*)}{ (my $t=$1) =~ s/\b(static)\b/\/*$1*\//; "$t" }e;

  # MBD: Seems gcc sometimes do a __inline - no idea if it is the same!
  #s{^(.*\b__inline\b.*)}{ (my $t=$1) =~ s/\b(__inline)\b/\/*$1*\//; "#pragma INLINE\n$t" }e;
  s{^(.*\b__inline\b.*)}{ (my $t=$1) =~ s/\b(__inline)\b/\/*$1*\//; "$t" }e;

  # gcc interrupt declatation to sdcc declaration
  # Replaces both prototype and function declaration
  # From: void __attribute((interrupt))   __vector_5(void)
  # To:   void __vector_5(void) interrupt 5
  s{^void\s+__attribute\(\(interrupt\)\)\s+(\w+)(\d+)\(void\)}{void $1$2(void) interrupt $2};
 
  # replace $ in symbols with __ (dollar in identifiers)
  s{([\w\$]+)}{ (my $t=$1) =~ s/\$/__/g; $t }ge if /\$/;

  # map gcc noinline attribute to hcs08 noinline pragma
  s{^(.*)(__attribute\(\(noinline\)\))(.*)}{#pragma NO_INLINE\n$1/*$2*/$3};
  
  # hide debug enums that are out of range
  s{^(.* 1ULL << (\d+).*)}{ ($2>=15) ? "//$1" : "$1" }e;

  ## map gcc interrupts back to hcs08 macro interrupts
  # s{^void\s*__attribute\(\(interrupt\)\)\s+signal_(\w+)\(void\)}{HCS08_SIGNAL($1)};

  
  # Convert datatypes
  # 64 bit integers are not implemented in sdcc so we convert them to 32bit!
  s/^\s*typedef\s*long\s*long\s*__nesc_nw_int64_t;\s*\n//;		# We assume the 32 bit version is already declared
  s/^\s*typedef\s*unsigned\s*long\s*long\s*__nesc_nw_uint64_t;\s*\n//;
  s/^\s*typedef\s*struct\s*nw_int64_t.*nw_int64_t;\s*\n//;
  s/^\s*typedef\s*struct\s*nw_uint64_t.*nw_uint64_t;\s*\n//;
  
  # Remove implementation of __nesc_nw_uint64_t
  $multi_match = 1 if /^.*static.*inline.*__nesc_nw_u{0,1}int64_t/;
  if ( $multi_match && /\}/ ) {
    $multi_match = 0;
    next;
  }
  next if $multi_match;

  
  s/^\s*typedef\s*long\s*long\s*int64_t;\s*\n//;
  s/^\s*typedef\s*unsigned\s*long\s*long\s*uint64_t;\s*\n//;
  
  s/\suint64_t/uint32_t/g;
  s/\sint64_t/int32_t/g;  
  s/long\s*long/long /g;

  # MBD: Fix packet attribute. I do not think there is a CW equiv?
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

# Remove comments
#   //#line 652
#  s{//.*#.*$}{};
#  s{//.*#.*\z}{};
   
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
		print "volatile NV_RAM_Struct_t * NV_RAM_ptr \@0x0000107E;\n";
		print "// #pragma DATA_SEG default\n";

	}
	if ($ENV{"ENVIRONMENT"} eq "SimpleMac") {
		print "/* ********************************************************************** */\n";
		print "/* Definitions needed by SMAC during linking, we place them last to\n";
		print "   make sure that the types are defined. This is hackish, kids! */\n";
		print "\n";
		print "/* Interrupt vector irq_isr at 0xFFFA. SMAC needs this. We hack it in. */\n";
		print "typedef void(*tIsrFunc)(void);\n";
		print "void irq_isr(); // defined in smac library\n";
		print "const tIsrFunc _vect[] \@0xFFFA = {\n";
		print "    irq_isr\n";
		print "};\n";
		print "\n";
		print "#ifndef byte\n";
		print "#define byte uint8_t\n";
		print "#endif\n";
		print "\n";
		print "#ifndef word\n";
		print "#define word uint16_t\n";
		print "#endif\n";
		print "\n";
		print "/*** IRQSC - Interrupt Request Status and Control Register; 0x00000014 ***/\n";
		print "volatile byte _IRQSC \@0x00000014;\n";
		print "\n";
		print "/*** SPI1S - SPI1 Status Register; 0x0000002B ***/\n";
		print "volatile byte _SPI1S \@0x0000002B;\n";
		print "\n";
		print "/*** SPI1D - SPI1 Data Register; 0x0000002D ***/\n";
		print "volatile byte _SPI1D \@0x0000002D;\n";
		print "\n";
		print "/*** PTBD - Port B Data Register; 0x00000004 ***/\n";
		print "volatile byte _PTBD \@0x00000004;\n";
		print "\n";
		print "/*** PTCD - Port C Data Register; 0x00000008 ***/\n";
		print "volatile byte _PTCD \@0x00000008;\n";
		print "\n";
		print "/*** PTED - Port E Data Register; 0x00000010 ***/\n";
		print "volatile byte _PTED \@0x00000010;\n";
		print "\n";
		print "// Stuff from mcu_init and MC13192_init\n";
		print "\n";
		print "/*** SOPT - System Options Register; 0x00001802 ***/\n";
		print "volatile byte _SOPT \@0x00001802;\n";
		print "\n";
		print "/*** TPM1SC - TPM 1 Status and Control Register; 0x00000030 ***/\n";
		print "volatile byte _TPM1SC \@0x00000030;\n";
		print "\n";
		print "// NB: WORD!\n";
		print "/*** TPM1CNT - TPM 1 Counter Register; 0x00000031 ***/\n";
		print "volatile word _TPM1CNT \@0x00000031;\n";
		print "\n";
		print "/*** PTBDD - Data Direction Register B; 0x00000007 ***/\n";
		print "volatile byte _PTBDD \@0x00000007;\n";
		print "\n";
		print "/*** PTCDD - Data Direction Register C; 0x0000000B ***/\n";
		print "volatile byte _PTCDD \@0x0000000B;\n";
		print "\n";
		print "/*** PTCPE - Pullup Enable for Port C; 0x00000009 ***/\n";
		print "volatile byte _PTCPE \@0x00000009;\n";
		print "\n";
		print "/*** PTEDD - Data Direction Register E; 0x00000013 ***/\n";
		print "volatile byte _PTEDD \@0x00000013;\n";
		print "\n";
		print "/*** SPI1C1 - SPI1 Control Register 1; 0x00000028 ***/\n";
		print "volatile byte _SPI1C1 \@0x00000028;\n";
		print "\n";
		print "/*** SPI1C2 - SPI1 Control Register 2; 0x00000029 ***/\n";
		print "volatile byte _SPI1C2 \@0x00000029;\n";
		print "\n";
		print "/*** SPI1BR - SPI1 Baud Rate Register; 0x0000002A ***/\n";
		print "volatile byte _SPI1BR \@0x0000002A;\n";
		print "\n";
		print "// Used by use_external_clock\n";
		print "\n";
		print "/*** ICGC1 - ICG Control Register 1; 0x00000048 ***/\n";
		print "volatile byte _ICGC1 \@0x00000048;\n";
		print "\n";
		print "/*** ICGS1 - ICG Status Register 1; 0x0000004A ***/\n";
		print "volatile byte _ICGS1 \@0x0000004A;\n";
		print "\n";
		print "/*** ICGC2 - ICG Control Register 2; 0x00000049 ***/\n";
		print "volatile byte _ICGC2 \@0x00000049;\n";
		print "\n";
		print "/* End SMAC required but undocumented definitions. */\n";
		print "/* ********************************************************************** */\n";
	}
}

close(FILE);
