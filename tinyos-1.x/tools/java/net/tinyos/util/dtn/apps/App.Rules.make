#
# This file is included to drive all the (non-gui based) apps
#
# An empty rule for converting .l to .c files.  Keeps make
# from trying to run lexx on the man page and overwriting
# the source.
%.c : %.l

all: $(PROGRAM)

$(PROGRAM): $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBDIRS) $(LIBS)

install: $(PROGRAM)
	-mkdir -p $(BINDIR)
	$(INSTALL) $(PROGRAM) ${BINDIR}
	-mkdir -p $(MANDIR)
	gzip -c -9 $(PROGRAM).l > $(MANDIR)/$(PROGRAM).l.gz

stripout:
	$(STRIP) $(PROGRAM)

clean:
	$(RM) -f $(PROGRAM).lo $(OBJECTS)

distclean: clean
	rm -rf .libs TAGS tags $(PROGRAM)

tags:
	etags *.c
	ctags *.[ch]

status:
	cvs status -v *.[ch] Makefile $(PROGRAM).l | grep Status

update:
	cvs update -d

depend:
	mkdep $(INCDIRS) *.c

include ../../Rules.make
