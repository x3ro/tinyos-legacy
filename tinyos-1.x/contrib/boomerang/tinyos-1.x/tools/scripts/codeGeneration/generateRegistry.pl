#!/usr/bin/perl -w

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
#
# @author Kamin Whitehouse 
# @author Cory Sharp

use strict;
use FindBin;
use lib $FindBin::Bin;
use AtTags;
use SlurpFile;

my $DestDir = "";
my $useRpc = 1;

#get rid of extraneous arguments
my @args = @ARGV;
@ARGV = ();
while (@args){
    my $arg = shift @args;
    if (($arg eq "-DNO_RPC") || ($arg eq "-DNO_RPC_FOR_REGISTRY")) {
	$useRpc = 0;
    }
    elsif ($arg eq "-d") {
        $DestDir = shift @args;
        $DestDir .= "/" unless $arg =~ m{/$};
    } elsif ($arg !~ m/^-[^I]/) {
	push @ARGV, $arg;
    }
}

#add a few more directories that should always be on the search path
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/types/" );
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/interfaces/" );
unshift ( @ARGV, "-I".$ENV{'TOSDIR'}."/system/" );
unshift ( @ARGV, "-I".$ENV{'PWD'}."/" );


#make sure the user knows what's going on:
print "generateRegistry.pl @ARGV\n";


##############################
# look through the @registry tags to find all unique Attributes
##############################


my ($attributes, $includes) = AtTags::getUniqueTags(@ARGV, "registry", ("attrName"));
for my $attr (keys %$attributes) {
}

##############################
# Number the attributes alphabetically
##############################

my $count = 0;
for my $attr (sort {$a->{attrName} cmp $b->{attrName}} values %$attributes) {
    $attr->{attrNum} = $count++;
    $attr->{attrEnum} = "ATTRIBUTE_" . uc($attr->{attrName});
}




##############################
# print out the parsed info for debugging/user knowledge
##############################

if (keys %$attributes){
    my $s = "Adding attributes to the RegistryC:\n"; 
    while ( my ($name, $attribute) = each %$attributes ) { 
	if ($attribute->{'provided'}==1){
	    $s .= sprintf "%30s : %s\n", "$attribute->{'gparams'}->[0]", "$attribute->{'componentName'}.$name"; 
	}
	else{
	    $s .= sprintf "%30s : %s\n", $attribute->{'gparams'}->[0], $name; 
	}
    }
    print "$s\n"; 
}
else{
    print "** Warning: no attributes added to the Registry.\n\n"; 
}	



my $text;

##############################
# Generate blocks of text for Registry.h and RegistryC.nc
##############################

my $enum = "";
my $provides = "";
my $components = "";
my $wiring = "";

my $nucleus_provides = "";
my $nucleus_components = "";
my $nucleus_wiring = "";
my $rpc;
if ($useRpc) {
    $rpc = '@rpc()';
}
else {
    $rpc = '';
}
for my $attr (sort { $a->{attrName} cmp $b->{attrName} } values %$attributes) { 

    my $gparams = "";
    for my $param (@{$attr->{gparams}}){
	$gparams .= $param.",";
    }
    $gparams .= "\b";

    $enum .= "  $attr->{attrEnum} = $attr->{attrNum},\n";
    $provides .= "  provides interface Attribute<$gparams> as $attr->{attrName} $rpc;\n";
    $wiring .= "\n";

    if ($attr->{provided} == 1) {
        $components .= "  components $attr->{componentName};\n";
    }
    else{
        $attr->{componentName} = "$attr->{attrName}C";
        $components .= "  components new AttributeM($gparams) as $attr->{componentName};\n";
        $wiring .= "  StdControl = $attr->{attrName}C;\n";
    }
    $wiring .= "  $attr->{attrName} = $attr->{componentName};\n";
    $wiring .= "  AttrBackend[$attr->{attrEnum}] = $attr->{componentName};\n", 
    $wiring .= "  RegistryM.AttrBackend[$attr->{attrEnum}] -> $attr->{componentName};\n";

    $attr->{nucleusComponentName} = "$attr->{componentName}";
    $attr->{nucleusInterfaceName} = "$attr->{attrName}";
    $attr->{nucleusSetInterfaceName} = "$attr->{attrName}Set";
    $nucleus_provides .= "  provides interface Attr<$gparams> as $attr->{nucleusInterfaceName} \@nucleusAttr(\"$attr->{attrName}\");\n";
    $nucleus_provides .= "  provides interface AttrSet<$gparams> as $attr->{nucleusSetInterfaceName} \@nucleusAttr(\"$attr->{attrName}\");\n";
    $nucleus_components .= "  components new NucleusAttrWrapperC($gparams) as $attr->{nucleusComponentName};\n";
    $nucleus_wiring .= "\n";
    $nucleus_wiring .= "  $attr->{nucleusInterfaceName} = $attr->{nucleusComponentName}.Attr;\n";
    $nucleus_wiring .= "  $attr->{nucleusSetInterfaceName} = $attr->{nucleusComponentName}.AttrSet;\n";
    $nucleus_wiring .= "  $attr->{nucleusComponentName}.Attribute -> RegistryC.$attr->{attrName};\n";
}

if( $wiring eq "" ) {
  $wiring .=<<"EOF";

  // There are no attributes, so wire in StdControl and AttrBackend stubs
  StdControl = RegistryM;
  AttrBackend[0] = RegistryM;
EOF
}

##############################
# Create a warning at the top of each generated file
##############################

my $G_warning =<< 'EOF';
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***
// ***                                                                     ***
// *** This file was automatically generated by generateRegistry.pl.   ***
// *** Any and all changes made to this file WILL BE LOST!                 ***
// ***                                                                     ***
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***

EOF

##############################
# Generate the Registry.h file
##############################

$text = <<"EOF";


#ifndef __REGISTRY_H__
#define __REGISTRY_H__

struct \@registry {
  char *attrName;
};

enum attributes {
  MARSHALL_REGISTRY = 1, //marshaller data source id for the registry

$enum
};

typedef uint8_t AttrID_t;

#endif //__REGISTRY_H__

EOF

#send the generated code out to a file
SlurpFile::dump_file( "${DestDir}Registry.h", "$G_warning$text" );


##############################
# Generate the RegistryC.nc file
##############################
#$includes->{'includes Registry;'}=1;
#if ($useRpc) {
#    $includes->{'includes Rpc;'}=1;
#}
my $includeStr = "";
for my $include (keys %$includes){
    $includeStr .= "$include\n";
}

$text =<<"EOF";
includes Registry;
includes Rpc;
$includeStr

configuration RegistryC {
  provides interface StdControl;
  provides interface GenericBackend;
  provides interface AttrBackend[AttrID_t];

$provides
}
implementation {
  components RegistryM;
  components NucleusRegistryC;
$components
  GenericBackend = RegistryM;
$wiring}

EOF

#send the generated code out to a file
my $backsp = sprintf("\b");
$text =~ s/.$backsp//g;
SlurpFile::dump_file( "${DestDir}RegistryC.nc", "$G_warning$text" );


##############################
# Generate the NucleusRegistryC.nc file
##############################

$text =<<"EOF";
includes Attrs;
includes Registry;
includes Rpc;
$includeStr

configuration NucleusRegistryC {

$nucleus_provides
}
implementation {
  components RegistryC;
$nucleus_components$nucleus_wiring}

EOF

#send the generated code out to a file
$backsp = sprintf("\b");
$text =~ s/.$backsp//g;
SlurpFile::dump_file( "${DestDir}NucleusRegistryC.nc", "$G_warning$text" );

