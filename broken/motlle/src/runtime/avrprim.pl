# a perl script to generate the primargs and primfns arrays needed for
# primitives on the avr (these sit in the program memory)

$gcc = "$ARGV[0] -DPRIMGET -E";
shift;
foreach $file (@ARGV)
{
    next if !($file =~ /\.c$/);
    print STDERR "$file\n";

    die unless open(PRIMS, "$gcc $file|");

    while (<PRIMS>) {
	if (/RUNTIME_DEFINE\((.*), (.*), (.*)\)/) {
	    push @ops, "code_$2";
	    push @nargs, $3;
	}
    }
}

printf "#include \"mudlle.h\"\n";
printf "#include \"primitives.h\"\n";
foreach $op (@ops) {
    printf "value $op();\n";
}
printf "primfn_type primfns[] = {\n  %s\n};\n\n", join(",\n  ", @ops);
printf "primargs_type primargs[] = {\n  %s\n};\n", join(",\n  ", @nargs);
