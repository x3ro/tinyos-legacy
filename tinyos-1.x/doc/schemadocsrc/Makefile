tinyschema.ps: tinyschema.dvi tinyschema.tex
	dvips tinyschema.dvi -f > tinyschema.ps

tinyschema.dvi: tinyschema.tex
	elatex tinyschema.tex
	elatex tinyschema.tex

tinyschema.aux: tinyschema.tex
	elatex tinyschema.tex

tinyschema.html : tinyschema.aux tinyschema.tex
	latex2html -split 1 -show_section_numbers -no_navigation tinyschema.tex

clean:
	rm tinyschema.aux tinyschema.dvi tinyschema.ps tinyschema.pdf
