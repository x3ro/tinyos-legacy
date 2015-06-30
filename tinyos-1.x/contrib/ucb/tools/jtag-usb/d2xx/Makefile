# integration of the FTDI D2xx library into the GCC environment.  This
# file assumes that the driver is installed already, but perhaps at
# some point in the future it will install the driver as well. 

ifndef PREFIX
	PREFIX=/usr/local
endif

libftd2xx.a:
	echo EXPORTS > foo.def
	nm FTD2XX.lib |grep ' T _'| sed 's/.* T _//' >> foo.def
	dlltool --def foo.def --dllname FTD2XX.dll --output-lib libftd2xx.a -k


install: libftd2xx.a
	install -m 644 libftd2xx.a ${PREFIX}/lib/libftd2xx.a
	install -m 644 FTD2XX.H ${PREFIX}/include/FTD2XX.H

clean: 
	rm -f libftd2xx.a foo.def