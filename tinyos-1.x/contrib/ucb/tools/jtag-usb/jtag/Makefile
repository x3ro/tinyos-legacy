
LIB_PREFIX := /usr/local/lib

CFLAGS  = -g -pg
objects = MSP430mspgcc.o JTAGfunc.o 
funclets = funclets/progFlash.ci funclets/eraseFlash.ci

#simple Windows detection over the environment
ifdef WINDIR
	LNOPTS	=  -pg -mno-cygwin  -mdll -L. 
	LDFLAGS	= -lftd2xx
	DEP_LIBS= -lHIL $(LDFLAGS);
	CFLAGS  += -mno-cygwin -mdll -I../d2xx
	targets  = libHIL.a HIL.dll MSP430mspgcc.dll libMSP430mspgcc.a
else
	LNOPTS   = -fPIC -shared 
	targets  = libHIL.a libHIL.so 
ifdef DIRECTIO
	CFLAGS  += -DHIL_DIRECTIO
else
	CFLAGS  += -DHIL_PPDEV
endif
endif

CFLAGS  += -I./funclets

.PHONY: all FORCE clean depend rmdepend implib

all: ${targets}


libHIL.so: HIL.o
	gcc ${LNOPTS} -o $@ $<

HIL.dll: HIL.o $(isforce)
	gcc ${LNOPTS}  -s HIL.def $< -o $@ ${LDFLAGS}

libMSP430mspgcc.so: $(objects)
	gcc ${LNOPTS} $(objects) -o $@ $(DEP_LIBS)

#Windows library (DLL)
MSP430mspgcc.dll: $(objects) $(funclets) $(isforce)
	gcc ${LNOPTS}  -s MSP430mspgcc.def $(objects) -o $@ $(DEP_LIBS)

#Import-library for Windows. Used to link against the DLL.
ifdef WINDIR
libMSP430mspgcc.a: MSP430mspgcc.def MSP430mspgcc.dll
	dlltool -k --def $< --dllname MSP430mspgcc.dll --output-lib $@

libHIL.a: HIL.def HIL.dll
	dlltool -k --def $< --dllname HIL.dll --output-lib $@
else
libMSP430mspgcc.a: $(objects)
	${AR} rc $@ $?

libHIL.a: HIL.o
	${AR} rc $@ $?
endif


test: test.o JTAGfunc.o HIL.o
	gcc test.o -o $@  -L. -lMSP430mspgcc

install:
	install -m 644 libHIL.so ${LIB_PREFIX}/libHIL.so
	ldconfig

#Import library for Windows. Used to link against the DLL.
#creates libHIL.a overwrites static link lib!!

clean:
	rm -f HIL.o HIL.dll libHIL.a libHIL.so $(objects) MSP430mspgcc.dll MSP430mspgcc.so libMSP430mspgcc.a
