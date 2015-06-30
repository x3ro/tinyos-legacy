
package SlurpFile;


sub slurp_file {
  my $file = shift;
  return "" unless defined($file);
  my $fh = create_anon_fh();
  open $fh, "< $file" or die "ERROR, module file $file, $!, aborting.\n";
  my $text = join("",<$fh>);
  close $fh;
  return $text;
}


sub dump_file {
  my $file = shift;
  my $text = shift;
  my $fh = create_anon_fh();
  open $fh, "> $file" or die "ERROR, writing file $file, $!, aborting.\n";
  print $fh $text;
  close $fh;
  1;
}


sub scrub_c_comments {
  my $text = shift;
  $text =~ s{/\*.*?\*/}{}gs;
  $text =~ s{//.*?\n}{}g;
  return $text;
}


sub create_anon_fh {
  local *FH;
  return *FH;
}


1;


