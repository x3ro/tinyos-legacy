#!/usr/bin/perl

do "../tools.pm";

$sent = message($BROADCAST, 1, 42, 11);
send_base($sent);
$received = recv_app(1);

if ($sent ne $received) {
    print "APP received message different from BASE sent\n";
    print "sent: ";
    print_message($sent);
    print "\nreceived: ";
    print_message($received);
    print "\n";
    exit 2;
}

exit 0;
