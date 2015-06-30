#!/usr/bin/perl -w

# "Copyright (c) 2000-2002 The Regents of the University of California.  
# All rights reserved.
# 
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice, the following
# two paragraphs and the author appear in all copies of this software.
# 
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
# OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
# CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."

# Authors: Cory Sharp
# $Id: create_routing.pl,v 1.1 2003/10/09 01:14:18 cssharp Exp $

use strict;

use FindBin;
use lib $FindBin::Bin;
use FindInclude;
use SlurpFile;


(my $self_path = $0) =~ s/[^\/]+$//;


# Parse the command line
#   -Ipath     add path to search for modules

my $G_dir = "build";
mkdir $G_dir unless -d $G_dir;

my %opts = (
    output_routing => "",
    output_extensions => "$G_dir/RoutingMsgExt.h",
    output_neighbor => 1,
    do_ncc_preprocessing => 0,
    input_filename => "<stdin>",
  );

my @aa = &FindInclude::parse_include_opts( @ARGV );
@ARGV = ();
while (@aa) {
  my $opt = shift @aa;
  if( $opt =~ /^-/ ) {
    if( $opt eq "-ncc" ) {
      $opts{do_ncc_preprocessing} = 1;
    } else {
      die "ERROR, bad command line option $opt, aborting.\n";
    }
  } else {
    push( @ARGV, $opt );
  }
}


# Prepare global variables for routing stack information

my %stacks = ();
my %components = map { $_ => 1 } qw(
    BindRoutingMethodM
    DispatchRoutingSendM
    DispatchRoutingReceiveM
    TinyOSRoutingM
    GenericComm
  );
my %provides = map { $_ => 1 } (
    "interface RoutingReceive"
  );


# scan the cache file
my @files = ();
my $cache = "build/nesc_deps.txt";

# Slurp the input and extract routing specification into lines

die "ERROR, expected at most one input file on the command-line\n" if @ARGV > 1;

if( (@ARGV == 1) && ($ARGV[0] !~ /[\\\/]/) ) {
  my $file = &FindInclude::find_file( $ARGV[0] );
  die "ERROR, could not find routing configuration file $ARGV[0], aborting.\n" unless defined $file;
  $opts{input_filename} = $ARGV[0] = $file;
}

