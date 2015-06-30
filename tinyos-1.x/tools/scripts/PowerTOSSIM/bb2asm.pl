#!/usr/bin/perl

# A script to generate basic block->asm statement mappings

# Input: 
# --- The basepath of local files (at the moment, the compiler is 
#     spitting out relative paths, while the debugging info has full 
#     names)
# --- cycle counts for each instruction type
# --- A BB dump 
# --- The object file with debug symbols

# The bb_linenum_map lines look like:
#1       $TOSDIR/platform/pc/external_comm.c:228
#2       $TOSDIR/platform/pc/Nido.nc:115
# ....

# The cycle count file looks like:
# cls\t1
# sbi\t2
# brid\t1.5
#  So fractional values are allowed (for instructions which can take
#  varying numbers of cycles)

# Output: A file with BB number\tAVR cycle count pairs 
# Line format: 'bb#\tcycle_count\n'
# Won't output a line if there isn't any info for it.

use Cwd 'realpath';

# Debugging flags
$DBG_OBJDUMP = 0;
$DBG_BBDUMP = 0;
$DBG_BB_CODE_MAP = 0;
$DBG_MAP_COMPUTE = 0;

$usage = 
    "Usage: bb2asm.pl basepath cycle_counts bb_linenum_map main.exe bb_cycle_map\n".
    "       basepath - path to add to start of relative filenames\n".
    "       cycle_counts - file with instruction->number of cycles map\n".
    "       bb_linenum_map - the basic block->line number mappings\n".
    "       main.exe - the mica2 assembly, with debugging symbols\n".
    "       bb_cycle_map - the output: a map of BB# -> AVR cycles\n\n";

die $usage if(scalar @ARGV != 5);

$basepath = shift @ARGV;
$cycle_counts = shift @ARGV;
$bb_dump = shift @ARGV;
$objfile = shift @ARGV;
$bb_cycle_map = shift @ARGV;

$me = `whoami`;
chomp($me);


# Do some checks
if($basepath =~ m|^[^/]|) {
    die "Basepath must start with '/'\n" . $usage;
}

# Remove any trailing '/'
$basepath =~ s|/$||;

open (CYCLE_COUNTS, $cycle_counts) || die "Can't open $cycle_counts: $!";

while(<CYCLE_COUNTS>) {
    chomp;
    ($opcode, $ncycles) = split /\t/;
    $cycles{$opcode} = $ncycles;
}

close CYCLE_COUNTS;

# File must be compiled with -g for this to work!!!
open (OBJDUMP, "avr-objdump -d -l $objfile |") || die "Can't run objdump on $objfile: $!";

while(<OBJDUMP>) {
    chomp();
    if(/^\//) {
	($cur_file, $cur_line) = split /:/, $_;
	# Get a canonical name out of this filename
	unless ($path = realpath($cur_file)) {
	    warn "realpath '$cur_file' failed: $!\n";
	    $path = $cur_file;  # just use the current path
	}
	$path =~ s|/.*$me/|~/|;  # replace "/blah/blah/blah/username" with "~/"
	$cur_file = $path;
    } elsif( /^\s*$/ ) {
	$cur_line = "";
    } elsif($cur_line ne "") {
	$asm{$cur_file}{$cur_line} .= "$_\n";
    }
}

close OBJDUMP;

open (BBDUMP, $bb_dump) || die "Can't open $bb_dump: $!";

while(<BBDUMP>) {
    chomp();
    /^(\d+)\t([^:]*):(\d+)$/;
    ($bb, $file, $line) = ($1, $2, $3);
    if($file =~ m|^[^/]| && $file !~ m|^\~|) {
	die "This shouldn't happen!\n";
	# Filename does not start with '/' or '~', so add the basepath
	$file = $basepath . "/" . $file;
    }
    $bbinfo{$bb} = { "file" => $file, 
		     "line" => $line,
		     "code" => "" };
    $revmap{$file}{$line} = $bb;
}

close BBDUMP;

if($DBG_OBJDUMP) {
    print "Line -> ASM mappings\n";
    print "--------------------\n\n";
	
    foreach $f (sort keys %asm) {
	foreach $l (sort {$a <=> $b} keys %{$asm{$f}}) {
	    print "$f, $l\n";
	    print $asm{$f}{$l};
	    print "--------------------------\n\n";
	}
    }
}


