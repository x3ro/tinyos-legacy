ifndef UCBROBODIR
UCBROBODIR := $(shell ncc -print-tosdir)/../contrib/ucbRobo
endif

#including -I$(UCBROBODIR)/lib/sensornet/PEGmagsensor because that's
#where some type files are located

CFLAGS = \
-I$(UCBROBODIR)/include\
-I$(UCBROBODIR)/lib/sensornet/PEGmagsensor


PROGRAM = Test_neighbor_table
all:
	gcc $(CFLAGS) -o $(PROGRAM).exe $(PROGRAM).c
