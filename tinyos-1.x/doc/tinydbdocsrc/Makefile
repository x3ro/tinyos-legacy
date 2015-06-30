
tinydb.pdf: tinydb.tex
	pdflatex tinydb.tex
	makeindex tinydb.idx
	makeindex tinydb.glo -s nomencl.ist -o tinydb.gls
	pdflatex tinydb.tex
	acroread tinydb.pdf

tinydb.ps: tinydb.dvi tinydb.tex
	dvips tinydb.dvi -f > tinydb.ps
	gv tinydb.ps

tinydb.dvi: tinydb.tex
	latex tinydb.tex
	makeindex tinydb.idx
	makeindex tinydb.glo -s nomencl.ist -o tinydb.gls
	latex tinydb.tex


tinydb.aux: tinydb.tex
	elatex tinydb.tex

tinydb.html : tinydb.aux tinydb.tex
	latex2html -split 1 -show_section_numbers -no_navigation tinydb.tex
	mozilla file:///home/madden/broken/dev/doc/tinydbdocsrc/tinydb/index.html

tinyschema.ps: tinyschema.dvi tinyschema.tex
	dvips tinyschema.dvi -f > tinyschema.ps

tinyschema.dvi: tinyschema.tex
	elatex tinyschema.tex

clean:
	rm tinydb.aux tinydb.glo tinydb.gls tinydb.idx tinydb.ilg tinydb.ind tinydb.log tinydb.dvi tinydb.pdf tinydb.ps
