#!/usr/bin/perl

# Strips out the registry code from a properly annotated file.
# Meant to work with PIRDetect(Simple)M.nc, PIRDetect(Simple)C.nc
# (see file list below)
# Output files requires interface file PIRDetection.nc and PIRRawData.nc
#
# * Replaces by substitution
# * Removes entire lines
#   ~ ex. if we have 'KrakenC;' on a line, all of it will be removed, including the ;
# * all code between (and including)  $startRemove and $stopRemove are removed
# * note that the "uses" and "provides" interface for PIRDetection and 
#   PIRRawData must be one line each (not part of a uses or provides block).
# * matching of 'configuration {' for adding 'provide interface' to PIRDetectC
#   uses exact syntax.
# * Adds in wiring of Main.StdControl->GenericComm explicitly for OscopeC to work
#   in barebones test file.
#
# NOTES:
# * In Perl 6 regexes, variables don't interpolate.
#   ~  Perl 6: / $var /
#      is like a Perl 5: / \Q$var\E /
# * To force interpolation, you must use assertions
#   ~ Assertions are delimited by <...>, where the first character
#     after < determines the behavior of the assertion
#   ~ A leading { after < indicates code that produces a regex to be
#     interpolated into the pattern at that point: 
#     ex. / (<ident>)  <{ cache{$1} //= get_body($1) }> /

print "Make sure you are running Perl version less than 6.\n";
print "Otherwise you will need to modify the script to interpolate\n";
print "variables in regular expressions.\n";

if ($ARGV[0] == 1) { #TestPIRDetectSimple
    #for top level; interface users
    %exactReplace1 = ("uses interface Attribute<uint16_t> as PIRDetection \@registry(\"PIRDetection\");", "uses interface PIRDetection;",
		      "uses interface Attribute<uint16_t> as PIRRawData \@registry(\"PIRRawData\");", "uses interface PIRRawData;",
		      "OscopeC,","OscopeC,\n             GenericComm as Comm,",
		      "Main.StdControl -> OscopeC;", "Main.StdControl -> OscopeC;\n  Main.StdControl -> Comm;",
		      "TestPIRDetectSimpleM.PIRDetection -> RegistryC.PIRDetection;","TestPIRDetectSimpleM.PIRDetection -> PIRDetectSimpleC;",
		      "TestPIRDetectSimpleM.PIRRawData -> RegistryC.PIRRawData;","TestPIRDetectSimpleM.PIRRawData -> PIRDetectSimpleC;");
    #for bottom level; interface providers
    %exactReplace2 = ("uses interface Attribute<uint16_t> as PIRDetection \@registry(\"PIRDetection\");", "provides interface PIRDetection;",
		      "uses interface Attribute<uint16_t> as PIRRawData \@registry(\"PIRRawData\");", "provides interface PIRRawData;",
		      "PIRDetectSimpleM.PIRRawData -> RegistryC.PIRRawData;","PIRRawData = PIRDetectSimpleM;",
		      "PIRDetectSimpleM.PIRDetection -> RegistryC.PIRDetection;","PIRDetection = PIRDetectSimpleM;",
		      "call PIRDetection.set(100)","signal PIRDetection.updated(100)",
		      "call PIRDetection.set(0)","signal PIRDetection.updated(0)",
		      "call PIRRawData.set(dataVal)","signal PIRRawData.updated(dataVal)",
		      "configuration PIRDetectSimpleC {",
		      "configuration PIRDetectSimpleC {\n  provides interface PIRRawData;\n  provides interface PIRDetection;");
    @inputFiles1 = ("../TestPIRDetect/TestPIRDetectSimple.nc",
		    "../TestPIRDetect/TestPIRDetectSimpleM.nc");
    @inputFiles2 = ("../../lib/PIRDetect/PIRDetectSimpleC.nc",
		    "../../lib/PIRDetect/PIRDetectSimpleM.nc");
} else { #TestPIRDetect
    #for top level; interface users
    %exactReplace1 = ("uses interface Attribute<uint16_t> as PIRDetection \@registry(\"PIRDetection\");", "uses interface PIRDetection;",
		      "uses interface Attribute<uint16_t> as PIRRawData \@registry(\"PIRRawData\");", "uses interface PIRRawData;",
		      "OscopeC,","OscopeC,\n             GenericComm as Comm,",
		      "Main.StdControl -> OscopeC;", "Main.StdControl -> OscopeC;\n  Main.StdControl -> Comm;",
		      "TestPIRDetectM.PIRDetection -> RegistryC.PIRDetection;","TestPIRDetectM.PIRDetection -> PIRDetectC;",
		      "TestPIRDetectM.PIRRawData -> RegistryC.PIRRawData;","TestPIRDetectM.PIRRawData -> PIRDetectC;");
    #for bottom level; interface providers
    %exactReplace2 = ("uses interface Attribute<uint16_t> as PIRDetection \@registry(\"PIRDetection\");", "provides interface PIRDetection;",
		      "uses interface Attribute<uint16_t> as PIRRawData \@registry(\"PIRRawData\");", "provides interface PIRRawData;",
		      "PIRDetectM.PIRRawData -> RegistryC.PIRRawData;","PIRRawData = PIRDetectM;",
		      "PIRDetectM.PIRDetection -> RegistryC.PIRDetection;","PIRDetection = PIRDetectM;",
		      "call PIRDetection.set(confidence)","signal PIRDetection.updated(confidence)",
		      "call PIRDetection.set(0)","signal PIRDetection.updated(0)",
		      "call PIRRawData.set(dataVal)","signal PIRRawData.updated(dataVal)",
		      "configuration PIRDetectC {",
		      "configuration PIRDetectC {\n  provides interface PIRRawData;\n  provides interface PIRDetection;");
    @inputFiles1 = ("../TestPIRDetect/TestPIRDetect.nc",
		    "../TestPIRDetect/TestPIRDetectM.nc");
    @inputFiles2 = ("../../lib/PIRDetect/PIRDetectC.nc",
		    "../../lib/PIRDetect/PIRDetectM.nc");
}


