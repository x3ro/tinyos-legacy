# The install rules assume that JNI libraries should be placed in .../jre/bin
# This seems to be true on Windows, and IBM's Linux Java
# It's not true for Sun's Linux Java (but we don't have javax.comm for that, so...)

JNI=$(shell ../../scripts/locate-jre --jni)
JAVAC_DIR=$(shell ../../scripts/locate-jre --javac)
JDK=$(shell dirname "$(JAVAC_DIR)")


all install clean rpminstall:
	$(MAKE) -f Makefile.$(shell uname | cut -d_ -f1) "JDK=$(JDK)" "JNI=$(JNI)" $@
