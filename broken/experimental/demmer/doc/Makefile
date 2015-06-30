LATEX = pdflatex
TEXFILES = $(wildcard *.tex) $(wildcard *.bib)

MAINFILE = manual

all: $(MAINFILE).pdf 

$(MAINFILE).pdf: $(MAINFILE).tex
	pdflatex $<
#	bibtex $(MAINFILE)
#	pdflatex $<
	pdflatex $<

%.blg: %.bib
	pdflatex $*.tex
	bibtex $*
	pdflatex $*.tex

%.toc: %.tex
	pdflatex $*.tex

clean:
	/bin/rm -f $(MAINFILE).pdf $(MAINFILE).pdf *.dvi *.aux *.ps *~ *.log
	/bin/rm -f *.lot *.lof *.toc *.blg *.bbl url.sty

view:
	acroread $(MAINFILE).pdf

upload:

