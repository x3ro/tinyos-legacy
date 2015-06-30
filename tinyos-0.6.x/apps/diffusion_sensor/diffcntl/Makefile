CFLAGS = -Wall -DNOT_IN_TOS -DDEFAULT_LOCAL_GROUP=0x7d

TARGETS =\
	data \
	diffdump \
	interest \
	rxpower \
	txid \
	txpower \
	txreset

all: $(TARGETS)

clean:
	rm -rf *.o $(TARGETS)

distclean: clean
	rm -rf *~
