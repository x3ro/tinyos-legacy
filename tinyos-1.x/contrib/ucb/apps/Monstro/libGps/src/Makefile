CC=g++
CPPFLAGS=-O2 -I../include

CPPFLAGS_PYTHON=-I/usr/include/python2.3
CPPFLAGS_JAVA=-I/opt/sun-jdk-1.4.2.08/include/linux -I/opt/sun-jdk-1.4.2.08/include

SWIG_PYTHON_LIB=_GpsBoxPython.so
SWIG_JAVA_LIB=libGpsBoxJava.so

SWIG_PYTHON_FILES=GpsBoxPython.py
SWIG_JAVA_FILES=GpsBox.java GpsBoxJava.java GpsBoxJavaJNI.java GpsPrtkb.java GpsVlhb.java RfsGps.java


CPP_FILES = ArbCharIO.cpp FileCharIO.cpp RfsGps.cpp StructIO.cpp GpsBox.cpp StdCharIO.cpp TcpServerCharIO.cpp wait_for_fd.cpp FileDescCharIO.cpp GpsIO.cpp SerialCharIO.cpp TcpClientCharIO.cpp
HEADER_FILES = types_float.h types_int.h minmax.h string_utils.h wait_for_fd.h GetMicros.h FormStr.h StringScan.h FileDescCharIO.h GpsIO.h SerialCharIO.h TcpClientCharIO.h ZeroCharIO.h ArbCharIO.h FileCharIO.h RfsGps.h StructIO.h BlockIO.h GpsBox.h NullCharIO.h StdCharIO.h TcpServerCharIO.h wait_for_fd.h
CPP_OBJS = $(CPP_FILES:%.cpp=%.o)
CPP_LIB = libgps.a

###
### Common
###

all: $(CPP_LIB) $(SWIG_JAVA_LIB) $(SWIG_PYTHON_LIB)


install :
	cp $(CPP_LIB) $(SWIG_JAVA_LIB) $(SWIG_JAVA_FILES:%.java=%.class) $(SWIG_PYTHON_LIB) $(SWIG_PYTHON_FILES) ../../lib

clean:
	rm -f $(CPP_LIB) $(CPP_OBJS)
	rm -f $(SWIG_PYTHON_LIB) $(SWIG_PYTHON_FILES) GpsBoxPython_wrap.cxx GpsBoxPython_wrap.cxx
	rm -f $(SWIG_JAVA_LIB) $(SWIG_JAVA_FILES) $(SWIG_JAVA_FILES:%.java=%.class) GpsBoxJava_wrap.cxx GpsBoxJava_wrap.cxx

###
### GPS lib
###

$(CPP_LIB): $(CPP_OBJS)
	ar crs $(CPP_LIB) $(CPP_OBJS)

ArbCharIO.o : $(@:%.o=%.cpp) ArbCharIO.h StringScan.h FormStr.h BlockIO.h FileCharIO.h NullCharIO.h SerialCharIO.h StdCharIO.h TcpClientCharIO.h TcpServerCharIO.h ZeroCharIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

FileCharIO.o : $(@:%.o=%.cpp) FileCharIO.h BlockIO.h FormStr.h StringScan.h StdCharIO.h FileDescCharIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

FileDescCharIO.o : $(@:%.o=%.cpp) FileDescCharIO.h FormStr.h GetMicros.h wait_for_fd.h BlockIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

GpsBox.o : $(@:%.o=%.cpp) GpsBox.h GetMicros.h ArbCharIO.h RfsGps.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

GpsIO.o : $(@:%.o=%.cpp) GpsIO.h GetMicros.h FormStr.h string_utils.h StructIO.cpp StructIO.h types_int.h types_float.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

RfsGps.o : $(@:%.o=%.cpp) RfsGps.h FormStr.h StructIO.cpp GpsIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

SerialCharIO.o : $(@:%.o=%.cpp) SerialCharIO.h FormStr.h StringScan.h FileDescCharIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

StdCharIO.o : $(@:%.o=%.cpp) StdCharIO.h FileDescCharIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

StructIO.o : $(@:%.o=%.cpp) StructIO.h FormStr.h GetMicros.h NullCharIO.h string_utils.h BlockIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

TcpClientCharIO.o : $(@:%.o=%.cpp) TcpClientCharIO.h FormStr.h StringScan.h FileDescCharIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

TcpServerCharIO.o : $(@:%.o=%.cpp) TcpServerCharIO.h FormStr.h GetMicros.h StringScan.h minmax.h wait_for_fd.h BlockIO.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

wait_for_fd.o : $(@:%.o=%.cpp) wait_for_fd.h FormStr.h
	$(CC) $(CPPFLAGS) -Wall -g -c -static $(@:%.o=%.cpp) -o $@

$(CPP_FILES) $(HEADER_FILES):


###
### Java
###

$(SWIG_JAVA_LIB): GpsBoxJava_wrap.cxx GpsBoxJava.class libgps.a
	g++ -o $(SWIG_JAVA_LIB) -shared $(CPPFLAGS) $(CPPFLAGS_JAVA) GpsBoxJava_wrap.cxx GpsBox.cpp libgps.a

GpsBoxJava.class: $(SWIG_JAVA_FILES)
	javac $(SWIG_JAVA_FILES)

GpsBoxJava_wrap.cxx: GpsBoxJava.i GpsBox.h GpsBox.cpp
	swig -c++ -java GpsBoxJava.i

###
### Python
###

$(SWIG_PYTHON_LIB): GpsBoxPython_wrap.cxx libgps.a
	g++ -o $(SWIG_PYTHON_LIB) -shared $(CPPFLAGS) $(CPPFLAGS_PYTHON) GpsBoxPython_wrap.cxx GpsBox.cpp libgps.a

GpsBoxPython_wrap.cxx: GpsBoxPython.i GpsBox.h GpsBox.cpp
	swig -c++ -python GpsBoxPython.i

