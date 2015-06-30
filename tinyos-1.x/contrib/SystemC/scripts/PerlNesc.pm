use strict;
use IO::Capture::Stdout;
use FindInclude;
use SlurpFile;
use Carp;

### ---
### --- PerlNesc
### ---
package PerlNesc;

sub new ($) {
  my $class = shift;
  $class = ref($class) if ref($class);
  my %opt = @_;

  ($opt{name} = $opt{filename}) =~ s{^.*/}{}
    if !defined $opt{name} && defined $opt{filename};

  $opt{filename} = FindInclude::find_file( $opt{name} )
    if !defined $opt{filename} && defined $opt{name};

  $opt{text} = SlurpFile::slurp_file( $opt{filename} )
    if !defined $opt{text} && defined $opt{filename};

  print STDERR "..... $opt{name}\n";

  my $self = bless {
    files => undef,
    tags => undef,
    children => PerlNescFiles->new(),
    parents => PerlNescFiles->new(),

    text => $opt{text},
    name => $opt{name},
    file => $opt{file},
    when => $opt{when} || "",
    modified => 0,
  }, $class;

  my $when = 0;
  if( defined $opt{parent} ) {
    $self->{files} = $opt{parent}{files};
    $self->{tags} = $opt{parent}{tags};
    $self->{parents}->push_file( $opt{parent} );
    $when = $opt{parent}{when};
  } else {
    $self->{files} = new PerlNescFiles();
    $self->{tags} = new PerlNescTags();
  }

  $self->{files}->push_file( $self );
  $self->process( $when );

  return $self;
}

sub include ($$) {
  my ($self,$name) = @_;
  my $file = $self->{files}{$name}
          || PerlNesc->new( parent => $self, name => $name );
  $self->{children}->push_file( $file );
  $file->process( $self->{when} );
}

sub process ($$) {
  my ($self,$when) = @_;

  if( $self->{when} ne $when ) {
    $self->{when} = $when;
    return undef unless defined $self->{text};
    my $parts = $self->process_parts( parse_text($self->{text}) );
    return $self->{text} = merge_text($parts);
  }

  return undef;
}

sub process_parts {
  my ($self,$parts) = @_;
  my $next_string_is_inc = 0;

  #  go through all the parts of the file
  for my $part (@{$parts}) {

    #  if a tag block is handled, handle it, otherwise pass it through
    if( exists $self->{tags}{tags}{$part->{type}} ) {

    print STDERR "type> $part->{type}\n";

      #  extract the tag arguments and its body
      my $tag = $part->{type};
      if( $part->{text} =~ m{^<$tag([^>]*)>(.*)</$tag>$}s ) {

	my ($arg,$block) = ($1,$2);

	#  split the arguments into options of the form name or name=value
        #  ... possibly with quotes involved (anywhere)
	my %opts = map { s/(?<!\\)"//g; m/(.*?)=(.*)/ ? ($1=>$2) : ($_=>1) }
		   ($arg =~ m/("(?:\\.|[^"])*"|[^\s"]+)/g);
	
	# if when for the part is now or we're on the last pass
	if( !defined $opts{when}
	    || $self->{when} eq $opts{when}
	    || $opts{when} eq "all"
	    || ( ($self->{when} eq "last") && $opts{last} )
	  ) {

	  my $cap = new IO::Capture::Stdout;
	  $cap->start;
	  my $rv = undef;
	  eval {
	    $rv = $self->{tags}{tags}{$tag}(
		file=>$self, part=>$part, opts=>\%opts, text=>$block
	      );
	  };
	  $self->{tags}->check_eval_error();
	  $cap->stop;

	  if( $rv ) {
	    my $text = join("",$cap->read);
	    my $bparts = $self->process_parts( parse_text($text) );

	    $part->{type} .= "_OUT";
	    $part->{text} = merge_text( $bparts );

	    $self->{modified} = 1;
	  }

	}
      }
    } else {
      #$part->{type} = "CODE";
    }

    if( $next_string_is_inc ) {
      $next_string_is_inc = 0;
      $self->include($1)
        if $part->{type} eq "STRING" && $part->{text} =~ m/^"(.*)"$/;
    }

    if( $part->{type} eq "CODE" ) {
      while ($part->{text} =~ m/ \bincludes\s+(\S+)\s*;
                               | \#include\s+[<](.*?)[>]
			       | \#include\s+$
			       /gx) {

	my $include_file = undef;
	if( defined $1 ) { $include_file = "$1.h"; }
	elsif( defined $2 ) { $include_file = $2; }
	else { $next_string_is_inc = 1; }

	$self->include($include_file) if defined $include_file;
      }
    } 

  }

  return $parts;
}

sub merge_text ($) {
  my ($parts) = @_;
  return join "", map { $_->{text} } @{$parts};
}

