TDIR=$(shell ncc -print-tosdir)
COMPONENT=TraceRouteProbe
NESC_FLAGS=-I$(TDIR)/lib \
  -I./ -I$(TDIR)/lib/Route -I$(TDIR)/lib/Queue \
  -I../ECC -I../Flood \
  -DTOSH_DATA_LENGTH=49 -DMH6_ROUTING

DEFAULT_LOCAL_GROUP=96
MSG_SIZE=49
include ./Makerules

