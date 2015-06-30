#
# Date 03/01/2004
# Author Kristin Wright
#

#LATEX = pdflatex
#PDF = pdflatex
LATEX = latex
PDF = pdflatex
BIBTEX = bibtex

pm.pdf: *.tex 
	$(PDF) pm.tex

pm.ps: pm.dvi pm.tex 
	dvips pm.dvi -f > pm.ps

pm.dvi: pm.tex
	$(LATEX) pm.tex
	#makeindex pm.tex
	$(BIBTEX) pm
	$(LATEX) pm.tex
	$(LATEX) pm.tex

pm.aux: pm.tex
	elatex pm.tex
clean: 
	rm -f *.aux *.bbl *.blg *.log *.toc 
	rm -f *.pdf *.ps *.dvi
	rm -f \#* *~
