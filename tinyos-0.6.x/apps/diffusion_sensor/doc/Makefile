############################################################
#
# Makefile     : Documentation Makefile
#
############################################################

DOCUMENT =	tdiff_howto

LATEX	 =	latex
DVIPS	 = 	dvips

default:	all

all: dvi ps

$(DOCUMENT).dvi dvi: $(DOCUMENT).tex
	$(LATEX) $(DOCUMENT).tex

$(DOCUMENT).ps ps: $(DOCUMENT).dvi $(DOCUMENT).tex
	$(DVIPS) -o $(DOCUMENT).ps $(DOCUMENT).dvi

$(DOCUMENT).pdf pdf: $(DOCUMENT).ps $(DOCUMENT).dvi $(DOCUMENT).tex
	ps2pdf $(DOCUMENT).ps $(DOCUMENT).pdf

clean:
	rm -f *.bak *.aux *.ps *.dvi *.log *.toc *~
