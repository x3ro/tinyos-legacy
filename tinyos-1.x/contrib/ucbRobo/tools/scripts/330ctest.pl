#!/usr/bin/perl -w
use IPC::Open2;

#use strict;

my @motelist;
my $numargs;
my $line;
my @line;
my $motefile = '/opt/tinyos-1.x/contrib/testbed/testbed/cory330-testbed-simple.cfg';
my $command;
my $i;
my $nummotes;
my $pgrp;
my $pid;
my @pids;
my $name;

$|= 1;
$SIG{CHLD} = 'IGNORE';

open (MOTES, "$motefile") or die "cannot open motefile: $!";

foreach $line (<MOTES>) {
    if ($line =~ m/^mote/) {
	@line = split "\t", $line;
	push @motelist, { addr => $line[2], id => $line[1]};
    }
}

$numargs = @ARGV;
if ($numargs > 0) {
    $command = shift;
    if ($command =~ m/r/) {
	refresh_tosbase();
    }
}

$nummotes = @motelist;
#$nummotes = 1;
print "number of motes attached: $nummotes \n";

for ($i = 0; $i < $nummotes; $i++) {
    $command = "echo -n '>' > 330tests/data$i";
    `$command`;
    `date +%s >> 330tests/data$i`;
    $command = "echo -n '>' >> 330tests/data$i";
    `$command`;
    $command = "java net.tinyos.tools.ListenPrompt network\@" . $motelist[$i]->{'addr'} . ":10002 >> 330tests/data$i";
    
    open2 ('TX' . $i, 'DATA' . $i, $command) or die ("cannot open data file: $!");
}

while (<>) {
    if ($_ =~ m/quit/i) {
	print "QUITING\n";
	for ($i = 0; $i < $nummotes; $i++) {
	    $name = 'DATA' . $i;
	    print $name $_ . "\n";
	    close 'DATA' . $i or die ("cannot close DATA0: $!");
	}
	$pgrp = getpgrp $$;
	kill -9,$pgrp;
    } elsif ($_ =~ m/move/) {
	print "MOVING FILES\n";
	@args = split " ", $_;
	for ($i = 0; $i < $nummotes; $i++) {
	    $command = "bash -c \'cp 330tests/data{$i,$i." . $args[1] . '}\';';
	    `$command`;
	    # looks like backticks don't return the exit status.  i need to find another way to check errors...
	    #$command = "echo > 330tests/data$i;";
	    $command = "echo -n '>' > 330tests/data$i";
	    `$command`;
	    $command = "date +%s >> 330tests/data$i";
	    `$command`;
	    $command = "echo -n '>' >> 330tests/data$i";
	    `$command`;
	    $command = "echo " . $motelist[$i]->{'addr'} . " >> 330tests/data$i";
	    `$command`;
	}
    } else {
	print "SENDING COMMAND\n";
	for ($i = 0; $i < $nummotes; $i++) {
	    $name = 'DATA' . $i;
	    print $name $_ . "\n";
	}
    }
}