sub parse_text ($) {
  my ($text) = (@_);

  my $re = qr{
     ( // [^\n]* )                # $1 C++ comment
    |( /\* .*? \*/ )              # $2 C comment
    |( " (?: \\. | [^"] )* " )    # $3 quoted string
    |( <(\w+)[^>]*> .*? </\5> )   # $4 special block, $5 special keyword
    |( [^/"<]+ | . )              # $6 everything else
  }xs;

  my $code = undef;
  my @parts = ();
  while( $text =~ m{$re}g ) {
    my ($cpprem,$crem,$str,$block,$keyword,$other) = ($1,$2,$3,$4,$5,$6);

    push( @parts, { type => "COMMENT", text => $cpprem } ) if defined $cpprem;
    push( @parts, { type => "COMMENT", text => $crem } ) if defined $crem;
    push( @parts, { type => "STRING", text => $str } ) if defined $str;
    push( @parts, { type => lc $keyword, text => $block } ) if defined $block;

    if( defined $other ) {
      if( defined $code ) {
	${$code} .= $other;
      } else {
	push( @parts, { type => "CODE", text => $other } );
	$code = \$parts[-1]->{text};
      }
    } else {
      $code = undef;
    }
  }

  linenumber_parts( \@parts );

  return \@parts;
}

sub linenumber_parts {
  my ($parts) = @_;
  return unless @{$parts};
  $parts->[0]->{lines} = ($parts->[0]->{text} =~ tr/\n//);
  $parts->[0]->{linenum} = 1;
  for( my $i=1; $i<@{$parts}; $i++ ) {
    $parts->[$i]->{lines} = ($parts->[$i]->{text} =~ tr/\n//);
    $parts->[$i]->{linenum} = $parts->[$i-1]->{linenum} + $parts->[$i-1]->{lines};
  }
}

sub add_tag {
  my $self = shift;
  $self->{tags}->add_tag( @_ );
}


### ---
### --- PerlNescFiles
### ---
package PerlNescFiles;

my $internal = 0;

sub new ($) {
  my $class = ref($_[0]) || $_[0];
  bless {
    files => {},
  }, $class;
}

sub push_file {
  my ($self,$file) = @_;

  my $name = $file->{name} || "PerlNescFiles_INTERNAL_" . (++$internal);

  if( !exists $self->{files}{$name} ) {
    $self->{files}{$name} = {
      file => $file,
      n => scalar( keys %{$self->{files}} )
    };
    return 1;
  }

  return 0;
}

sub get_files {
  my ($self) = @_;
  return map { $_->{file} } sort { $a->{n} <=> $b->{n} } values %{$self->{files}};
}



### ---
### --- PerlNescTags
### ---
package PerlNescTags;

sub new ($) {
  my $class = ref($_[0]) || $_[0];
  bless {
    tags => { perl => \&perl_tag },
    evals => {},
  }, $class;
}

#  add_tag - associate a tag name with a subroutine handler
sub add_tag {
  my ($self,$tagname,$tagsub) = @_;
  $self->{tags}{lc($tagname)} = $tagsub;
}

#  save_eval - save the text of an eval by eval num into a hash
#  ... doesn't actual eval the given text, use it like this:
#    eval $self->save_eval $text, $extra;
sub save_eval ($$) {
  my ($self,$evaltext,$extra) = @_;
  eval(","); #force an eval error, snag the eval number
  $self->{evals}{$1+1} = { text => $evaltext, extra => $extra }
    if $@ =~ /\(eval (\d+)\)/;
  return $evaltext;
}

#  check_eval_error - test if there was an eval error, if so print out an
#  informative and useful error message.
sub check_eval_error () {
  my ($self) = @_;
  if( $@ ) {

    #  lookup this eval error, if we don't have it cached, die with the
    #  original error text.
    my $eval = $self->{evals}{$1} if $@ =~ /\(eval (\d+)\)/;
    die $@ if not defined $eval;

    #  undo some name mangling to the part type
    (my $type = $eval->{extra}{part}{type}) =~ s/_OUT$//;

    #  add line numbers to the saved eval text
    my $n = 0;
    (my $text = $eval->{text}) =~ s/^/sprintf("%6d  ",++$n)/gem;

    #  mangle the eval text to provide better error context
    (my $err = $@) =~ s/\s+$//;
    my $linenum = undef;
    $err =~ s/PerlNescTags:://g;
    $err =~ s/(\(eval (\d+)\) line (\d+))/
	      $linenum = $3;
              "$1, $self->{evals}{$2}{extra}{file}{name} line "
              . ($self->{evals}{$2}{extra}{part}{linenum} + $3 - 1)
	     /e;

    $text =~ s/^(\s*$linenum) /$1*/m if defined $linenum;

    #  now die with a PerlNescTags-style error message
    die "Error in $type tag "
      . "at $eval->{extra}{file}{name}:$eval->{extra}{part}{linenum}:\n"
      . "$text\n$err\n";
  }
}

#  default code to handle the basic perl tags <perl>...</perl>
sub perl_tag {
  my %arg = @_;
  my ($file,$part,$opts,$text) = @arg{qw(file part opts text)};
  local *include = sub { $file->include( $_[0] ); };
  eval $file->{tags}->save_eval( $text, \%arg );
  die $@ if $@;
  1;
}

1;

