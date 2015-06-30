#!/usr/bin/perl

print "Task Lister\n";
print "Until we have \"ps\", we might as well have this.\n";
print "\n";

if (scalar(@ARGV) == 0) {
    print "usage: taskCount.pl <platform>";
    exit;
}

$platform = $ARGV[0];

open(APP, "build/$platform/app.c") or die "Failed to open build/$platform/app.c";

open(EXE, "objdump -x build/$platform/main.exe |") or die "Failed to run objdump build/$platform/main.exe";


foreach $line (<APP>) {
    if ($line =~ /TOS_post/ && !($line =~ /void/)) {
#	print $line;
	$line =~ s/^.*TOS_post\((.*?)\).*/$1/;
	chomp($line);
	$tasks{$line} = 1;
    }
}

foreach $line (<EXE>) {
    if ( $line =~ /^(\S+).+? \.text\s+\S+ (\S+)/ ) {
#	print $line;
	($addr, $symbol) = ($1, $2);
	$symtab{$symbol} = hex $addr;
#	print "$addr $symbol\n";
    }
}

print "Addr\tName\n";
foreach $task (sort keys %tasks) {
    $dotTask = $task;
    $dotTask =~ s/\$/./;
    printf("0x%x\t%s\n", $symtab{$task}, $dotTask);
    $taskCount++;
}
print "\n$taskCount tasks\n";

