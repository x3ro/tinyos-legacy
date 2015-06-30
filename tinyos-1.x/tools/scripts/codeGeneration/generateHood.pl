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
#

use strict;
use FindBin;
use lib $FindBin::Bin;
use AtTags;

my $DestDir = "";

#get rid of extraneous arguments
my @args = @ARGV;
@ARGV = ();
while (@args){
    my $arg = shift @args;
    if ($arg eq "-d") {
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
print "generateHood.pl @ARGV\n";


##############################
# look through the @registry tags to find all unique Attributes, and
#count them
##############################


my ($attributeDefs, $includes) = AtTags::getUniqueTags(@ARGV, "registry", ("attrName"));
my $count = scalar keys %$attributeDefs;

##############################
# look through the @reflection tags to find all unique Reflections
# Numbers come by default by including the Registry.h file.
##############################


my ($reflectionDefs, $includesB) = AtTags::getUniqueTags(@ARGV, "reflection", ("hoodName","reflName"));

for my $include (keys %$includesB){
    $includes->{$include} = 1;
}

##############################
# look through the @scribble tags to find all unique Scribbles.
##############################


my ($scribbleDefs, $includesC) = AtTags::getUniqueTags(@ARGV, "scribble", ("hoodName","scribbleName"));

for my $include (keys %$includesC){
    $includes->{$include} = 1;
}

##############################
# Continue numbering the scribbles where the attributes left off
##############################

for my $name (sort keys %$scribbleDefs ) {
    my $scribble = $scribbleDefs->{$name};
    $scribble->{'scribbleNum'} = $count++;
}


##############################
# look through the @hood tags to find all unique neighborhoods.
##############################


my ($hoodDefs, $includesD) = AtTags::getUniqueTags(@ARGV, "hood", ("hoodName", "numNeighbors", "requiredAttr1", "requiredAttr2", "requiredAttr3", "requiredAttr4", "requiredAttr5", "requiredAttr6", "requiredAttr7", "requiredAttr8"));

for my $include (keys %$includesD){
    $includes->{$include} = 1;
}

##############################
# go through all reflections and scribbles and create a new hash of
# them for each hood.  Simultaneously, crosscheck all refls vs attribute
# names and all hoodNames against actual hood defs for undefined
#names;
# 
# The desired structure is:
# hoods--->Hood1--->reflections--->Refl1
#       |        |              |
#       |        |              |->Refl2...
#       |        |
#       |        |
#       |        |->scribbles----->Scribble1
#       |                       |
#       |                       |->Scribble2...
#       |
#       |
#       |->Hood2...
##############################

my %hoods;
while ( my ($hoodkey, $hood) = each ( %$hoodDefs) ){
    my %reflections;
    my %scribbles;
    my $hoodName = $hood->{'hoodName'};
    $hood->{'reflections'} = \%reflections;
    $hood->{'scribbles'} = \%scribbles;
    my @required = ();
    if ($hood->{"requiredAttr1"}) { push(@required, $hood->{"requiredAttr1"});}
    if ($hood->{"requiredAttr2"}) { push(@required, $hood->{"requiredAttr2"});}
    if ($hood->{"requiredAttr3"}) { push(@required, $hood->{"requiredAttr3"});}
    if ($hood->{"requiredAttr4"}) { push(@required, $hood->{"requiredAttr4"});}
    if ($hood->{"requiredAttr5"}) { push(@required, $hood->{"requiredAttr5"});}
    if ($hood->{"requiredAttr6"}) { push(@required, $hood->{"requiredAttr6"});}
    if ($hood->{"requiredAttr7"}) { push(@required, $hood->{"requiredAttr7"});}
    if ($hood->{"requiredAttr8"}) { push(@required, $hood->{"requiredAttr8"});}
    for my $attr (@required){
	if (! $attributeDefs->{$attr} ){
	    die("ERROR: $hoodName requires attribute $attr, which doesn't exist.");
	}
    }
    $hood->{'required'} = \@required;
    $hoods{$hoodName} = $hood;
}

while ( my ($key, $reflDef) = each( %$reflectionDefs) ){
    my $reflName = $reflDef->{'reflName'};
    if (! $attributeDefs->{$reflName} ){
	die ("$reflDef->{'componentName'}:  ERROR: reflection \"$reflName\" defined with no corresponding attribute.\n\n");
    }
    my $hoodName = $reflDef->{'hoodName'};
    if (! $hoods{$hoodName} ){
	die ("$reflDef->{'componentName'}:  ERROR: reflection \"$reflName\" defined in undefined hood \"$hoodName\".\n\n");
    }
    $hoods{$hoodName}->{'reflections'}->{$reflName} = $reflDef;
}

while ( my ($key, $scribbleDef) = each( %$scribbleDefs) ){
    my $scribbleName = $scribbleDef->{'scribbleName'};
    if ( $attributeDefs->{$scribbleName} ){
	die ("$scribbleDef->{'componentName'}:  ERROR: scribble \"$scribbleName\" has conflict with attribute of same name.\n\n");
    }
    my $hoodName = $scribbleDef->{'hoodName'};
    if (! $hoods{$hoodName} ){
	die ("$scribbleDef->{'componentName'}:  ERROR: scribble \"$scribbleName\" defined in undefined hood \"$hoodName\".\n\n");
    }
    $hoods{$hoodName}->{'scribbles'}->{$scribbleName} = $scribbleDef;
}



##############################
# Number the hoods alphabetically
##############################

my $firstHoodNum = 100;
$count = 0;
for my $name (sort keys %hoods ) {
    my $hood = $hoods{$name};
    $hood->{'hoodNum'} = $count++;
}


##############################
# discover the number of attributes, max reflections per hood, attr
# groups, etc in order to create the Hood.h file
##############################

#total number of attributes
my $numAttributes = scalar keys %$attributeDefs;
my $numHoods = scalar keys %$hoodDefs;
my $maxReflectionsPerHood=0;
my $maxRequiredPerHood=0;
my $maxAttributeGroupSize=1;
while ( my ($hoodName, $hood) = each (%hoods) ) {
    $hood->{'totalRefls'} = scalar keys(%{$hood->{'reflections'}})
	+  scalar keys (%{$hood->{'scribbles'}});
    if ($hood->{'totalRefls'} > $maxReflectionsPerHood ){
        #max reflections per hood
	$maxReflectionsPerHood = $hood->{'totalRefls'};
    }
    my $required = $hood->{'required'};
    if (scalar @$required > $maxRequiredPerHood ){
        #max required attributes per hood
	$maxRequiredPerHood = scalar @$required;
    }

    # create attribute groups, ie. groups of attrs that are "pushed" together (one for each attribute)
    if (scalar @$required > 1){
	for my $attr (@$required){
	    my %groupHash; #use hash table to avoid duplicates in group
	    my $group = \%groupHash;
	    if ($attributeDefs->{$attr}->{'group'}) {
		$group = $attributeDefs->{$attr}->{'group'};
	    }
	    for my $subAttr (@$required){
		if ($attr ne $subAttr ){
		    $group->{$subAttr} = 1;
		}
	    }
	    if (1 + scalar keys %$group > $maxAttributeGroupSize){
		$maxAttributeGroupSize = 1+ scalar keys %$group;
	    }
	    $attributeDefs->{$attr}->{'group'} = $group;
	}
    }
}




##############################
# print out the parsed info for debugging/user knowledge
##############################

my $s;

if (keys %hoods){
    while ( my ($hoodName, $hood) = each ( %hoods) ){
	$s = "Adding reflections to $hoodName:\n"; 
	my $reflections = $hood->{'reflections'};
	while ( my ($reflName, $reflection) = each %$reflections ) { 
	    if ($reflection->{'provided'}==1){
		$s = sprintf "%s%30s : %s\n", $s, $reflection->{'gparams'}->[0],"$reflection->{'componentName'}.$reflName"; 
	    }
	    else{
		$s = sprintf "%s%30s : %s\n", $s, $reflection->{'gparams'}->[0],$reflName; 
	    }
	}
	print "$s\n"; 
	$s = "Adding scribbles to $hoodName:\n"; 
	my $scribbles = $hood->{'scribbles'};
	while ( my ($scribbleName, $scribble) = each %$scribbles ) { 
	    if ($scribble->{'provided'}==1){
		$s = sprintf "%s%30s:\t\t$scribble->{'gparams'}->[0]\n", $s, "$scribble->{'componentName'}.$scribbleName"; 
	    }
	    else{
		$s = sprintf "%s%30s:\t\t$scribble->{'gparams'}->[0]\n", $s, $scribbleName; 
	    }
	}
	print "$s\n"; 
    }
}
else{
    print "** Warning: no hoods defined.\n\n"; 
}	

##############################
# Create a warning at the top of each generated file
##############################

my $G_warning =<< 'EOF';
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***
// ***                                                                     ***
// *** This file was automatically generated by generateHood.pl.   ***
// *** Any and all changes made to this file WILL BE LOST!                 ***
// ***                                                                     ***
// *** WARNING ****** WARNING ****** WARNING ****** WARNING ****** WARNING ***

EOF



if (keys %hoods) {
    
    ##############################
    # Generate the Hood.h file
    ##############################
    
    $s = sprintf "#ifndef __HOOD_H__\n";
    $s = sprintf "%s#define __HOOD_H__\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s#include \"Registry.h\"\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s/*********************************\n", $s;
    $s = sprintf "%s* The following are the definitions of the \@tags that hood uses. \n", $s;
    $s = sprintf "%s* These definitions are needed by the compiler to parse the tag parameters. \n", $s;
    $s = sprintf "%s*********************************/\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sstruct \@reflection {\n", $s;
    $s = sprintf "%s  char *reflName;\n", $s;
    $s = sprintf "%s  char *hoodName;\n", $s;
    $s = sprintf "%s};\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sstruct \@scribble {\n", $s;
    $s = sprintf "%s  char *scribbleName;\n", $s;
    $s = sprintf "%s  char *hoodName;\n", $s;
    $s = sprintf "%s};\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sstruct \@hood {\n", $s;
    $s = sprintf "%s  char *hoodName;\n", $s;
    $s = sprintf "%s  uint8_t numNeighbors;\n", $s;
    $s = sprintf "%s  char *requiredAttr1;\n", $s;
    $s = sprintf "%s  char *requiredAttr2;\n", $s;
    $s = sprintf "%s  char *requiredAttr3;\n", $s;
    $s = sprintf "%s  char *requiredAttr4;\n", $s;
    $s = sprintf "%s  char *requiredAttr5;\n", $s;
    $s = sprintf "%s  char *requiredAttr6;\n", $s;
    $s = sprintf "%s  char *requiredAttr7;\n", $s;
    $s = sprintf "%s  char *requiredAttr8;\n", $s;
    $s = sprintf "%s};\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s/*********************************\n", $s;
    $s = sprintf "%s* The following typedefs are the IDs of each type entity,\n", $s;
    $s = sprintf "%s* eg, attributes, reflections, hoods, etc.\n", $s;
    $s = sprintf "%s* These IDs are used to identify what is being\n", $s;
    $s = sprintf "%s* packed/unpacked by the data marshaller.  Eg. a refl is Identified\n", $s;
    $s = sprintf "%s* by the reflID and the nodeID.  Typedefs are used to be\n", $s;
    $s = sprintf "%s* able to change the way we identify data in the future.. \n", $s;
    $s = sprintf "%s*********************************/\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%stypedef struct ReflBackend_t {\n", $s;
    $s = sprintf "%s  uint8_t reflID;\n", $s;
    $s = sprintf "%s  uint16_t nodeID;\n", $s;
    $s = sprintf "%s} ReflBackend_t;\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%stypedef uint8_t ReflID_t;\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%stypedef uint8_t HoodID_t;\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s/*********************************\n", $s;
    $s = sprintf "%s* The following constants are the actual IDs of \n", $s;
    $s = sprintf "%s* each hood and scribble.  Hood IDs are offset by HOOD_ID_OFFSET in \n", $s;
    $s = sprintf "%s* order to allow IDs for the registry, memset/memget, etc. \n", $s;
    $s = sprintf "%s* Reflection IDs are the same as the attribute IDs by definition.\n", $s;
    $s = sprintf "%s*********************************/\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%senum {\n", $s;
    $s = sprintf "%s  HOOD_ID_OFFSET = $firstHoodNum\n", $s;
    $s = sprintf "%s};\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%senum {\n", $s;
    $s = sprintf "%s  //1 is the registry\n", $s;
    $s = sprintf "%s  //2 is ram query\n", $s;
    $s = sprintf "%s  //3 is hood query\n", $s;
    $s = sprintf "%s  //4 is hood transport\n", $s;
    $s = sprintf "%s  ALL_HOODS = 5,", $s;
    while ( my ($hoodName, $hood) = each %hoods ) { 
	$s = sprintf "%s\n  %s = %d,", $s, uc $hoodName, $hood->{'hoodNum'}+$firstHoodNum;
    }
    $s = sprintf "%s\b\n};\n", $s;

    if (scalar keys %$scribbleDefs > 0){   
	$s = sprintf "%s\n", $s;
	$s = sprintf "%senum {", $s;
	while ( my ($scribbleKey, $scribble) = each %$scribbleDefs ) { 
	    $s = sprintf "%s\n  %s = %d,", $s, "ATTRIBUTE_".uc $scribble->{'scribbleName'}, $scribble->{'scribbleNum'};;
	}
	$s = sprintf "%s\b\n};\n", $s;
    }

    $s = sprintf "%s\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s/*********************************\n", $s;
    $s = sprintf "%s* The following constants are not currently used, but may be useful to others\n", $s;
    $s = sprintf "%s*********************************/\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%senum {", $s;
    while ( my ($hoodName, $hood) = each %hoods ) { 
	$s = sprintf "%s\n  %s_NUM_NEIGHBORS = %d,", $s, uc $hoodName, $hood->{'numNeighbors'};
    }
    $s = sprintf "%s\b\n};\n", $s;

    $s = sprintf "%s\n", $s;
    $s = sprintf "%senum {\n", $s;
    $s = sprintf "%s  MAX_REFLECTIONS_PER_HOOD = $maxReflectionsPerHood,\n", $s;
    $s = sprintf "%s  MAX_REQUIRED_PER_HOOD = $maxRequiredPerHood,\n", $s;
    $s = sprintf "%s  NUM_ATTRIBUTES = $numAttributes,\n", $s;
    $s = sprintf "%s  MAX_ATTRIBUTES_GROUP_SIZE = $maxAttributeGroupSize\n", $s;
    $s = sprintf "%s};\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s/*********************************\n", $s;
    $s = sprintf "%s* The following constants are used by HoodM.nc and HoodTransportM.nc\n", $s;
    $s = sprintf "%s* This is way for the code generation mechanism to pass array parameters \n", $s;
    $s = sprintf "%s* to the code, which NesC does not allow\n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s* \"reflections\" is used by HoodM to know which reflections it has so\n", $s;
    $s = sprintf "%s* it can clear them all when a node is removed from the hood.\n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s* \"requiredAttrs\" is used by HoodM to know which reflections it requires so\n", $s;
    $s = sprintf "%s* it can signal a new candidate when all required refls become filled.\n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s* \"attrGroup\" is used by HoodTransportM to know which attributes are grouped\n", $s;
    $s = sprintf "%s* so it can \"push\" them all simultaneously if one is pushed.\n", $s;
    $s = sprintf "%s* \n", $s;
    $s = sprintf "%s*********************************/\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t numReflections[$numHoods] = {", $s;
    for my $name (sort keys %hoods ) {
	my $hood = $hoods{$name};
	$s = sprintf "%s %d,", $s, $hood->{'totalRefls'};
    }
    $s = sprintf "%s\b };\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t reflections[$numHoods][$maxReflectionsPerHood] = {", $s;
    for my $hoodName (sort keys %hoods ) {
	my $hood = $hoods{$hoodName};
	$s = sprintf "%s\n%33s   { ", $s, "/*$hoodName*/";
	for my $name (keys %{$hood->{'reflections'}}) {
	    $s = sprintf "%s %s,", $s, "ATTRIBUTE_".uc $name;
	}
	for my $name (keys %{$hood->{'scribbles'}}) {
	    $s = sprintf "%s %s,", $s, "ATTRIBUTE_".uc $name;
	}
	$s = sprintf "%s\b },", $s;
    }
    $s = sprintf "%s\b\n%36s\n", $s, "};";
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t numRequired[$numHoods] = {", $s;
    for my $name (sort keys %hoods ) {
	my $hood = $hoods{$name};
	$s = sprintf "%s %d,", $s, scalar @{$hood->{'required'}};
    }
    $s = sprintf "%s\b };\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t requiredAttrs[$numHoods][$maxRequiredPerHood] = {", $s;
    for my $hoodName (sort keys %hoods ) {
	$s = sprintf "%s\n%33s   { ", $s, "/*$hoodName*/";
	for my $requiredAttrName (@{$hoods{$hoodName}->{'required'}}) {
	    $s = sprintf "%s %s,", $s, "ATTRIBUTE_".uc $requiredAttrName;
	}
	$s = sprintf "%s\b },", $s;
    }
    $s = sprintf "%s\b\n%36s\n", $s, "};";
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t groupSize[$numAttributes] = {", $s;
    for my $name (sort keys %$attributeDefs ) {
	$s = sprintf "%s %d,", $s, 1 + scalar keys %{$attributeDefs->{$name}->{'group'}};
    }
    $s = sprintf "%s\b };\n", $s;
    $s = sprintf "%s\n", $s;
    $s = sprintf "%sconst uint8_t attrGroup[$numAttributes][$maxAttributeGroupSize] = {", $s;
    for my $attrName (sort keys %$attributeDefs ) {
	$s = sprintf "%s\n%33s   { ", $s, "/*$attrName*/";
	$s = sprintf "%s %s,", $s, "ATTRIBUTE_".uc $attrName; #the attr itself is always the first in the list
	for my $attrName (keys %{$attributeDefs->{$attrName}->{'group'}}) {
	    $s = sprintf "%s %s,", $s, "ATTRIBUTE_".uc $attrName; #now add the rest
	}
	$s = sprintf "%s\b },", $s;
    }
    $s = sprintf "%s\b\n%36s\n", $s, "};";
    $s = sprintf "%s\n", $s;
    $s = sprintf "%s#endif //__HOOD_H__\n", $s;

#send the generated code out to a file
SlurpFile::dump_file( "${DestDir}Hood.h", "$G_warning$s" );



    ##############################
    # For each hood, generate the XxxHoodC.nc file
    ##############################
    while (my ($hoodName, $hood) = each ( %hoods) ){
	my $name;
	my$item;

	$includes->{'includes Registry;'}=1;
	$includes->{'includes Hood;'}=1;
	
	$s = "";
	for my $include (keys %$includes){
	    $s .= "$include\n";
	}

	$s = sprintf "%s\n", $s;
	$s = sprintf "%sconfiguration ${hoodName}C {\n", $s;
	$s = sprintf "%s  provides {\n", $s;
	$s = sprintf "%s    interface StdControl;\n", $s;
	$s = sprintf "%s    interface Hood;\n", $s;
	$s = sprintf "%s    interface HoodManager;\n", $s;
	$s = sprintf "%s\n", $s;
	while ( ($name, $item) = each ( %{$hood->{'reflections'}}) ){
	    $s = sprintf "%s    interface Reflection<$item->{'gparams'}->[0]> as  $item->{'interfaceName'};\n", $s;
	}
	while( ($name, $item) = each ( %{$hood->{'scribbles'}}) ){
	    $s = sprintf "%s    interface Reflection<$item->{'gparams'}->[0]> as  $item->{'interfaceName'};\n", $s;
	}
	$s = sprintf "%s  }\n", $s;
	$s = sprintf "%s}\n", $s;
	$s = sprintf "%s\n", $s;
	$s = sprintf "%simplementation {\n", $s;
	$s = sprintf "%s\n", $s;
	$s = sprintf "%s  components HoodTransportC;\n", $s;
	$s = sprintf "%s  components new HoodM ( %s, %s_NUM_NEIGHBORS+1 ) as HoodM;\n", $s, uc $hoodName, uc $hoodName;
	while( ($name, $item) = each ( %{$hood->{'reflections'}}) ){
	    $s = sprintf "%s  components new ReflectionM ( $item->{'gparams'}->[0], %s_NUM_NEIGHBORS+1 ) as  $item->{'interfaceName'}M;\n", $s, uc $hoodName;
	}
	while( ($name, $item) = each ( %{$hood->{'scribbles'}}) ){
	    $s = sprintf "%s  components new ReflectionM ( $item->{'gparams'}->[0], %s_NUM_NEIGHBORS+1 ) as  $item->{'interfaceName'}M;\n", $s, uc $hoodName;
	}
	$s = sprintf "%s\n", $s;
	$s = sprintf "%s  StdControl = HoodTransportC;\n", $s;
	$s = sprintf "%s  StdControl = HoodM;\n", $s;
	$s = sprintf "%s\n", $s;
	$s = sprintf "%s  Hood = HoodM.Hood;\n", $s;
	$s = sprintf "%s  HoodManager = HoodM.HoodManager;\n", $s;
	$s = sprintf "%s\n", $s;
	$s = sprintf "%s  //setup hood communication\n", $s;
	$s = sprintf "%s  HoodM.HoodTransport -> HoodTransportC;\n", $s;
	$s = sprintf "%s  HoodTransportC.GenericBackend[ALL_HOODS] -> HoodM;\n", $s;
	$s = sprintf "%s  HoodTransportC.GenericBackend[%s] -> HoodM;\n", $s, uc $hoodName;
	$s = sprintf "%s\n", $s;
	while( ($name, $item) = each ( %{$hood->{'reflections'}}) ){
	    $s = sprintf "%s  HoodM.ReflBackend[%s] -> $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	while( ($name, $item) = each ( %{$hood->{'scribbles'}}) ){
	    $s = sprintf "%s  HoodM.ReflBackend[%s] -> $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	$s = sprintf "%s\n", $s;
	$s = sprintf "%s  //expose interfaces of reflections and scribbles\n", $s;
	while( ($name, $item) = each ( %{$hood->{'reflections'}}) ){
	    $s = sprintf "%s  StdControl = $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	while( ($name, $item) = each ( %{$hood->{'scribbles'}}) ){
	    $s = sprintf "%s  StdControl = $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	$s = sprintf "%s\n", $s;
	while( ($name, $item) = each ( %{$hood->{'reflections'}}) ){
	    $s = sprintf "%s  $item->{'interfaceName'} = $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	while( ($name, $item) = each ( %{$hood->{'scribbles'}}) ){
	    $s = sprintf "%s  $item->{'interfaceName'} = $item->{'interfaceName'}M;\n", $s, "ATTRIBUTE_".uc $name;
	}
	$s = sprintf "%s}\n", $s;

        #send the generated code out to a file
        SlurpFile::dump_file( "${DestDir}${hoodName}C.nc", "$G_warning$s" );
    }
}




