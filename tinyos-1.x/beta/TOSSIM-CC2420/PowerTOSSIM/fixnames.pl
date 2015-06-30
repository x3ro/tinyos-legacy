#!/usr/bin/perl -w

# Script to fix files... the automounter makes it nigh impossible to
# get canonical absolute pathnames, so we'll just strip out everything
# up to $USERNAME.

# Input lines of the format:
# number\tpath:number

# Output, same, except that the paths inside the home directory will
# all be of the form ~/blah/blah

use Cwd 'realpath';

$me = `whoami`;
chomp($me);

while(<>) {
    chomp();
    /^(\d+)\t([^:]*):(\d+)$/;
    ($bb, $file, $line) = ($1, $2, $3);
    if(/^\d+\t:-1/) {
	print "$_\n";
	next;
    }
    $path = realpath($file) || die "fixname.pl: realpath '$file' failed: $!\n";
    $path =~ s|/.*$me/|~/|;  # replace "/blah/blah/blah/username" with "~/"
    print "$bb\t$path:$line\n";
}
