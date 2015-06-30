parseschema : y.tab.c
	gcc y.tab.c -lfl -o parseschema

y.tab.c : lex.yy.c parseschema.yacc
	bison -y parseschema.yacc -o y.tab.c

lex.yy.c : parseschema.lex
	flex -olex.yy.c parseschema.lex 

clean:
	rm -f y.tab.c lex.yy.c parseschema
