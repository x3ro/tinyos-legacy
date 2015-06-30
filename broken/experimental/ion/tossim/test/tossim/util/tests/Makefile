ROOT = ../../../..
_MODULE = tossim_util 
MODULE = $(_MODULE:%=%_tests)
_NAMES = File Heap
NAMES = $(_NAMES:%=%_Test) Util_Tests
TARGET = exe

LOCAL_INCLUDEPATH =
LOCAL_LIBRARYPATH = 
LOCAL_LIBRARIES = $(_MODULE) boost_filesystem-gcc

include $(ROOT)/test/Makefile.defines

include $(ROOT)/test/Makefile.rules
