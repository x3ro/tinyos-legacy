#!/usr/bin/perl -w
use strict;

# print usage if we have the wrong number of arguments
if( @ARGV != 1 ) {
  print "usage: ram_schema.pl [exe]\n";
  exit 0;
}

# get the args and default variables set up
my $exein = shift @ARGV;

# build a hash of all data segment symbols to their address and size
my %symbols = ();
open( SYMBOL, "objdump -t $exein |" )
  or die "Cannot extract symbol information: $!\n";
while(<SYMBOL>) {
  if( /^(\S+)\s+.+\s+\.(?:data|bss)\s+(\S+)\s+(\S+)\s*$/ ) {
    my ($addr,$size,$sym) = ($1,$2,$3);
    $addr =~ s/^00800/00000/;
    $symbols{$sym} = { addr => hex($addr), size => hex($size) };
  }
}
close(SYMBOL);

# delete pseudosymbols from the schema
for my $sym (keys %symbols) {
  delete $symbols{$sym} if $symbols{$sym}{size} == 0;
}

# map variables of size 1, 2, and 4 optimistically to uint's
my %types = (
  1 => "MA_TYPE_UINT",
  2 => "MA_TYPE_UINT",
  4 => "MA_TYPE_UINT",
);

# print out all the variable information as a schema
for my $sym (sort keys %symbols) {
  (my $name = $sym) =~ s/\$/./g;
  my ($addr,$size) = ( $symbols{$sym}->{addr}, $symbols{$sym}->{size} );
  my $type = $types{$size} || "MA_TYPE_OCTETSTRING";
  printf( "%-50s %-6d %4d %-20s\n", $name, $addr, $size, $type );
}

