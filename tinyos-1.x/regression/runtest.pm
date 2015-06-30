sub runtests {
    my ($test) = @_;

    die "Can't create output directory for $test" unless mkdir("output/$test");

    die "Can't enter test directory $test" unless chdir($test);

    if (runsingletest($test, "app")) {
	while (<*.tst>) {
	    system("../reset") == 0 || die "./reset doesn't work";
	    sleep 4; # radio may take a while to learn the noise floor
	    runsingletest($test, $_);
	}
    }

    die ".. missing" unless chdir("..");
}

sub runsingletest {
    my ($test, $subtest) = @_;

    print "running $test:$subtest\n";
    $exitcode = system("./$subtest >../output/$test/$subtest 2>&1");

    if (($exitcode & 0xff) == 0) {
	$exitcode >>= 8;
    }
    else {
	$exitcode = 2;
    }

    if ($exitcode == 1) {
	$status = "SKIP";
    }
    elsif ($exitcode == 0) {
	$status = "PASS";
    }
    else {
	$status = "FAIL";
	push @failed, "$test:$subtest";
    }

    print "  $status\n";

    return $exitcode == 0;
}
