#! /usr/bin/env perl

# Script to provide a "compile service" for an TinyOS app.c file
# prepared for the MetroWerks CodeWarrior compiler, into binary files
# (and their s19 representation).

# The program accepts no parameters, but assumes input on stdin of the
# following format:

# ENVIRONMENT=<environment>
# first line of app.c
# second line of app.c
# ...
# last line of app.c

# If the app.c file is more than approx. 512 KB, the program aborts.

# These are the exit codes of the program:
# 0 - no error
# 64 - timeout waiting for input.
# 65 - protocol error
# 66 - app.c too big
# 67 - Internal error: Unable to write to filesystem
# 68 - Unable to run compiler (will return compiler/make error = 2)
# 69 - Timeout while waiting for compiler
# 70 - Timeout while waiting for tar
# others are error codes as returned by the make program

# In case of no errors, the program returns a tar.gz file on
# stdout. In case of errors, this may be the case (TODO: describe when)

# TODO: The "tell" check does not work!
# TODO: I am not sure assigning to $! is always good enough...
# TODO: One will have to trap SIGPIPE oneself.....

################################################################################
#
# Uses

use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use IPC::Open3;
use POSIX ":sys_wait_h";

################################################################################
#
# Configuration

# This program uses the configuration hardcoded in here. Change it to change
# paths, etc, that the program uses.

$ENV{"CWPATH"}             = "c:/Program Files/Metrowerks/CW08 V3.1/";
$ENV{"TINYOS_EVB13192DIR"} = "/home/tinyos/contrib/diku/evb13192"; 
$ENV{"FREESCALE_LIBDIR"}   = "/home/tinyos/contrib/diku/evb13192/lib ";
#C:/cygwin/home/ADMINI~1/SMAC/SMAC4_~1/CW_IDE~2/smac/bin/";

# TODO: Set more env depending on the evb _we_ read.

my @cmd = qw(make -f /home/tinyos/contrib/diku/evb13192/tools/make/hcs08/MakeHCS08 app.s19);

my $debug = 1;

################################################################################

# Overall program structure:

# Validate input
# Create temporary directory
# Write app.c file to temporary directory
# Call make with appropriate environment
# Tar and compress the directory contents
# Read and return the tar file
# Return appropiate exit code


################################################################################

# Acutal program

# First, to make sure no Windows hickups, use binmode on STDIN and STDOUT
binmode STDIN;
binmode STDOUT;
binmode STDERR;

############################################################
#
# Handle input

# Make sure we do not wait forever for this input.

local $SIG{ALRM} = sub { 
    $!= 64 ;
    die "Timeout waiting for input";
    # Not absolutely sure this is needed:
    exit 64;
};
alarm (60);

my $first = 1; 
my $app_c = "";
while(<>) {
    # Check for the ENVIRONMENT header in the first line
    if (1 == $first) {
	if (m/^ENVIRONMENT\s*=\s*(\w*)\s$/) {
	    print STDERR "Info: Got ENVIRONMENT = $1\n" if $debug;
	    $ENV{"ENVIRONMENT"} = $1;
	} else {
	    $! = 65;
	    die "Protocol error";
	}
	$first = 0;
	next;
    }

    # Check for last line marker (needed because Net::SSH::Perl is borken
    if (m/^DONE_WE_ARE_YAYAYA_PSDKLKLQWELINXJBBSKTGRE$/) {
	last;
    }
    
    # Check for size
    if (tell(STDIN) > 512000) {
	$! = 66;
	die "Input out of bounds";
    }
    
    # This is the app.c file I reckon
    $app_c .= $_;
}

# No need for timeout now.
local $SIG{ALRM} = sub { };

############################################################
#
# Setup for make

# Create a temporary directory for us to compile in, make sure we
# cleanup on exit
my $dir = tempdir( CLEANUP => 1 );
$! = 67;
chdir($dir) 
    || die "Internal error: Unable to change to temporary directory";
print STDERR "Info: Temporary directory created at $dir\n" if $debug;

# Write app.c to this directory
$! = 67;
open(OUTPUT, ">$dir/app.c") 
    || die "Internal error: Unable to write app.c to filesystem";
print OUTPUT $app_c;
close(OUTPUT);

############################################################
#
# Call make and friends
# TODO: Set up environment

# Get some handles - we bundle stderr and stdout for the kiddie
$! = 67;
open(KIDOUTPUT, ">$dir/OUTPUT")
    || die "Internal error: Unable to write OUTPUT to filesystem";
# Setup a NULL stdin file
my $null_file = ($^O =~ /Win/) ? 'nul': '/dev/null';   
open(KIDINPUT, $null_file)
    || die "Internal error: Unable to open NULL file";

# Actually run the command
print STDERR "Info: Running @cmd\n" if $debug;
$! = 68;
my $proc_id 
    = open3("<&KIDINPUT", ">&KIDOUTPUT", ">&KIDOUTPUT", @cmd)
    || die "Unable to run @cmd";
# Close the handles from here
close(KIDOUTPUT);
close(KIDINPUT);

# Now, wait for the kid, with a timeout of 5 seconds.
my $alarm = 0;
local $SIG{ALRM} = sub { $alarm=1; };
alarm (5);

# Wait for it
my $reaped;
do {
    # Sleep 250 ms.
    select(undef, undef, undef, 0.25);
    # sleep 1;	
    $reaped = waitpid( $proc_id, &WNOHANG);
} until ($reaped == $proc_id or $alarm == 1);

# Check if the child had a wrong exit code - we save this for later
my $child_error = $? >> 8;

# Check if we timed out
if($alarm) {
    kill "KILL", $proc_id;
    $! = 69;
    die "Timeout while waiting for compiler";
}


# OK, we should be ready, wrap it in a tar.gz file

################################################################################
# 
# Wrap in tar file

# First, set the permissions a bit more sensible
chmod 0644, glob("*");

# Tar needs a file to write to, or someone to read from stdout, which
# we do not do.
my $tmp_file = new File::Temp(); # Will be deleted automatically.
my $tmp_file_name = $tmp_file->filename;

open(KIDINPUT, $null_file)
    || die "Internal error: Unable to open NULL file (2)";

@cmd = "tar -zcf $tmp_file_name *";

# Actually run the command
print STDERR "Info: Running @cmd\n" if $debug;
my($tar_stdout, $tar_stderr);
$proc_id 
    = open3("<&KIDINPUT", $tar_stdout, $tar_stderr, @cmd) 
    || die "Unable to run @cmd"; 

# Now, wait for the kid, with a timeout of 5 seconds.
$alarm = 0;
alarm (5);

# Wait for it
do {
    # Sleep 250 ms.
    select(undef, undef, undef, 0.25);
    # sleep 1;	
    $reaped = waitpid( $proc_id, &WNOHANG);
} until ($reaped == $proc_id or $alarm == 1);

# Check if we timed out
if($alarm) {
    kill "KILL", $proc_id;
    $! = 70;
    die "Timeout while waiting for tar";
}
my $tar_error = $? >> 8;

############################################################

# Actually dump the tar file:
while(<$tmp_file>) {
    print STDOUT $_;
}
binmode STDOUT; #Should flush stdout

# Return an errorcode if neccesary
if ($child_error != 0) {
    $! = $child_error;
    die "Error running compiler";
}
if ($tar_error != 0) {
    while(<$tar_stderr>) {
	print STDERR $_;
    }
    binmode STDERR;
    $! = $tar_error;
    die "Error running tar";
}

# Happy program ends up here.
exit 0;
