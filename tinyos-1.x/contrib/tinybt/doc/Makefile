# $Id: Makefile,v 1.1 2003/09/22 15:44:30 mleopold Exp $
# DEFINES

# Change to fit document
MAIN		= manual
TEXFILES	= manual.tex
BIBTEXFILE	= manual.bib

# Constant

LATEX		= latex
BIBTEX		= bibtex
PDFLATEX	= pdflatex
DVIPS		= dvips
FIG2DEV		= fig2dev
CONVERT         = convert

DEPDIR		= .deps
DEPFILES	:= $(TEXFILES:.tex=.dep)

UNDEF_REF	= 'Warning: There were undefined citations'
RERUN_LAT	= 'Warning:.*Rerun '

.PHONY:		clean realclean default print view depend
.SUFFIXES:	.ps .tex .dvi .eps .fig .dep .png .pdf .bbl .bib .gif .pnm .pl .txt .plx .dia

# TARGETS
default:	depend $(MAIN).ps

depend:		$(DEPFILES) 

# RULES
.tex.pdf:	$<
		@echo "******** Making $@ from $< ********"
		@$(PDFLATEX) $<

.tex.dvi:	$<
		@echo "******** Making $@ from $< ********"
		@$(LATEX) $<
		@if \
			grep -q -e ${UNDEF_REF} $*.log ; \
		then \
			$(BIBTEX) $* && \
			$(LATEX) $< ; \
		fi
		@if \
			grep -q -e ${RERUN_LAT} -e ${UNDEF_REF} $*.log ; \
		then \
			$(LATEX) $< ; \
			if \
				grep -q -e ${RERUN_LAT} $*.log ; \
			then \
				$(LATEX) $< ; \
			fi ; \
		fi

.dvi.ps:	$<
		@echo "******** Making $@ from $< ********"
		@$(DVIPS) -t letter -Z $< -o $@ # -Ppdf?

.fig.eps:	$<
		$(FIG2DEV) -L eps $< > $@

.fig.png:	$<
		$(FIG2DEV) -L png $< > $@

.pl.plx:	$<
		perl -pe 'if (/^__END__/) {exit;}' < $< > $@

.pl.txt:	$<
		pod2text $< > $@

.gif.pnm:	$<
		giftopnm $< > $@

# Apparently pdflatex has a problem if no density is set...
.eps.png:	$<
		$(CONVERT) -density 300x300 $< $@

#.png.pnm:	$<
#		pngtopnm $< > $@

.pnm.eps:	$<
		pnmtops -rle $< > $@

.dia.eps:	$<
		dia -n -t eps $< -e $@

#.pnm.png:	$<
#		pnmtopng $< > $@

$(MAIN).bbl:	$(BIBTEXFILE) $(MAIN).aux
		$(BIBTEX) $*

$(MAIN).aux:	$(MAIN).tex
		$(LATEX) $<

# MISC RULES
clean:
		rm -f *~ *.log *.blg *.aux

realclean:	clean
		rm -f $(MAIN).ps $(MAIN).dvi *.bbl *.aux \
		figures/*.fig.bak figures/*.png figures/*.eps

print:		$(MAIN).ps
		lpr -Zduplex $<

view:		$(MAIN).ps
		ghostview $<

# DEPENDENCIES
.tex.dep:	
#		echo "tiasdfa" > $(DEPDIR)/$@
		@echo $(MAIN).ps\:$(MAIN).dvi > $(DEPDIR)/$@
		@echo $(MAIN).dvi\:$(BIBTEXFILE) >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\epsfigure.*\{.+\}' $< | sed -e 's/\\epsfigure{\([^}]*\)}.*/$(MAIN).dvi:\1.eps/' >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\epsfigure.*\{.+\}' $< | sed -e 's/\\epsfigure{\([^}]*\)}.*/$(MAIN).pdf:\1.png/' >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\includegraphics.*\{.+\}' $< | sed -e "s/.*{\(.*\)}.*/$(MAIN).dvi:\1.eps/" >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\includegraphics.*\{.+\}' $< | sed -e "s/.*{\(.*\)}.*/$(MAIN).pdf:\1.png/" >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\include\{.*\}' $< | sed -e "s/.*{\(.*\)}.*/$(MAIN).dvi:\1.tex/" >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\input\{.*\}' $< | sed -e "s/.*{\(.*\)}.*/$(MAIN).dvi:\1.tex/" >> $(DEPDIR)/$@
	 	@grep -E '^[^%]*\\verbatiminput\{.*\}' $< | sed -e "s/.*{\(.*\)}.*/$(MAIN).dvi:\1/" >> $(DEPDIR)/$@

-include $(addprefix $(DEPDIR)/,$(DEPFILES))

$(MAIN).dvi:	$(TEXFILES) $(MAIN).bbl

# Directory...
$(DEPFILES):	$(DEPDIR)

$(DEPDIR):	
		mkdir $@

$(DEPDIR)/bilag:
		mkdir $@
