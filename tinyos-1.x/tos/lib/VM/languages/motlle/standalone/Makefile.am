AUTOMAKE_OPTIONS = foreign

noinst_PROGRAMS = motlle

motlle_LDFLAGS = @READLINE_LIBS@

WARN_FLAGS = -Wall -Wshadow -Wnested-externs -Wno-char-subscripts -Wno-parentheses -Wno-unused
AM_CFLAGS = $(WARN_FLAGS) @TARGET_FLAGS@ -fno-strict-aliasing

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

PRIMS= $(COMMON_PRIMS)		\
       $(PC_PRIMS)		\
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

motlle_SOURCES = 		\
	$(COMMON_SOURCES)	\
	$(PC_SOURCES)		\
	$(PRIMS)		\
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
	mate_imachine.c		\
	mate_fmachine.c		\
	mate_machine.inc	\
	mate_machine.h		\
	mcompile.c		\
	mcompile.h		\
	module.c		\
	module.h		\
	motlle.c		\
	mparser.c		\
	mparser.h		\
	objenv.c		\
	objenv.h		\
	scheme.c		\
	scheme.h		\
	scompile.c		\
	scompile.h		\
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
	runtime/primops.c

EXTRA_DIST =			\
	parser.y		\
	lexer.l

lexer.c: $(srcdir)/lexer.l
	flex -F -8 $(srcdir)/lexer.l
	mv lex.yy.c lexer.c

build-parser:
	bison -dtv $(srcdir)/parser.y
	mv parser.tab.h $(srcdir)/tokens.h
	mv parser.tab.c $(srcdir)/mparser.c

$(srcdir)/tokens.h $(srcdir)/mparser.c: $(srcdir)/parser.y
	touch $(srcdir)/tokens.h $(srcdir)/mparser.c

$(srcdir)/runtime/primops.c: $(srcdir)/runtime/prim.pl $(PRIMS)
	perl $< "$(CC) -I$(srcdir) -I. $(AM_CFLAGS)" $^ >$@
