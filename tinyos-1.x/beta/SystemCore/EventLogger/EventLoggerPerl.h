#ifndef __EVENTLOGGERPERL_H__
#define __EVENTLOGGERPERL_H__

<perl>
sub snms_tag {
  my %arg = @_;
  my $command = $arg{text};
  $command =~ m/(.*)logEvent\((.*)\)/s;
  my $storeVar = $1;
  my $arglist = $2;
  $arglist =~ m/(".*")/;
  my $schemaString = $1;
  $arglist =~ s/\".*\"//g;

  my @commandArgs = split(/\s*,\s*/, $arglist);

  if (!defined($main::schemaKey)) {
    $main::schemaKey = 0;
  }

  if (!defined($main::schemaStr)) {
    $main::schemaStr = "";
  }

  $main::schemaStr .= "$main::schemaKey\t$schemaString\n";
  shift(@commandArgs);
 
  my $commandArg;
  my $pushStr;
  foreach $commandArg (@commandArgs) {
    chomp $commandArg;
    $pushStr .= "          call EventLogger.push(buf, (uint8_t*)&$commandArg, sizeof($commandArg));\n"; 
  }

  print <<EOT;
#ifndef PLATFORM_PC
      {
	LogEntryMsg *buf = call EventLogger.getBuffer();
	if (buf != NULL) {
$pushStr
  $storeVar call EventLogger.logBuffer($main::schemaKey);

EOT

  if ($storeVar =~ /\S/) {
    print "} else {\n";
    print "$storeVar FAIL;\n";
  } 

 print <<EOT;
	}
	}
#endif

EOT
  $main::schemaKey++;

  1;
}
$file->{tags}->add_tag("snms",\&snms_tag);

sub save_schema {
  my ($pnc) = @_;
  $pnc->save_file( "event_schema.txt", $main::schemaStr );
}

$file->post_accounting( sub { save_schema($file) } );
</perl>

#endif
