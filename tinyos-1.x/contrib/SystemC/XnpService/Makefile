COMPONENT=XTestXnp
SENSORBOARD=basicsb
#CFLAGS=  -v 

include ../Makerules

# Special installation with bootloader for In-Network Programming
# This requires modification to apps/Makerules for new target 'inp' which
# loads bootloader or typing the command line manually.
#
# Loading application SREC: this can be done with 'make <platform> install' or
# 'make <platform> reinstall'
#
#       @echo "    installing $(PLATFORM) binary"
#       @#$(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |sed 's:reinstall.::g'`
#       $(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |perl -pe 's/^reinstall.//; $$_=hex if /^0x/i;'`
#       uisp -dprog=dapa -dpart=ATmega128 --wr_fuse_e=ff --erase
#       sleep 1
#       uisp -dprog=dapa -dpart=ATmega128 --wr_fuse_e=ff --upload if=$(MAIN_SREC).out
#       sleep 1
#       uisp -dprog=dapa -dpart=ATmega128 --wr_fuse_e=ff --verify if=$(MAIN_SREC).out
#       sleep 1
#
# Load Bootloader over top: this can be done with 'make <platform> inp'
#
#       uisp -dprog=dapa --upload if=inpispm2d.srec                     # mica2dot
#       uisp -dprog=dapa --wr_fuse_e=ff --upload if=inpispm2.srec       # mica2

