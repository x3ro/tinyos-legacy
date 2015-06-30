COMPONENT=TestRouting

#For Wireless Reprogramming - Vinayak
SENSORBOARD=basicsb

include ../../Makerules

#special installation with bootloader for In-Network Programming
install_inp: reinstall
#	@echo "    installing $(PLATFORM) binary"
#	@#$(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |sed 's:reinstall.::g'`
#	$(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |perl -pe 's/^reinstall.//; $$_=hex if /^0x/i;'`
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --erase 
#	sleep 1	             
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=$(MAIN_SREC).out
#	sleep 1	             
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --verify if=$(MAIN_SREC).out
#	sleep 1	 
#Load Bootloader over top            
	sleep 1
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=../../inpispm2.srec

install_inp.%: reinstall.%
#	@echo "    installing $(PLATFORM) binary"
#	@#$(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |sed 's:reinstall.::g'`
#	$(SET_ID) $(MAIN_SREC) $(MAIN_SREC).out `echo $@ |perl -pe 's/^reinstall.//; $$_=hex if /^0x/i;'`
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --erase 
#	sleep 1	             
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=$(MAIN_SREC).out
#	sleep 1	             
#	$(PROGRAMER) $(PROGRAMMER_FLAGS) --verify if=$(MAIN_SREC).out
#	sleep 1	 
#Load Bootloader over top            
	sleep 1
	$(PROGRAMER) $(PROGRAMMER_FLAGS) --upload if=../../inpispm2.srec