@exactRemove = ("RegistryC","KrakenC","includes Registry;");
# will also remove other lines like "Main.StdControl -> KrakenC;"
@regexRemove = ("interface Attribute");
#@regexRemove = ("interface Attribute<\\w+> as \\w+ @registry\(\"\\w+\"\);");
$startRemove = "//////////Registry Code Start//////////";
$stopRemove = "//////////Registry Code Stop//////////";


#Debugging
# foreach $regex (@regexRemove) {
#     print "$regex\n";
# }
# foreach $exactRep (keys %exactReplace) {
#     print "$exactRep\n";
# }

foreach $file (@inputFiles1) {
    &parsePrint(1);
}

foreach $file (@inputFiles2) {
    &parsePrint(2);
}

sub parsePrint {
    $useProvide = $_[0];
    #print ">>> DEBUG:  $useProvide\n";
    $remFlag = 0;
    $outFile = $file;
    $outFile =~ s/[.\/\w]+\///;
    print "########    $outFile    ########\n";
    open(INFILE,$file);
    open(OUTFILE,">$outFile");
    while ($ln = <INFILE>) {
	if ($ln =~ /\Q$startRemove\E/) {$remFlag++};
	if ($ln =~ /\Q$stopRemove\E/) {$remFlag--};
	if ($remFlag <= 0) {
	  SWITCH: {
	      if ($ln =~ /\Q$stopRemove\E/) {
		  print "REMOVING_BLOCK:  ".$ln;
		  last SWITCH;
	      }
	      if ($useProvide == 1) {
		  foreach $exactRep (keys %exactReplace1) {
		      if($ln =~ /\Q$exactRep\E/) {
			  print "EXACT_REPLACE:  ".$ln;
			  $ln =~ s/\Q$exactRep\E/$exactReplace1{$exactRep}/;
			  print OUTFILE $ln;
			  last SWITCH;
		      }
		  }
	      } elsif ($useProvide == 2) {
		  foreach $exactRep (keys %exactReplace2) {
		      if($ln =~ /\Q$exactRep\E/) {
			  print "EXACT_REPLACE:  ".$ln;
			  $ln =~ s/\Q$exactRep\E/$exactReplace2{$exactRep}/;
			  print OUTFILE $ln;
			  last SWITCH;
		      }
		  }
	      }
	      foreach $exactRem (@exactRemove) {
		  if($ln =~/\Q$exactRem\E/) {
		      print "EXACT_REMOVE:  ".$ln;
		      last SWITCH;
		  }
	      }
	      foreach $regEx (@regexRemove) {
		  if ($ln =~ /$regEx/) { #modify for perl 6
		      print "REGEX_REMOVED:  ".$ln;
		      last SWITCH;
		  }
	      }
	      print OUTFILE $ln;
	  } #SWITCH
	} else {
	    print "REMOVING_BLOCK:  ".$ln;
	} #if $remFlag
    } #while
    close(INFILE);
    close(OUTFILE);
    print "\n";
}