my $input = join("",<>);
my $routing = "";
$input =~ s{/\*<routing>(.*?)</routing>\*/\s*}{$routing.=" $1 ";""}ges;
$routing =~ s{//.*?\n}{}g;
$routing =~ s/\s+/ /g;
my @lines = ($routing =~ m/(\S.*?[:;])/g);

# scrub comments from the input
$input = &SlurpFile::scrub_c_comments( $input );
(my $ctext = join( ",", ($input =~ /\bcomponents(.*?);/sg) )) =~ s/\s+/ /;
my %givenComponents = map { if( /(.*)\s+as\s+(.*)/ ) { $1 => $2 } else { $_ => $_ } } split( /\s*,\s*/, $ctext );
my %reverseGivenComponents = reverse %givenComponents;
if( exists $reverseGivenComponents{GenericComm} ) {
  delete $components{GenericComm};
}


# Grab the default output filename if its unspecified
if( !$opts{output_routing} && $input =~ /\bconfiguration\s+(\w+)/ ) {
  $opts{output_routing} = "$G_dir/$1.nc";
}


# Parse the lines of routing information into the global variables

my @errors = ();
my $label = "";
for (@lines) {

  if( /^\s*$/ ) {

    # Skip blank lines
    next;

  } elsif( /^(\w+)\s*:$/ ) {

    # A label starts a new routing decoration stack, probably either
    # "Top" or "Bottom", although this is not enforced here.
    $label = $1;
    $stacks{$label} = { components => [] };

  } elsif( /^TOSAM\s+(\d+)\s*:$/ ) {

    # TOSAM specificies a middle routing stack that is associated with a
    # routing module proper.
    $label = $1;
    $stacks{$label} = { components=>[], am=>$1, interface=>"", provides=>"", as=>"" };

  } elsif( /^(.*);$/ ) {

    (my $expr = $1) =~ s/\s+$//;

    if( $expr =~ /^(provides\s+(.*))$/ ) {

      if( exists($stacks{$label}->{am}) ) {

	my $pp = $2 || "";
	$stacks{$label}->{provides} = $pp;
	$provides{$pp} = 1 if $pp;
	$pp =~ m/interface\s+(\w+)(?:\s+as\s+(\w+))?/;
	$stacks{$label}->{interface} = $1||"";
	$stacks{$label}->{as} = $2||$1||"";

      } else {
	push( @errors, "In \"$expr\", \"provides\" is only valid in TOSAM specifications" );
      }

    } elsif( $expr =~ /^(\w+)$/ ) {

      # A single word ending in a semicolon specifies a module for a given stack.
      push( @{$stacks{$label}->{components}}, $1 );
      $components{$1} = 1;

    } else {
      push( @errors, "Syntax error in \"$expr\"" );
    }

  } else {

    # If here, error.
    push( @errors, "Syntax error in \"$_\"" );

  }

}


# Abort on errors, if any

if( @errors ) {
  die join( "\n", @errors ) . "\n"
    . @errors . " error" . (@errors>1?"s":"")
    . " in routing specification, aborting.\n"
}


# Given the global parsing, prepare blocks of text for the nestarch routing.

# Hash all text blocks
my %text = ();

# StdControl wiring block
my @stdcontrol = ( "GenericComm" );
my $num_found_stdcontrol = 0;
for my $cc (keys %components) {
  if( does_module_provide_StdControl( $cc ) ) {
    push( @stdcontrol, $cc ) if does_module_provide_StdControl( $cc );
    $num_found_stdcontrol++;
  }
}
$text{stdcontrol} = join( "", map { "  StdControl = $_;\n" } sort @stdcontrol );
if( $num_found_stdcontrol == 0 ) {
  die "ERROR, no routing modules found that provide StdControl.  This probably\n"
    . "means your include paths (use -I) aren't correct.  Aborting.\n";
}

# Dispatch (distribute receive protocol) and Bind Dispatch (save send method)
# wiring blocks
$text{dispatch} = "";
$text{bind_dispatch} = "";
for my $label (sort grep { exists($stacks{$_}->{am}) } keys %stacks) {
  my $ll = $stacks{$label};
  next unless $ll->{interface} =~ /^Routing(SendBy\w+)$/;
  my $dd = "Dispatch${1}M";
  $components{$dd} = 1;
  $text{dispatch} .= "  $ll->{as} = $dd;\n";
  $text{bind_dispatch} .= "  $dd -> BindRoutingMethodM.RoutingSend[$ll->{am}];\n";
}

# Provides block
my $rp = "[ RoutingProtocol_t protocol ]";
$text{provides} = join( "", map { "  provides $_$rp;\n" } sort keys %provides );

# Components list
$text{components} = "  components "
                  . join( "\n           , ", sort keys %components )
                  . "\n           ;\n";

# Top routing decorations beween BindRoutingMethodM and DispatchRoutingSendM
$text{top} = wire_many_send_receive(
               "BindRoutingMethodM",
	       $stacks{Top} ? @{$stacks{Top}->{components}} : (),
	       "DispatchRoutingSendM"
	     );

# Wiring for each routing method, possibly with local decorations above and 
# below.
my @amlist = sort { $a <=> $b } grep { /^\d+$/ } keys %stacks;
my @routing_methods = ();
for my $am (@amlist) {
  push( @routing_methods, wire_routing_method( $am, @{$stacks{$am}->{components}} ) );
}
$text{routing_methods} = join( "\n", @routing_methods );

# Bottom routing decorations between DispatchRoutingReeiveM and TinyOSRoutingM
$text{bottom} = wire_many_send_receive(
                  "DispatchRoutingReceiveM",
	          $stacks{Bottom} ? @{$stacks{Bottom}->{components}} : (),
	          "TinyOSRoutingM"
	        );


# Splice the blocks of text into the given skeleton nesc code

my $warning =<< "EOF";
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***
// ***                                                                     ***
// *** This file was automatically generated by create_routing.pl.         ***
// *** Any and all changes made to this file WILL BE LOST!                 ***
// ***                                                                     ***
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***
EOF

my $provides =<< "EOF";
$text{provides}
  provides interface StdControl;
EOF

my $implementation =<< "EOF";
$text{components}
$text{stdcontrol}
$text{dispatch}
  RoutingReceive = BindRoutingMethodM;
$text{bind_dispatch}
$text{top}
$text{routing_methods}
$text{bottom}
  TinyOSRoutingM -> GenericComm.SendMsg;
EOF

for my $am (sort map {$_->{am}+0} grep {defined $_->{am}} values %stacks) {
  $implementation .= "  TinyOSRoutingM -> GenericComm.ReceiveMsg[$am];\n";
}

my $output = "$warning\n$input";
$output =~ s/(configuration\s+(\w+)\s*\{)/$1\n$provides/;
$output =~ s/(implementation\s+\{(?:\s*components[^;]+;\n?)*)/$1\n$implementation/;


# Print the output

if( $opts{output_routing} eq "-" ) {
  print $output;
} else {
  print STDERR "    creating $opts{output_routing} from $opts{input_filename}\n";
  open FH, "> $opts{output_routing}" or die "$opts{output_routing}, $!, aborting\n";
  print FH $output;
  close FH;
}

# Done

exit;


###
### Wiring helper functions
###

sub wire_send_receive {
  my ( $a, $b, $c, $d, $e, $f ) = (@_,"","","","");
  #return "  $a$c -> $b.RoutingSend$d;\n  $a$e -> $b.RoutingReceive$f;\n";
  return "  $a$c -> $b.Routing$d;\n";
}

sub wire_many_send_receive {
  my $text = "";
  my $left = shift;
  while (@_) {
    my $right = shift;
    $text .= wire_send_receive( $left, $right );
    $left = $right;
  }
  return $text;
}

sub wire_routing_method {
  my $am = shift;
  my $text = "";
  my $left = "DispatchRoutingSendM";
  my $right = shift;
  my $br = ".BottomRouting";
  #$text .= wire_send_receive( $left, $right, "${br}Send[$am]", "", "${br}Receive[$am]", "" );
  $text .= wire_send_receive( $left, $right, "${br}\[$am\]", "" );
  while( @_ ) {
    $left = $right;
    $right = shift;
    $text .= wire_send_receive( $left, $right );
  }
  $left = $right;
  $right = "DispatchRoutingReceiveM";
  #$text .= wire_send_receive( $left, $right, "", "[$am]", "", "[$am]" );
  $text .= wire_send_receive( $left, $right, "", "[$am]", );
}


###
### File access helper functions
###

sub does_module_provide_StdControl {
  my $file = &FindInclude::find_file( "$_[0].nc" );
  my $text = &SlurpFile::scrub_c_comments( &SlurpFile::slurp_file( $file ) );
  return 1 if $text =~ /\bprovides\s+interface\s+StdControl;/;
  return 1 if $text =~ /\bprovides\s*\{[^\}]*\binterface\s+StdControl;/;
  return 0;
}

