#!/usr/bin/perl -w
use strict;

if( @ARGV == 0 ) {
  print "usage: ident.pl [ident_id_file]\n";
  exit 0;
}

my ($id_file,$name) = @ARGV;

my $id = 0;
my $time = `date +%s`;
$time =~ s/\s//g;

if( open( FH, "< $id_file" ) ) {
  my $text = join("",<FH>);
  close FH;
  $id = $1 if $text =~ /(\d+)/;   
}

if( $id == 0 ) {
  $id = int( 65535 * rand() ) + 1;
} else {
  $id++;
}
  open( FH, "> $id_file" )
    or die "ERROR, could not write id file $id_file, aborting: $!\n";
  print FH "$id\n";
  close FH;

my @defs = ();
push( @defs, "-DIDENT_PROGRAM_NAME=\"$name\"" ) if defined $name && $name !~ /^\s*$/;
push( @defs, "-DIDENT_INSTALL_ID=${id}u" );
push( @defs, "-DIDENT_UNIX_TIME=${time}L" );

print join(" ",@defs) . "\n";

