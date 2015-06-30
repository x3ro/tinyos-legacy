#!/usr/bin/perl -w
#$Id: make_hcs08regs.pl,v 1.1 2005/01/31 21:04:31 freefrag Exp $

# "Copyright (c) 2000-2003 The Regents of the University of California.  
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement
# is hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
# OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."

#@author Cory Sharp <cssharp@eecs.berkeley.edu>

### make_hcs08regs.pl:
###   Take hcs08regs.txt from the command line and produce hcs08regs.h


use strict;

print <<'EOF';
//$Id: make_hcs08regs.pl,v 1.1 2005/01/31 21:04:31 freefrag Exp $
//@author Cory Sharp <cssharp@eecs.berkeley.edu>

// This file was automatically generated with the command:
//  ./make_hcs08regs.pl hcs08regs.txt > hcs08regs.h

// Script modified for 13192EVB by Mads Bondo Dydensborg, madsdyd@diku.dk

#ifndef _H_hcs08regs_h
#define _H_hcs08regs_h


#define HC08_REGISTER(type,addr) (*((type*)(addr)))

EOF

while(<>) {

  if( /^\$/ ) {

    s/\s+$//;
    s/Bit//g;
    s/\*//g;

    my @s = split /\s+/;

    (my $addr = shift @s) =~ s/^\$(00)?//;
    my $name = shift @s;

    my $field = "";
    my $defs = "";
    my $nbit = 7;
    my $prefix = "  ";
    my $worddef = "";
    for my $bit (@s) {

      my ($bitname,$bitwidth,$dodef) = ($bit,1,1);
      if( $bit =~ /^[-0]$/ ) { $bitname = "bit$nbit"; $dodef=0; }
      elsif( $bit =~ /^\d+$/ ) { $bitname = "bit$bit"; $dodef=0; }
      elsif( $bit =~ /^(.*):(\d+)$/ ) { ($bitname,$bitwidth) = ($1,$2); }

      if( $dodef ) {
	$defs .= "#define ${name}_$bitname ${name}_Bits.$bitname\n";
      }
      
      # MBD: Changed the order of bit fields - borken in CW...
      $field = "${prefix}uint8_t $bitname : $bitwidth;\n".$field;
      $nbit -= $bitwidth;

    }

    print STDERR "WARNING! Register $name at address 0x$addr has "
        . ($nbit+1) . " undefined bits.\n"
      if $nbit != -1;

    # use enums to make app.c more readable
    #print "#define ${name}_Addr 0x$addr\n\n";
    print "enum { ${name}_Addr = 0x$addr };\n\n";

    if( $name =~ /^(.*)H$/ ) {
      $worddef = "#define $1 HC08_REGISTER(uint16_t,${name}_Addr)\n";
    }

    print <<"EOF";
typedef struct
{
$field} ${name}_t;

${worddef}#define ${name} HC08_REGISTER(uint8_t,${name}_Addr)

#define ${name}_Bits HC08_REGISTER(${name}_t,${name}_Addr)

$defs

EOF

  }

}

print <<'EOF';
#endif//_H_hcs08regs_h

EOF

