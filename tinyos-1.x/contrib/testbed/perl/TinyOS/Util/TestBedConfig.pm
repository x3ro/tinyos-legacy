package TinyOS::Util::TestBedConfig;

use 5.008;
use strict;
use warnings;
use Carp;

## Module to read a simple configuration file for testbeds, and provinding calls to get information from it
## Author: Rodrigo Fonseca (rfonseca at cs.berkeley.edu)


our $VERSION = '0.02';


# Preloaded methods go here.
# parameter: a file name to read from
sub new {
  my ($class,$filename) = @_;
  if (! defined $filename) {
    print STDERR "TestBedConfig->new called without filename object\n";
    return undef;
  }
  my $self = {
    motes => undef,
    platform => undef
  };
  bless $self,$class;
  
  if (! $self->parse_file($filename) ) {
    croak "TestBedConfig->new : cannot parse file $filename\n";
    return undef;
  }
  return $self;
}

sub getNumberOfMotes {
  return scalar @{$_[0]->{motes}};
}

sub getMote {
  my ($self,$i) = @_;
  if (! defined $i || $i < 0 || $i > scalar @{$self->{motes}}) {
    return undef;
  }
  return ${$self->{motes}}[$i];
}

#Receives an array reference, and makes the referent a copy of the motes array.
sub getMotes {
  my ($self,$aref) = @_;
  if (ref $aref ne "ARRAY") {
    croak "Reference must be to an array.\n";
  }
  @{$aref} = @{$self->{motes}};
}


sub getPlatform {
  return ($_[0]->{platform});
}

#opens filename and reads the mote information into the motes array

sub parse_file {
  my $self = shift;
  my $filename = shift;
  my @line;
  my $line = 0;
  my ($id,$address,$x,$y);

  if (! (open FH, $filename)) {
    croak "Cannot open $filename\n";
    return undef;
  } 

  while (<FH>) {
    $id = 0;
    $address = "0.0.0.0";
    $x = 0.0;
    $y = 0.0;
    $line++;
    chomp;
    if (s/^mote\s+//) {
      @line = split;
      if (scalar @line < 2) {
        croak "Warning: parse error at line $line\n";
        next;
      }
      $id = $line[0];
      $address = $line[1];
      if (scalar @line == 4) {
        $x = $line[2];
        $y = $line[3];
      }
      print "TesbedConfig::parse_file: read mote id $id address $address x $x y $y\n";
      push @{$self->{motes}}, {id => $id, address => $address, x => $x, y => $y};
    } elsif (/^platform\s+(\S+)/) {
      $self->{platform} = $1;
    }
  }
  1;
}

#@motes is an array of hash references
#The hashes represent a ADT for motes, with the following structure
#  ind id
#  string address
#  double x
#  double y

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 Short Description

   use TinyOS::Util::TestBedConfig;
   $cfg = TinyOS::Util::TestBedConfig->new($config_file);
   $n = cfg->getNumberOfMotes();

Iterating over the motes
   
   my @mote_array;
   $cfg->getMotes(\@mote_array);
   for $mote (@mote_array) {
      $address = $mote->{'address'};
      $id      = $mote->{'id'};
      $x       = $mote->{'x'};
      $y       = $mote->{'y'}; 
      #do whatever you want
   }

Other calls:
  
   $moteref = getMote($id);
   getMotes(\@array);
   $n = getNumberOfMotes();
   $platform = getPlatform();
  
The array of motes returned by getMotes() is an array of hash references with the following keys:

=item 'address' is the ip address or host name of the mote
=item 'id' is the mote id (TOS_LOCAL_ADDRESS for the mote)
=item 'x' is the x coordinate of the mote in the testbed
=item 'y' is the y coordinate of the mote in the testbed

=head2 Extending
The file format can be extended in a backwards compatible way if fields are added after the existing ones

=cut

