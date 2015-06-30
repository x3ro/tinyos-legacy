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
open (OBJDUMP, "msp430-objdump -s -d -l $objfile |") || die "Can't run objdump on $objfile: $!";

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
    # rows are operand type, cols are opcode group
    # corresponds to table 3-15
    @fmt2tab =
    ([1, 3, 4],
	[3, 4, 4],
	[3, 4, 5],
	[0, 4, 5],
	[4, 5, 5],
	[4, 5, 5],
	[4, 5, 5]);

    # rows are src operand type, cols are dst operand type
    # corresponds to table 3-16
    @fmt1tab =
    ([1, 2, 4, 4, 4],
	[2, 3, 5, 5, 5],
	[2, 3, 5, 5, 5],
	[2, 3, 5, 5, 5],
	[3, 3, 6, 6, 6],
	[3, 3, 6, 6, 6],
	[3, 3, 6, 6, 6]);

    # Expansions of emulated instructions.
    %emulated = (
	'ret' => 'mov	@sp+,	pc',
	'adc' => 'addc	#0,	dst',
	'adc.b' => 'addc.b	#0,	dst',
	'clrc' => 'bic	#1,	sr',
	'clr' => 'mov	#0,	dst',
	'clr.b' => 'mov.b	#0,	dst',
	'decd' => 'sub	#2,	dst',
	'decd.b' => 'sub.b	#2,	dst',
	'inc' => 'add	#1,	dst',
	'inc.b' => 'add.b	#1,	dst',
	'incd' => 'add	#2,	dst',
	'incd.b' => 'add.b	#2,	dst',
	'inv' => 'xor	#0xffff,	dst',
	'inv.b' => 'xor.b	#0xff,	dst',
	'pop' => 'mov	@sp+,	dst',
	'rla' => 'add	dst,	dst',
	'rla.b' => 'add.b	dst,	dst',
	'rlc' => 'addc	dst,	dst',
	'rlc.b' => 'addc	dst,	dst',
    );

    # Takes a chunk of assembly code.  Assumes that it's a basic block. 
    # Uses the $cycles{$opcode} map to get total number of cycles for it.
    my($total) = 0;
    my($code) = shift;
    my(@lines) = split /\n/, $code;
    foreach $line (@lines) {
	next if($line =~ /^\s*$/ || $line =~ /\.\.\./);   # Skip empty lines
	@fields = split /\t/, $line;
	$opcode = $fields[2];
	$operand1 = $fields[3];
	$operand2 = $fields[4];

	# TODO add check back in
#	if(not defined $cycles{$opcode}) {
#	    print STDERR "code = '$code'";
#	    print STDERR "line = '$line'";
#	    print STDERR "Fields: ", join('/',@fields), "\n";
#	    print STDERR "opcode = '$opcode'\n";
#	    die "no mapping for '$opcode'";
#	}

	# Sometimes, the operands might be stuck together (no tab)
	@fakeOps = split /,/, $operand1;
	if ($fakeOps[1] ne '') {
		$operand1 = $fakeOps[0];
		$operand2 = $fakeOps[1];
		$fields[3] = $operand1;
		$fields[4] = $operand2;
	}

	# Remove trailing comma from operand1
	$operand1 =~ s/,$//;
	$operand2 =~ s/;.*$//;

	# Expand emulated instructions.
	if ($emulated{$opcode} ne '') {
	    my $expansion = $emulated{$opcode};
	    #print "Expanding $opcode\n";
	    $expansion =~ s/dst/$operand1/g;
	    push @lines, "\t\t$expansion";
#	    print join "\n", @lines;
	    next;
	}

	# Cycle calculation based on info from:
	# MSP430 User's Guide 2004
	# Section 3.4.4: Instruction Cycles and Lengths
	if ($opcode eq '' and $fields[1] =~ /^[\da-f]{2} 0[02]\s+$/) {
	    # This is a no-op, so skip it.
	    next;
	} elsif ($opcode eq '' and ($fields[1] =~ /^[\da-f]{2} [\da-f]{2}\s+$/
		or $fields[1] =~ /^\.\.\.\s*$/)) {
	    # TODO WHAT TO DO ABOUT THESE WEIRD THINGS?
	    next;
	} elsif ($opcode =~ /^\.word$/) {
	    # TODO WHAT TO DO ABOUT THESE WEIRD THINGS?
	    next;
	} elsif ($opcode =~ /^(jc|jge|jl|jmp|jn|jnc|jne|jnz|jz)$/) {
	    # Format-III instructions.
	    # All jumps require two cycles.
	    $count = 2;
	    #print "COUNT $count\n";
	} elsif ($operand1 ne '' and $operand2 ne '') {
	    # Format-I instructions.
	    $operand1Type = getOperand1Type($operand1, $code, $line, $fields);

	    $_ = $operand2;
	    if (/^(r\d+|sr|pc|sp)$/) {
		$operand2Type = 0;
	    } elsif (/^PC$/) {
		$operand2Type = 1;
	    } elsif (/^(-?0x(\d|[a-fA-F])+|-?\d+)\((r\d+|sr|pc|sp)\)$/) {
		$operand2Type = 2;
	    } elsif (/^(-?0x(\d|[a-fA-F])+|-?\d+)$/) {
		$operand2Type = 3;
	    } elsif (/^&(-?0x(\d|[a-fA-F])+|-?\d+)$/) {
		$operand2Type = 4;
	    } else {
		print STDERR "CODE\n$code";
		print STDERR "line = '$line'";
		print STDERR "FIELDS\n",join('/', @fields),"\n";
		die 'invalid operand 2 for format-I instruction';
	    }
	    $count = $fmt1tab[$operand1Type][$operand2Type];
	} elsif ($operand2 eq '') {
	    # Format-II instructions.
	    $operandType = getOperand1Type($operand1, $code, $line, $fields);

	    $_ = $opcode;
	    if (/^(rra|rra.b|rrc|rrc.b|swpb|sxt)$/) {
		$opcodeGroup = 0;
	    } elsif (/^push$/) {
		$opcodeGroup = 1;
	    } elsif (/^call$/) {
		$opcodeGroup = 2;
	    } else {
		print STDERR "CODE\n$code";
		print STDERR "LINE\n$line\n";
		die 'invalid opcode for format-II instruction.';
	    }

	    if ($operandType == 3 and $opcodeGroup == 0) {
		print STDERR "CODE\n$code";
		print STDERR "line = '$line'";
		die 'invalid opcode+operand for format-II instruction.' 
	    }

	    $count = $fmt2tab[$operandType][$opcodeGroup];

	    #print "OPERANDTYPE $operandType\tOPCODE $opcodeGroup\tCOUNT $count\n";
	} else {
	    print STDERR "CODE\n$code";
	    print STDERR "line = '$line'";
	    die 'unknown instruction format.';
	}

	#print "COUNT $count\tTOTAL $total\n";
	$total += $count;
    }
    return $total;
}

sub getOperand1Type {
    $operand = shift;
    $code = shift;
    $line = shift;
    $fields = shift;

    $_ = $operand;
    if (/^(r\d+|sr|pc|sp)$/) {
	$operandType = 0;
    } elsif (/^\@(r\d+|sr|pc|sp)$/) {
	$operandType = 1;
    } elsif (/^\@(r\d+|sr|pc|sp)\+$/) {
	$operandType = 2;
    } elsif (/^#(-?0x(\d|[a-fA-F])+|-?\d+)$/) {
	$operandType = 3;
    } elsif (/^(-?0x(\d|[a-fA-F])+|-?\d+)\((r\d+|sr|pc|sp)\)$/) {
	$operandType = 4;
    } elsif (/^(-?0x(\d|[a-fA-F])+|-?\d+)$/) {
	$operandType = 5;
    } elsif (/^&(-?0x(\d|[a-fA-F])+|-?\d+)$/) {
	$operandType = 6;
    } else {
	print STDERR "CODE\n$code";
	print STDERR "LINE\n$line\n";
	print STDERR "FIELDS\n",join('/', @fields),"\n";
	print STDERR "OPERAND1\n",$operand,"\n";
	die 'invalid operand-1 type'
    }

    return $operandType;
}
