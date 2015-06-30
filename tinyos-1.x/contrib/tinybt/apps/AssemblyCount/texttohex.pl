#!/usr/bin/perl -w

# Program to take a string as argument and convert it to ascii hex values.

$arg = shift(@ARGV);
if (!defined $arg || "" eq $arg) {
    $arg = "Hello World!";
}

foreach $letter (split("", $arg)) {
    printf ("0x%0x ", ord($letter));
}
