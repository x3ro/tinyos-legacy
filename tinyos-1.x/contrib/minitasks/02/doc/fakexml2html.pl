#!/usr/bin/perl -w
use strict;
# $Id: fakexml2html.pl,v 1.2 2002/12/06 23:22:38 cssharp Exp $

# Homebrew Markup Overview
# ------------------------
#
# Sections and subsection:
#   <section name="my_section_name"> ... </section>
#
# Title, just at the beginning of the document:
#   <title> My Title </title>
# 
# Paragraphs:
#   <p> ... </p>
#
# Inline images:
#   <image src="my_image.png"/>
#
# Code blocks protected from all tags except </code>.  Blocks of code are
# subject to reformatting and parsing for NesC constructs.  Each module,
# interface, and typedef should be included in its own code block.  Given
# that, this script extract the type name from the block of code and links
# references to that name from all other code blocks:
#   <code> ... </code>
#
# Unordered lists:
#   <ul> <li> List Item One </li> <li> ... </li> </ul>
#
# Ordered lists:
#   <ol> <li> List Item One </li> <li> ... </li> </ol>
#
# Italics, bold, underline.  Outside these symbols must be immediately
# surrounded by whitespace and inside must include no whitespace.  This is
# to help prevent spurious markup:
#   /this/ /is/ /in/ /italics/
#   *this* *is* *in* *bold*
#   _this_ _is_ _underlined_
#
# Code fragments.  Code fragments use a monospace font.  If the code fragment
# corresponds to a module, interface, or typedef defined in a block of code,
# then an appropriate hyperlink is made:
#   [[MyModuleName]]


my %G_coderefs = ();
my @G_codelist = ();
my %doc = ( body => "" );


### HTML styles

$doc{style} =<< 'EOF';
<style>
<!--
.title {
  font-family:sans-serif;
  font-size:160%;
  font-weight:bold;
}
.heading1 {
  font-family:sans-serif;
  font-size:140%;
  font-weight:bold;
  margin-top:.25in;
}
.heading2 {
  font-family:sans-serif;
  font-size:125%;
  font-weight:bold;
  font-style:italic;
  margin-top:.25in;
}
.heading3 {
  font-family:sans-serif;
  font-size:110%;
  font-weight:bold;
  margin-top:.25in;
}
.heading4 {
  font-family:sans-serif;
  font-weight:bold;
  font-style:italic;
  margin-top:.25in;
}
.nesc_self {
  font-family:sans-serif;
  font-weight:bold;
  font-size:110%;
}
.code {
  border:1px solid black;
  padding:4px;
  background:#e8e8e8;
  margin-left:2em;
  margin-right:2em;
  font-family:monospace;
  font-size:10pt;
  white-space:pre;
}
.codefrag {
  font-family:monospace;
}
.subsection {
  margin-left:2em;
}
-->
</style>
EOF


### Regular expressions for matching blocks of nesc 

my %G_nesc = ();
$G_nesc{block} = '\{ [^\}]* \}';
$G_nesc{module} = 'module \s+ (\w+) \s* (?: \{ [\s\001]* provides \s* ('.$G_nesc{block}.') [\s\001]* uses \s* ('.$G_nesc{block}.') \s* \} | '.$G_nesc{block}.' )';
$G_nesc{interface} = 'interface \s+ (\w+) \s* ('.$G_nesc{block}.')';
$G_nesc{typedef} = 'typedef \s+ ([^\{;]*\S) \s* ('.$G_nesc{block}.'|\s+) \s* (\w+);';


### Process the input files.
###
### Cat all input files into one scalar, them split them into an array of
### tokens, where each token is either one tag or a block of uninterupted text.

# snarf up all the input text
my $text = join("",<>);

# grab all CVS Id: tags from html-style comment block
my @cvsid = ( $text =~ m/<!-- \s*\$ ( Id: .*? ) \$ \s* -->/gx );

# remove all html-style comments from the source
$text =~ s/<!--.*?-->//gs;

# temporarily mask all '<' and '>' symbols from within code blocks
# so that extracted code regions continue through to </code>
sub protectcode { (my $t = shift) =~ s/</\006/g; $t =~ s/>/\007/g; return $t; }
$text =~ s/(<code>)(.*?)(<\/code>)/$1.protectcode($2).$3/gesi;

# parse the text into tokens, where each token is one tag or uninterupted text
my @tokens = ($text =~ m/(<[^>]*>|[^<]*)/g);
my @section = (1);
my $do_code = 0;

