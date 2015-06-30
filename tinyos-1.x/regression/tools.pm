#!/usr/bin/perl

use Socket;

$BROADCAST = 0xffff;

$APP_PORT = 9011;
$BASE_PORT = 9012;

r_connect(APP, BASE) unless $dontconnect;

sub r_connect {
    my ($app, $base) = @_;

    sf_connect($app, "localhost", $APP_PORT);
    sf_connect($base, "localhost", $BASE_PORT);
}

sub r_close {
    close(APP);
    close(BASE);
}

sub send_base { sf_send(BASE, $_[0]); }
sub send_app { sf_send(APP, $_[0]); }
sub recv_base { return sf_recv(BASE, $_[0]); }
sub recv_app { return sf_recv(APP, $_[0]); }

# Build a TOSMsg in a perl string
sub message {
    my ($dest, $amid, @data) = @_;
    my ($msg);

    return pack "vCCCC*", $dest, $amid, 0, $#data + 1, @data;
}

sub unpack_message {
    my ($msg) = @_;

    return unpack "vCCCC*", $msg;
}

sub print_message {
    my ($msg) = @_;

    for ($i = 0; $i < length $msg; $i++) {
	printf "%02x ", ord(substr($msg, $i, 1));
    }
}
    

# Connect to a serial forwarder
sub sf_connect {
    my ($handle, $host, $port) = @_;
    my ($lhost, $ptcp);

    $lhost = inet_aton($host) || die "can't lookup $host";
    $ptcp = getprotobyname("tcp");
    socket($handle, PF_INET, SOCK_STREAM, $ptcp) || die "SF socket";
    connect($handle, sockaddr_in($port, $lhost)) || die "No serial forwarder at $host:$port";
    # Send identifying string ('T', ' ' for original version)
    sf_write($handle, "T ");
    $s = sf_read($handle, 2);
    die "Not a serial forwarder at $host:$port" unless
	substr($s, 0, 1) eq "T" && ord(substr($s, 1)) >= 32;
}

# Start a serial forwarder
sub sf_start {
    my ($port, $comm) = @_;

    $pid = fork();
    die "can't fork" unless defined($pid);

    return $pid if $pid;

    exec "java net.tinyos.sf.SerialForwarder -comm $comm -port $port";
    die "couldn't start serial forwarder";
}

# Wait for a serial forwarder to start
sub sf_wait {
    my ($host, $port) = @_;
    my ($lhost, $ptcp);

    $lhost = inet_aton($host) || die "can't lookup $host";
    $ptcp = getprotobyname("tcp");
    socket(TEMP, PF_INET, SOCK_STREAM, $ptcp) || die "SF socket";
    $sin = sockaddr_in($port, $lhost);

    for ($tries = 0; $tries < 20; $tries++) {
	$sin = sockaddr_in($port, $lhost);
	if (connect(TEMP, $sin)) {
	    close(TEMP);
	    return;
	}
	sleep 1;
    }
    die "serial forwarder at $host:$port didn't show up\n";
}

# Write a string to a handle, abort on error
sub sf_write {
    my ($handle, $string) = @_;

    while ($string ne "") {
	$cnt = syswrite($handle, $string);
	if (!$cnt) {
	    print "write error $! $cnt\n";
	    exit 2;
	}
	$string = substr($string, $cnt);
    }
}

# Read n bytes from a handle, abort on error and timeout
sub sf_read {
    my ($handle, $n, $timeout) = @_;
    my ($s, $offset, $rin);

    $offset = 0;
    vec($rin, fileno($handle), 1) = 1;
    while ($offset < $n) {
	$cnt = select($rin, undef, undef, $timeout);
	if (!$cnt) {
	    print "read error: timeout\n";
	    exit 2;
	}
	$cnt = sysread $handle, $s, $n, $offset;
	if (!$cnt) {
	    print "read error $cnt $!\n";
	    exit 2;
	}
	$offset += $cnt;
    }
    return $s;
}

# Send a packet to a serial forwarder
sub sf_send {
    my ($handle, $msg) = @_;

    $msg = chr(length $msg) . $msg;
    sf_write($handle, $msg);
}

# Receive a packet from a serial forwarder
sub sf_recv {
    my ($handle, $timeout) = @_;
    my ($s);

    $len = ord(sf_read($handle, 1, $timeout));
    $s = sf_read($handle, $len, $timeout);

    # Set group id to 0 to simplify life
    substr($s, 3, 1) = chr(0);

    return $s;
}

