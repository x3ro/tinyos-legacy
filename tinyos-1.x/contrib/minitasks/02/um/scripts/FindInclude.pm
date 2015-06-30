
package FindInclude;
use strict;

my @dirs = ();


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
  #print "IN  DIRS = " . join(" ",@dirs) . "\n";
  for my $dir (@dirs ? @dirs : "") {
    my $full = "$dir$file";
    #print "FULL = $full\n";
    return $full if -f $full;
  }
  return undef;
}


1;