for my $tt (@tokens) {

  ### skip this token if it's empty

  next if $tt eq "";

  ### handle plain text and continue
  ### we set the $do_code flag below when in a code region

  if( $tt =~ /^[^<]/ ) {
    if( $do_code ) {
      # restore the angle brackets from '\006' and '\007' to '<' and '>'
      $tt =~ s/\006/</g;
      $tt =~ s/\007/>/g;
      # reformat the code
      $doc{body} .= clean_code($tt);
    } else {
      $doc{body} .= text_formatting($tt);
    }
    $doc{body} .= "\n" unless $tt =~ /\n$/;
    next;
  }

  ### handle all manner of tags

  ### first parse the tag into tag name and field
  my $tag = lc( join("",$tt =~ /^<([^\s>]+)/) );
  $tag .= "/" if $tt =~ /\/>$/ && $tag !~ /\//;
  my %field = ( $tt =~ /([^\s=]+)="([^"]*)"/g );

  ### now process each tag name
  if( $tag eq "section" ) {

    push( @section, 1 );
    $doc{body} .= "<div class=\"heading" . $#section . "\">";
    $doc{body} .= join(".",@section[0..(@section-2)]) . ". "
      unless ($field{numbered}||"") eq "no";
    $doc{body} .= "$field{name}</div><div class=\"subsection\">";

  } elsif( $tag eq "/section" ) {

    pop( @section ) unless @section == 1;
    $section[-1]++;
    $doc{body} .= "</div>";

  } elsif( $tag eq "title" ) {

    $doc{body} .= "<div class=\"title\">";

  } elsif( $tag eq "/title" ) {

    $doc{body} .= "</div>";

  } elsif( $tag eq "cvsid/" ) {

    $doc{body} .= "\n<ul>\n<li>" . join("</li>\n<li>",@cvsid) . "</li>\n</ul>\n\n";

  } elsif( $tag eq "code" ) {

    $doc{body} .= "<pre class=\"code\" id=__FAKEXML_CODEREF__>";
    $do_code = 1;

  } elsif( $tag eq "/code" ) {

    $doc{body} .= "</pre>";
    $do_code = 0;

  } elsif( $tag eq "image/" ) {

    $doc{body} .= "<div align=center><img src=\"$field{src}\"></div>";

  } elsif( $tag =~ m{^/?(p|ul|ol|li)$} ) {

    $doc{body} .= $tt;

  } else {

    ### dumb error handling, sorry. you'll have to grep your source for the
    ### offending tag.
    die "ERROR, unknown tag $tag\n";

  }
}

### label all code blocks with the id of the code it contains
$doc{body} =~ s/ id=__FAKEXML_CODEREF__/my $a=shift @G_codelist; $a?" id=\"$a\"":""/eg;

### link to appropriate code sections throughout the text
@tokens = ();
$doc{body} =~ s/(<[^>]+>)/push(@tokens,$1);".\001."/eg;
$doc{body} =~ s/(\w+)\003/link_coderef($1)/eg;
$doc{body} =~ s/\[\[(\w+)\]\]/"<span class=\"codefrag\">".link_coderef($1)."<\/span>"/eg;
$doc{body} =~ s/.\001./shift(@tokens)/eg;
$doc{body} =~ s/[\002\003]//g;
$doc{body} =~ s/\006/&lt;/g;
$doc{body} =~ s/\007/&gt;/g;

### done, print style and body and get out of here
print "$doc{style}\n$doc{body}\n";
exit;



### link_coderef
###
### If the given word is a key in %G_coderef, then link it up.
### Otherwise, don't.

sub link_coderef {
  my $word = shift;
  if( exists($G_coderefs{$word}) ) {
    return "<a href=\"#$G_coderefs{$word}->{id}\">$word</a>";
  }
  return $word;
}


### clean_code
###
### Apply consistent indendation and spacing to a block of code.
### For an expected subset of NesC code, apply more aggressive indentation
### rules and extract the name of the module, interface, or typedef.

