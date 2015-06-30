#$Id: FindInclude.pm,v 1.2 2004/07/23 00:03:52 cssharp Exp $

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

# @author Cory Sharp <cssharp@eecs.berkeley.edu>

package FindInclude;
use strict;

my @dirs = ();
my %found = ();


sub parse_include_opts {
  my @args_in = @_;
  my @args_out = ();
  for my $arg (@args_in) {
    if( $arg =~ /-I(.+)/ ) {
      #print "DIR = $1\n";
      push( @dirs, $1 );
    } else {
      push( @args_out, $arg );
    }
  }
  for (@dirs) { $_ .= "/" unless /\/$/; }
  #print "OUT DIRS = " . join(" ",@dirs) . "\n";
  return @args_out;
}


sub find_file {
  my $file = shift;
  #DISABLE CACHING ... return $found{$file} if defined $found{$file};
  #print "IN  DIRS = " . join(" ",@dirs) . "\n";
  for my $dir (@dirs ? @dirs : "") {
    my $full = "$dir$file";
    #print "FULL = $full\n";
    return $found{$file}=$full if -f $full;
  }
  return undef;
}


1;

