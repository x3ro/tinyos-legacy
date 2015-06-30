tinydb.ps: tinydb.dvi tinydb.tex
	dvips tinydb.dvi -f > tinydb.ps
	ggv tinydb.ps

tinydb.dvi: tinydb.tex
	elatex tinydb.tex
	makeindex tinydb.idx
	makeindex tinydb.glo -s nomencl.ist -o tinydb.gls
	elatex tinydb.tex

tinydb.aux: tinydb.tex
	elatex tinydb.tex

tinydb.html : tinydb.aux tinydb.tex
	latex2html -split 1 -show_section_numbers -no_navigation tinydb.tex
	mozilla file:///home/madden/tinydbdoc/tinydb/index.html

clean:
	rm tinydb.aux tinydb.glo tinydb.gls tinydb.idx tinydb.ilg tinydb.ind tinydb.log tinydb.dvi tinydb.pdf tinydb.ps