sub clean_code {
  my $text = shift;
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;

  $text =~ s/\s*\{/ {/g;

  my $n_indent = 4;
  my $indent = "";
  my $code = "";

  my @lines = split( /\s*\n\s*/, $text );
  for my $line (@lines) {
                               # unindent if starts with '}'
    $indent = substr( $indent, $n_indent ) if $line =~ /^\}/;
    $line =~ s/\s*\{/ {/g;     # one space before '{'
    $line =~ s/\}\s*/} /g;     # one space after '}'
    $line =~ s/\s*\(\s*/( /g;  # no spaces before and one space after '('
    $line =~ s/\s*\)\s*/ )/g;  # one space before and no spaces after ')'
    $line =~ s/\(\s*\)/()/g;   # no spaces inside '()'
    $line =~ s/\s*,\s*/, /g;   # no spaces before and one space after ','
    $code .= "$indent$line\n"; # apply the indentation to the line
                               # indent if ends with '{'
    $indent .= " " x $n_indent if $line =~ /\{$/;
  }

  ### try to recognize this is a block of NesC code.
  ### if so, use that parsing instead of the one we just used.
  my $nescref = prettify_nesc( $code );
  push( @G_codelist, ($nescref ? $nescref->{id} : "") );
  if( defined($nescref) ) {
    $code = $nescref->{text};
    $code = fix_html_special_chars($code);
    $code =~ s/(\w+)/$1\003/g;
    $code =~ s[\b($nescref->{name})\b][<span class="nesc_self">$1\002</span>];
    $G_coderefs{$nescref->{name}} = $nescref;
  } else {
    $code = fix_html_special_chars($code);
    $code =~ s/(\w+)/$1\003/g;
  }
  
  return $code;
}


### fix_html_special_chars
###

sub fix_html_special_chars {
  my $text = shift;
  my %chars = ( '<'=>'&lt;', '>'=>'&gt;', '&'=>'&amp;' );
  my $re = '([' . join("",keys %chars) . '])';
  $text =~ s/$re/$chars{$1}/geo;
  return $text;
}


### prettify_nesc
###
### Prettify nesc code

sub prettify_nesc {
  my $code = shift;

  ### Remove, mark, and save in a @comments array all comments in the nesc
  ### code.  This is to preserve all user formatting within comments.
  my @comments = ();
  $code =~ s/^\s+//g;
  $code =~ s{(\s*(?:/\*.*?\*/\s*?|\/\/.*?)\n)}{push(@comments,$1);"\001"}ges;

  ### Reindent the nesc code by ignoring all whitespace and applying a small,
  ### somewhat insufficient set of indentation rules.  Hack in a few simple
  ### regular expressions afterward to fix special cases.
  my $nin = 4; # number of spaces to indent
  my $in = ""; # current indentation prefix
  my $inatom = " " x $nin;  # cache one indentation
  $code =~ s/([\{\}();,\001])\s*
            /if($1 eq "{") { $in.=$inatom; "$1\n$in" } 
	     elsif($1 eq "}") { $in=substr($in,$nin); "\n$in$1" }
	     elsif($1 eq "(") { $in.=" "x($nin*1); "$1\n$in" } 
	     elsif($1 eq ")") { $in=substr($in,1*$nin); "\n$in$1" }
	     else { "$1\n$in" } # else is ";", ",", "\001"
            /gex;
  ### Collapse '( )' to '()', and such
  $code =~ s/\(\s*\)/()/g;
  ### Collapse parens with just one parameter to a single line
  #$code =~ s/\(\s*\n\s*([^,)]*[^,\s)])\s*\n\s*\)/( $1 )/g;
  ### Remove any blank lines
  $code =~ s/\n\s*\n/\n/g;
  ### Remove all whitespace in front of a comment marker
  $code =~ s/\s+\001/\001/g;
  ### If a close bracket is followed by a non-whitespace, insert a space
  $code =~ s/\}(\S)/} $1/g;
  ### Remove remaining trailing whitespace
  $code =~ s/\s+$//;

  ### Determine key and name fields for this nesc block
  my ($key,$name) = ("","");
  if( $code =~ m/^[\s\001]*$G_nesc{module}\s*$/xio ) { $key = "module"; $name = $1; }
  elsif( $code =~ m/^[\s\001]*$G_nesc{interface}\s*$/xio ) { $key = "interface"; $name = $1; }
  elsif( $code =~ m/^[\s\001]*$G_nesc{typedef}\s*$/xio ) { $key = "typedef"; $name = $3; }

  #if( $key ne "" ) { print stderr ">>> $key = $name\n"; }

  ### Reinsert the unmodified comment blocks
  $code =~ s/\001\n?/shift(@comments)/ge; 
  ### If a comment is flush at the start of a line and exists solely on that
  ### line, indent it.
  $code =~ s/\n *(\/\*.*?\*\/)/\n$inatom$1/g;

  $code =~ s/(\w+)/$1\003/g;

  ### Return this chunk of code as a hashref
  return $key ne "" ? { name=>$name, text=>$code, id=>"${key}_${name}" } : undef;
}


### text_formatting
###
### Apply common *bold* /italic/ and _underline_ markups to text

sub text_formatting {
  my $text = " $_[0] ";
  $text =~ s{(?<=\s)\*(\S+)\*(?=\s)}{<b>$1</b>}g;
  $text =~ s{(?<=\s)/(\S+)/(?=\s)}{<i>$1</i>}g;
  $text =~ s{(?<=\s)_(\S+)_(?=\s)}{<u>$1</u>}g;
  $text = substr( $text, 1, length($text)-2 );
  return $text;
}

