#!/usr/bin/perl

do "../tools.pm";

$sent = message($BROADCAST, 1, 42, 12);

send_app($sent);
$received = recv_base(1);

if ($sent ne $received) {
    print "BASE received message different from APP sent\n";
    print "sent: ";
    print_message($sent);
    print "\nreceived: ";
    print_message($received);
    print "\n";
    exit 2;
}

exit 0;
