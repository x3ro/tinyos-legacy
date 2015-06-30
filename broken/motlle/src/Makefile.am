AUTOMAKE_OPTIONS = foreign

noinst_PROGRAMS = @TARGET@
noinst_LIBRARIES = @TARGETLIB@

EXTRA_PROGRAMS = motlle smotlle tmotlle
EXTRA_LIBRARIES = libmotlle.a

motlle_LDFLAGS = -lreadline -lcurses

WARN_FLAGS = -Wall -Wshadow -Wnested-externs -Wno-char-subscripts -Wno-parentheses -Wno-unused
AM_CFLAGS = $(WARN_FLAGS) @TARGET_FLAGS@

COMMON_PRIMS = 			\
	runtime/arith.c		\
	runtime/arith.h		\
	runtime/basic.c		\
	runtime/basic.h		\
	runtime/list.c		\
	runtime/list.h		\
	runtime/vector.c	\
	runtime/vector.h

PC_PRIMS =			\
	runtime/bitset.c	\
	runtime/bitset.h	\
	runtime/io.c		\
	runtime/io.h		\
	runtime/string.c	\
	runtime/stringops.h	\
	runtime/symbol.c	\
	runtime/symbol.h

APRIMS= $(COMMON_PRIMS) 	\
	runtime/mote.c		\
	runtime/mote.h

SPRIMS= $(APRIMS) $(PC_PRIMS)

PRIMS= $(SPRIMS)		\
	runtime/debug.c		\
	runtime/debug.h		\
	runtime/files.c		\
	runtime/files.h		\
	runtime/support.c	\
	runtime/support.h

COMMON_SOURCES = 		\
	alloc.c			\
	alloc.h			\
	call.c			\
	call.h			\
	code.h			\
	context.c		\
	context.h		\
	error.c			\
	error.h			\
	interpret.c		\
	interpret.h		\
	memory.c		\
	memory.h		\
	mudlle.h		\
	mvalues.h		\
	options.h		\
	primitives.h		\
	types.c			\
	types.h

PC_SOURCES =			\
	mudio.c			\
	mudio.h			\
	ports.c			\
	ports.h			\
	print.c			\
	print.h			\
	table.c			\
	table.h			\
	utils.c			\
	utils.h

libmotlle_a_SOURCES =		\
	$(COMMON_SOURCES)	\
	$(APRIMS)		\
	runtime/avrprimops.c	\
	smotlle.c		\
	smotlle.h

tmotlle_SOURCES =		\
	$(libmotlle_a_SOURCES)	\
	fake.c

smotlle_SOURCES =		\
	$(COMMON_SOURCES)	\
	$(PC_SOURCES)		\
	$(SPRIMS)		\
	smain.c			\
	smotlle.c		\
	smotlle.h

motlle_SOURCES = 		\
	$(COMMON_SOURCES)	\
	$(PC_SOURCES)		\
	$(PRIMS)		\
	avrlayout.h		\
	avr_machine.c		\
	avr_machine.h		\
	calloc.c		\
	calloc.h		\
	compile.c		\
	compile.h		\
	dump.c			\
	dump.h			\
	env.c			\
	env.h			\
	global.c		\
	global.h		\
	ins.c			\
	ins.h			\
	lexer.c			\
	lexer.h			\
	machine.h		\
	mcompile.c		\
	mcompile.h		\
	module.c		\
	module.h		\
	motlle.c		\
	mparser.c		\
	mparser.h		\
	objenv.c		\
	objenv.h		\
	this_machine.c		\
	this_machine.h		\
	tokens.h		\
	tree.c			\
	tree.h			\
	valuelist.c		\
	valuelist.h		\
	runtime/runtime.c	\
	runtime/runtime.h


BUILT_SOURCES = 		\
	lexer.c			\
	tokens.h		\
	mparser.c		\
	runtime/aprimops.c	\
	runtime/primops.c	\
	runtime/sprimops.c

EXTRA_DIST =			\
	parser.y		\
	lexer.l

$(srcdir)/lexer.c: lexer.l
	flex -F -8 $(srcdir)/lexer.l
	mv lex.yy.c $(srcdir)/lexer.c

$(srcdir)/tokens.h $(srcdir)/mparser.c: parser.y
	bison -dtv $(srcdir)/parser.y
	mv $(srcdir)/parser.tab.h $(srcdir)/tokens.h
	mv $(srcdir)/parser.tab.c $(srcdir)/mparser.c

$(srcdir)/runtime/primops.c: runtime/prim.pl $(PRIMS)
	perl $< "$(CC) -I$(srcdir) $(AM_CFLAGS)" $^ >$@

$(srcdir)/runtime/sprimops.c: runtime/prim.pl $(SPRIMS)
	perl $< "$(CC) -I$(srcdir) $(AM_CFLAGS) -DSTANDALONE" $^ >$@

$(srcdir)/runtime/aprimops.c: runtime/prim.pl $(APRIMS)
	perl $< "avr-gcc -I$(srcdir) $(AM_CFLAGS) -DSTANDALONE -DTINY" $^ >$@

$(srcdir)/runtime/avrprimops.c: runtime/avrprim.pl $(APRIMS)
	perl $< "$(CC) -I$(srcdir) $(AM_CFLAGS)" $^ >$@
