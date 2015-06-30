# Build the documentation

SRCS=usermanual.xml docbook-utils.dsl

all: web pdf

web:	$(SRCS)
	docbook2html -d "docbook-utils.dsl#html" usermanual.xml
#	collateindex.pl -i faq-index -o faq-index.xml HTML.index
#	db2html usermanual.xml

pdf:	$(SRC)
	docbook2pdf -d "docbook-utils.dsl#print" usermanual.xml
#	collateindex.pl -i faq-index -o faq-index.xml HTML.index
#	db2pdf usermanual.xml

clean:
	rm -rf usermanual.pdf html/*.html *~


# Some notes:
#
# When running emacs in PSGML mode, use 
#   (set-variable sgml-parent-document usermanual.xml)
# to connect the child document to the parent for parsing and proper display.
# You'll probably need to run 'sgml-parse-prolog to force it redisplay and
# parse your text