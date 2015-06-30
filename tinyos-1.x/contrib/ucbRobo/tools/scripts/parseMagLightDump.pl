#!/usr/bin/perl

# Run this script to convert raw data files logged from the mote to
# decimal number format.
#
# RUN like this:
# Name your data files data* (or change $commonName below)
# dump the data files in directories for each test
# dump all test directories in a directory (say 'results')
# ls | parseTBDataDump.pl

$commonName = data;
foreach $dirname (<>) {
    chomp($dirname);
    opendir(DIR, $dirname) or next; #die  "can't opendir $dirname: $!\n";
    while (defined($file = readdir(DIR))) {
	# do something with "$dirname/$file"
	if ($file eq ".." || $file eq "." || !($file =~ /$commonName/)) {next;};
	print "parsing file $file\n";
	open(INFILE, "<$dirname/$file");

	$unixtime = <INFILE>;
	$commString = <INFILE>; # might have IP address, or network@ipaddress...
	@commArr = split(/[\.,:]/,$commString);
	shift @commArr;
	shift @commArr;
	shift @commArr;
	$moteID = shift @commArr;
	$moteID -= 100; #IP address is 100 + moteID
	
	open(OUTFILE, ">$dirname/mote$moteID".".txt");
	while (<INFILE>) {
	    @line = split; #splits by whitespace
	    shift @line; shift @line; #remove destination address
	    $AM = shift @line;
	    if (hex($AM) == 1) {
		shift @line; shift @line; # remove groupID and msg length
		$sourceID = shift @line;
		$sourceID = (shift @line).$sourceID;
		$seqNo = shift @line;
		$seqNo = (shift @line).$seqNo;
		$dataX = shift @line;
		$dataX = (shift @line).$dataX;
		$dataY = shift @line;
		$dataY = (shift @line).$dataY;
		print OUTFILE hex($sourceID)." ";
		print OUTFILE hex($seqNo)." ";
		print OUTFILE hex($dataX)." ";
		print OUTFILE hex($dataY)."\n";
	    }
	} #while file loop
	close(INFILE);
	close(OUTFILE);
    } #while dir loop
    closedir(DIR);
}
