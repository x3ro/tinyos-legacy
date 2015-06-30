#! /usr/bin/env perl

# This program receives an enviroment setting and an an file encoded
# as if it were posted from a form. It then contacts the windows
# server to compile it, and return the tar.gz file from there.

################################################################################
# Use stuff

use strict;
use warnings;
use CGI;
#use CGI::Carp qw(fatalsToBrowser); 
use Net::SSH::Perl;

################################################################################
# Configuration
my $compile_host = "amigos18.diku.dk";
my $compile_user = "compile";
my $fake_home    = "/home/distlab/TestbedApacheHome/";

my $debug = 0;


################################################################################
#
# Error function - uses global query
my $query;
sub my_error() {
    my $error = shift(@_);
    print $query->header(-status=>400, 
			 -exit_code => 254,
			 -tar_code => 1,
			 -type  =>  'text/plain'),
    $error."\n";
#    print $query->header(-status=>400),
#    $query->start_html('Problems'),
#    $query->h2('Request not processed'),
#    $query->strong($error."\n"),
#    $query->end_html;
    exit 0;
}


################################################################################
#
# Startup

# Let the output be autoflushed
$| = 1;

# For debug: Redirect stderr to stdout:
if ($debug) {
    open(STDERR, ">&STDOUT");
}

# Get the query handle
$query = new CGI;

if ($debug) {
    print $query->header(-status=>200,
			 -tar_code => 1,
			 -type => 'text/plain'),
    # $query->start_html('Debug');
}

# Test for errors in CGI module before decoding stuff
my $error = $query->cgi_error;
if ($error) {
    &my_error($error);
}

################################################################################
# 
# Test the input

# We need two fields: ENVIRONMENT and app_c
my $environment = $query->param('ENVIRONMENT');
if (!defined $environment || $environment eq "") {
    &my_error("Malformed request, missing environment");
}

# Test the filename
my $filehandle = $query->upload('app_c');
if (!defined $filehandle) { 
    &my_error("Malformed request, missing file");
}
binmode $filehandle;

################################################################################
#
# Got a valid filehandle - use ssh to compile this file.

# This module seems to need a special home - perhaps we could use ssh options.
# The id_dsa key must be present in this fake home.
$ENV{"HOME"} = $fake_home;

if ($debug) {
    print STDOUT "Ready to setup connection\n";
}
# Set up the SSH connection
my $ssh;
eval '$ssh = Net::SSH::Perl->new($compile_host,
			      debug => $debug,
			      protocol => 2,
			      compression => 1,
		 	      options => [ "LogLevel DEBUG3", 
					   "ConnectionAttempts 2",
					   "StrictHostKeyChecking yes",
					   "BatchMode yes", 
					   "RhostsAuthentication no",
					   "PasswordAuthentication no",
					   "PreferredAuthentications publickey" ]);';
if( $@ ) 
{ 
    &my_error("Error connecting to compile service");
} 
if (!defined $ssh) {
    &my_error("Error connecting to compile service (2)");
}

if ($debug) {
    print STDOUT "Ready to login\n";
}
# Open it
$ssh->login($compile_user);

if ($debug) {
    print STDOUT "Setting up input\n";
}

# Prepare stdin for the ssh program
my $stdin = "ENVIRONMENT = $environment\n";
while (<$filehandle>) {
    $stdin .= $_;
}
close($filehandle);
$stdin .= "\nDONE_WE_ARE_YAYAYA_PSDKLKLQWELINXJBBSKTGRE\n";

if ($debug) {
    print STDOUT "Ready to run command\n";
}

############################################################
# Run the command
#

my ($out, $err, $exit) 
    = $ssh->cmd("/home/tinyos/contrib/diku/evb13192/addtools/compile_server.pl", $stdin);

################################################################################
# Return a result

# Note, that we always return a result. We put the exitcode in a
# special header though

my $length = bytes::length($out);

print $query->header(-type  =>  'application/x-tar',
		     -tar_code => 0,
		     -exit_code => $exit,
		     -content_encoding  =>  'x-gzip',
		     -content_length => $length);
print STDOUT $out;
exit 0;

