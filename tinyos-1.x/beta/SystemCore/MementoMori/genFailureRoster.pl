#!/usr/bin/perl -w

use DBI;
use strict;
use POSIX qw(ceil floor);

# database information
my $db="auth";
#my $host="mist.csail.mit.edu";
my $host="127.0.0.1";
my $port="3306";
my $userid="stanrost";
my $passwd="stanr";
my $connectionInfo="DBI:mysql:database=$db;$host:$port";
my $exptTable = $ARGV[0];

#if (scalar @ARGV != 1) {
#    print "Usage: ./genFailureRoster.pl <name of the experiment file>\n";
#    exit;
#}

open(OUTF, ">failureSched.h");

print OUTF "#define TIME_OUT_SCHED \\\n";

# make connection to database
my $dbh = DBI->connect($connectionInfo,$userid,$passwd);

my $query = "select moteid from motes where active != 0 and platform != 'cricket'";

my $sth = $dbh->prepare($query);

$sth->execute();

my @res;

while (@res = $sth->fetchrow()) {
    print OUTF "{$res[0], 0xFFFF}, \\\n";
}

# disconnect from database
$dbh->disconnect;

print OUTF "{ 0xFFFF, 0xFFFF }\n";

close(OUTF);
