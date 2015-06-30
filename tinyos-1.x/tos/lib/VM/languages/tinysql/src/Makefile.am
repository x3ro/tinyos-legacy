AUTOMAKE_OPTIONS = foreign

bin_PROGRAMS = tinysqlcc$(EXEEXT)

bin_SCRIPTS = tinysql

tinysqlcc$(EXEEXT): lex.mll parse.mly sql.mli sqlgen.ml
	ocamlyacc parse.mly
	ocamllex lex.mll
	ocamlc -o $@ sql.mli parse.mli parse.ml lex.ml sqlgen.ml
