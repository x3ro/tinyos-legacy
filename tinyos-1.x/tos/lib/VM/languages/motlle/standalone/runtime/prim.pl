# a perl script to generate the primargs and primops arrays needed for
# primitives on the standalone motlle

$gcc = "$ARGV[0] -DPRIMGET -E";
shift;
foreach $file (@ARGV)
{
    next if !($file =~ /\.c$/);
    print STDERR "$file\n";
    die unless open(PRIMS, "$gcc $file|");

    while (<PRIMS>) {
	if (/RUNTIME_DEFINE *\( *(.*) *, *([a-zA-Z_0-9]*) *, *(.*) *\)/) {
	    $name = $2;
	    push @ops, "op_$2";
	    push @nargs, $3;
	}
	if (/GLOBALS *\((.*)\)/) {
	    push @initialisers, "$1_init";
	}
    }
}

foreach $op (@ops) 
{
    printf "extern struct primitive_ext $op;\n";
    push @addr_of_ops, "&$op";
}
printf "struct primitive_ext *primops[] = {\n  %s\n};\n\n", join(",\n  ", @addr_of_ops);

printf "#ifndef STANDALONE\n";
foreach $init (@initialisers) 
{
    printf "void $init(void);\n";
}
printf "void (*global_initialisers[])(void) = {\n  %s\n};\n\n", join(",\n  ", @initialisers);
printf "#endif\n";

