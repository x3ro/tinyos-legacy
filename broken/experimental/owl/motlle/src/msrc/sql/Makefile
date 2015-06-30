foo: lex.mll parse.mly sql.mli sqlgen.ml
	ocamlyacc parse.mly
	ocamllex lex.mll
	ocamlc -o foo sql.mli parse.mli parse.ml lex.ml sqlgen.ml

t1: foo
	echo SELECT id, parent, temp INTERVAL 60 | ./foo


t2: foo
	echo 'SELECT id, parent, light WHERE temp < light and light < 20 INTERVAL 60' | ./foo

t2a: foo
	echo 'SELECT id, parent, light WHERE temp < light and light >= 20 INTERVAL 60' | ./foo


t3: foo
	echo 'SELECT id, parent, expdecay(light, 14) INTERVAL 60' | ./foo

t4: foo
	echo 'SELECT avg[temp] INTERVAL 60' | ./foo

t5: foo
	echo 'SELECT avg[light] WHERE 20 < temp INTERVAL 60' | ./foo


queries:
	@make -s t1 >q1.mud
	@echo 'SELECT id, expdecay(temp, 14) WHERE humidity > 920 INTERVAL 60' | ./foo >q2.mud
	@make -s t4 > q3.mud