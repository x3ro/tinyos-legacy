AUTOMAKE_OPTIONS = foreign

bin_PROGRAMS = full/motlle

SUBDIRS = tools matelib mate

full/motlle$(EXEEXT): standalone/configure
	rm -rf full/[A-BD-Za-z]*
	-mkdir full
	(cd full;../standalone/configure TARGET=motlle)
	(cd full;ln -s . runtime; make)

standalone/configure:
	(cd standalone; ./Bootstrap)

