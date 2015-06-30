###########################################################################
#
# Makefile for TinyOS documentation
# Author: Phil Levis
# Date: 8/16/02
#
###########################################################################

LATEX = latex
PDF = pdflatex

TEX_FILES =  $(wildcard *.tex)
PDF_FILES = $(subst tex,pdf,$(TEX_FILES))

all:	$(PDF_FILES) cleanup

copy:   all
	cp *.pdf ..

%.pdf: %.tex
	$(PDF) $<
	$(PDF) $<

%.dvi: %.tex
	$(LATEX) $<
	$(LATEX) $<

clean: cleanup
	rm -f *.pdf *.ps *.dvi
	rm -f \#* *~

cleanup:
	rm -f *.aux *.bbl *.blg *.log *.toc 