if($DBG_BBDUMP) {
    print "BB->file,line mappings\n";
    foreach $bb (sort {$a <=> $b} keys %bbinfo) {
	print $bb, ",", $bbinfo{$bb}{"file"}, ":",$bbinfo{$bb}{"line"},"\n";
    }
    print "--------------------------\n\n";
    print "Reverse ( [file, line]->bb ) mappings\n";
    foreach $f (sort keys %revmap) {
	print "$f: ";
	foreach $l (sort {$a <=> $b} keys %{$revmap{$f}}) {
	    print "($l,", $revmap{$f}{$l},") ";
	}
	print "\n";
    }
}



foreach $f (sort keys %revmap) {
    print "file = $f\n" if $DBG_MAP_COMPUTE;

    @bb_lines = sort {$a <=> $b} keys %{$revmap{$f}};
    @asm_lines = sort {$a <=> $b} keys %{$asm{$f}};
    
    print "bb_lines = ", join(" ", @bb_lines), "\n" if $DBG_MAP_COMPUTE;
    print "asm_lines = ", join(" ", @asm_lines), "\n" if $DBG_MAP_COMPUTE;
    next if scalar(@asm_lines) == 0;
    # Now go through and find the asm_lines that go with each
    # bb_line
    while($cur_bb_line = shift @bb_lines) {
	print "bb_line = $cur_bb_line\n" if $DBG_MAP_COMPUTE;
	# Get rid of any lines that aren't in a basic block
	# This probably won't happen at all, but might at the start of 
	# a file
	print "asm_line = '".$asm_lines[0]."'\n" if $DBG_MAP_COMPUTE;

	while(defined($asm_lines[0]) && ($asm_lines[0] < $cur_bb_line)) {
	    shift @asm_lines;
	}
	if($bb_lines[0]) {
	    # Get all the lines till the next BB
	    while(defined($asm_lines[0]) &&
		  defined($bb_lines[0]) &&
		  ($asm_lines[0] < $bb_lines[0]) ) {
		$bb = $revmap{$f}{$cur_bb_line};
		$bbinfo{$bb}{"code"} .= $asm{$f}{$asm_lines[0]};
		shift @asm_lines;
	    }
	} else {
	    # Last BB in the file, so get all the remaining lines
	    while(@asm_lines) {
		$bb = $revmap{$f}{$cur_bb_line};
		$bbinfo{$bb}{"code"} .= $asm{$f}{$asm_lines[0]};
		shift @asm_lines;
	    }
	}
    }
}


if($DBG_BB_CODE_MAP) {
    print "\n\nBB->Code map\n";
    print "-------------------\n\n";

    foreach $bb (sort {$a <=> $b} keys %bbinfo) {
	print $bb, ",", $bbinfo{$bb}{"file"},":", $bbinfo{$bb}{"line"},"\n";
	$code = $bbinfo{$bb}{"code"};
	print $code;
	print "Num cycles: ", &code_cycles($code), "\n";
	
	print "-----------------\n\n";
    }
}

open(OUTPUT, ">$bb_cycle_map") || die "Can't open $bb_cycle_map: $!";

foreach $bb (sort {$a <=> $b} keys %bbinfo) {
    $code = $bbinfo{$bb}{"code"};
    $cycles = &code_cycles($code);
    print OUTPUT "$bb\t$cycles\n" unless ($cycles == 0);
}

close(OUTPUT) || die "Can't close $bb_cycle_map: $!";


sub code_cycles {
    # Takes a chunk of assembly code.  Assumes that it's a basic block. 
    # Uses the $cycles{$opcode} map to get total number of cycles for it.
    my($total) = 0;
    my($code) = shift;
    my(@lines) = split /\n/, $code;
    foreach $line (@lines) {
	next if($line =~ /^\s*$/);   # Skip empty lines
	@fields = split /\t/, $line;
	$opcode = $fields[2];
	if(defined $cycles{$opcode}) {
	    $total += $cycles{$opcode};
	} else {
	    print STDERR "code = '$code'";
	    print STDERR "line = '$line'";
	    print STDERR "Fields: ", join('/',@fields), "\n";
	    print STDERR "opcode = '$opcode'\n";
	    die "no mapping for '$opcode'";
	}
	    
    }
    return $total;
}
