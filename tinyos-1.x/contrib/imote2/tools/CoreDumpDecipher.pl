#!/usr/bin/perl

$ADDR2LINE = '/cygdrive/c/wasabi/usr/local/bin/xscale-elf-addr2line.exe';

sub FileContent
{
	$fileName = $_[0];
	$execfile = $_[1];
	print "$fileName\n";
	open (_LOGFILE, "$fileName") or die("Unable to open file");

	while ($line = <_LOGFILE>)
	{
		$line =~ s/\r/ /g;
		if ($line =~ m/function/)
		{
			@pstr = split(/ /,$line);
			$execline = "$ADDR2LINE -fse $execfile $pstr[1]";
			#print "$execline \n";
			#exec ($execline); 
			$result = `$execline`;
		       	chomp ($result);
			$result =~ s/\n/\t/;
			print "$result \n";
		}

		if ($line =~ m/^task 0x/)
		{
			@pstr = split(/ /,$line);
			$execline = "$ADDR2LINE -fse $execfile $pstr[4]";
			$result = `$execline`;
		       	chomp ($result);
			$result =~ s/\n/\t/;

			if ($pstr[1] eq "0x00000000")
			{
				$result1 = $pstr[1];
			}
			else
			{
				$execline = "$ADDR2LINE -fse $execfile $pstr[1]";
				$result1 = `$execline`;
		       		chomp ($result1);
				$result1 =~ s/\n/\t/;
			}
			print "$result1 posted by $result \t Ran For - $pstr[9]\n";
		}
	}
	close (_LOGFILE);
}


sub main ()
{
	FileContent ($ARGV[0], $ARGV[1]);	
}

eval { main ();}
