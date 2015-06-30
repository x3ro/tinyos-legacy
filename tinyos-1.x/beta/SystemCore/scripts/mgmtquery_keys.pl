#!/usr/bin/perl -w
use strict;

my @names = ();
my %sizes = ();
my %types = ();

while(<>) {
    if( m/.*result = (.*)\$MA_(.*)\$getAttr/ ) {
	push( @names, "$1.$2" );
      # print scalar(@names) . ": $names[-1]\n";
    }

    if( m/  (.*)\$MA_(.*)\$.*init\((.*),(.*)\)/ ) {
	my ($id,$size,$type) = ("$1.$2",$3,$4);
      # print "$id: $size\n";
	$size =~ s/sizeof//;
	$size =~ s/\(//;
	$size =~ s/\)//;
	$size =~ s/\s//g;
	$sizes{$id} = $size;
	$type =~ s/\s//g;
	$types{$id} = $type;
    }
}

my %TypeSize = (
		uint8_t => 1,
		uint16_t => 2,
		uint32_t => 4,
		);

my $i = 0;
for my $name (@names) {
    die "Uninitialized attribute: $name (did you call .init(size)?)"
	unless defined $sizes{$name};
    
    my $size = $TypeSize{$sizes{$name}} || $sizes{$name};
    printf("%-50s %-6d %2d %-20s\n", $name, $i, $size, $types{$name});
    
    $i++;
}
