ifeq ($(OS),Windows_NT)
	NCUNIT_CP := "$(shell cygpath --windows $(NCUNIT_ROOT)/bin);$(shell cygpath --windows $(NESC_CP));$(shell cygpath --windows $(AVRORA_ROOT)/bin)"
else
	NCUNIT_CP := "$(NCUNIT_ROOT)/bin:$(NESC_CP):$(AVRORA_ROOT)/bin"
endif

all:
	mkdir -p bin
	javac -classpath ${NCUNIT_CP} -d bin `find java -name '*.java'`
	cp tos_make/mica2test.target ${TOSDIR}/../tools/make/
	chmod a+x scripts/ncc_cl scripts/uninliner
	mkdir -p ${TOSDIR}/platform/mica2test
	echo "@opts = (\"-gcc=${NCUNIT_ROOT}/scripts/uninliner\"," > ${TOSDIR}/platform/mica2test/.platform
	echo "         \"-mmcu=atmega128\"," >> ${TOSDIR}/platform/mica2test/.platform
	echo "         \"-fnesc-target=avr\"," >> ${TOSDIR}/platform/mica2test/.platform
	echo "         \"-fnesc-no-debug\");" >> ${TOSDIR}/platform/mica2test/.platform
	echo "push @opts, \"-mingw-gcc\" if \$$cygwin;" >> ${TOSDIR}/platform/mica2test/.platform
	echo "@commonplatforms = (\"mica2\", \"mica128\", \"mica\", \"avrmote\");" >> ${TOSDIR}/platform/mica2test/.platform

