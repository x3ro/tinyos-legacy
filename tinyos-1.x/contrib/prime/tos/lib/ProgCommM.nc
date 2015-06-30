
includes ProgCommMsg;

module ProgCommM 
{
  uses {
    interface StdControl as GenericCommCtl;
    interface StdControl as LoggerCtl;
    interface SendMsg as Send;
    interface LoggerRead;
    interface LoggerWrite;
    interface Leds;
    interface ReceiveMsg as ReadFragmentMsg;
    interface ReceiveMsg as WriteFragmentMsg;
    interface ReceiveMsg as StartReprogrammignMsg;
    interface ReceiveMsg as NewProgramMsg;
    interface Bootloader;
  }
  provides {
    interface StdControl;
  }
}
implementation
{
    enum {
	NORMAL=0,
	BITMAP_WRITE=1,
	BITMAP_READ=2,
	BITMAP_READ_WAIT_1=3,
	BITMAP_READ_WAIT_2=4,
	LG_WAKEUP=5,
	LG_LISTEN=6,
	PRGM_ENABLE=8,
	READ_BYTE=9,
	WRITE_BYTE=10,
	UNKNOWN=11,
	INIT0=15,
	INIT1=16,
	INIT2=17,
	INIT3=18,
	INIT4=19,
	FINAL_CHECK1=26,
	FINAL_CHECK2=27,
	FINAL_CHECK3=28,
	FINAL_CHECK4=29,
	REPROGRAM = 30,
	TOS_PROG_ID = 50
    };
    
/* Code capsules are of size 2^n. This makes it simple to map them onto
   loglines, to account for them. Additionally, the uController memory is a
   multiple of that size. For the Atmel, we start out with 16 bytes of code
   per capsule */
    enum {
	CAPSULE_POWER=4,
	MAX_CAPSULES=8192,
	BASELINE=32,
	BITMAP_MASK = ((MAX_CAPSULES >> (CAPSULE_POWER+3)) -1),
	METABASE=16
    };

    uint16_t dest;
    uint8_t state;
    uint8_t write_delay;
    uint8_t q;
    uint8_t i2c_pending;
    uint8_t check;
    //    uint8_t done;
    uint8_t frag_map[16];
    int new_prog;
    int prog_length;
    TOS_Msg msg;  
    TOS_MsgPtr i2c_msg;

    command result_t StdControl.init(){
	result_t r1;
	result_t r2;
	result_t r3;
	i2c_pending = 0;
	q = 0xff;
	dest = TOS_BCAST_ADDR;
	i2c_msg = &(msg);
	r1 = call LoggerCtl.init();
	r2 = call GenericCommCtl.init();
	dbg(DBG_BOOT, ("ReprogramM initialized\n"));
	i2c_pending = 1;
	state = INIT0;
	r3 = call LoggerRead.read(METABASE, frag_map);
	if (r3 == SUCCESS) {
	    call Leds.greenOn();
	}
	call GenericCommCtl.init();
	return rcombine(r1, r2);
    }

    command result_t StdControl.start() {
	result_t r1;
	result_t r2;
	r1 = call LoggerCtl.start();
	r2 = call GenericCommCtl.start();
	call Leds.redOn();
	return rcombine(r1, r2);
    }

    command result_t StdControl.stop() {
	result_t r1;
	result_t r2;
	r1 = call LoggerCtl.stop();
	r2 = call GenericCommCtl.stop();
	return rcombine(r1, r2);
    }

    result_t write_done_handler() {
	int i;
	call Leds.yellowToggle();
	dbg(DBG_PROG, "LOG_WRITE_DONE\n");
	for (i = 0; i < 16; i++) {
	    dbg(DBG_PROG, "%02x ", frag_map[i] & 0xff);
	} 
	dbg(DBG_PROG, ("\n"));
	if (state == REPROGRAM) {
	    call Bootloader.reloadProgram();
	} else if (state == BITMAP_WRITE) {
	    dbg(DBG_PROG, "Finished writing the capsule bitmap\n");
	    state = BITMAP_READ;
	    if(call LoggerRead.read((uint16_t)(BASELINE + MAX_CAPSULES + q), frag_map) != SUCCESS) {
		call Leds.greenToggle();
	    }
	} else if (state == NORMAL) {
	    i2c_pending = 0;
	    //	((capsule *)(i2c_msg->data))->addr = count++;
	    //call COMM_SEND_MSG(TOS_UART_ADDR,0x06,i2c_msg);

	} else if ((state >= INIT1) && (state <= INIT4)) {
	    for ( i = 0; i < 16; i++) { 
		frag_map[i] = 0;
	    }
	    if (call LoggerWrite.write((uint16_t)(BASELINE + MAX_CAPSULES +
					   state - INIT1),
				       frag_map) != SUCCESS) {
		call Leds.greenToggle();

	    }
	    state++;
	} else {
	    state = NORMAL;
	    i2c_pending = 0;
	}
	return 1;
    }

    void write_frag() {
	ProgFragment * data = (ProgFragment *) i2c_msg->data;
	int log_line = data->addr;
	dbg(DBG_PROG, "LOG_WRITE_FRAG_START 0x%04x\n", log_line & 0xffff);
	//    log_line >>= CAPSULE_POWER;
	if (q != ((log_line >> (CAPSULE_POWER+3)) & BITMAP_MASK)) {
	    state = BITMAP_WRITE;
	    if (q == 0xff) {
		q =  (log_line >> (CAPSULE_POWER+3)) & BITMAP_MASK;
		write_done_handler();
		//TOS_SIGNAL_EVENT(PROG_COMM_WRITE_LOG_DONE)(0);
	    } else {
		dbg(DBG_PROG, "Storing to logline %04x\n", BASELINE +MAX_CAPSULES + q);
		if (call LoggerWrite.write((uint16_t)(BASELINE + MAX_CAPSULES + q),
					   frag_map) != SUCCESS) {
		    call Leds.greenToggle();
		}
		q =  (log_line >> (CAPSULE_POWER+3)) & BITMAP_MASK;
	    }
	} else {
	    frag_map[(log_line>>3)& 0xf] |= 1 << (log_line & 0x07);
	    call LoggerWrite.write((uint16_t)(BASELINE+log_line), data->code);
	}
    }



    event TOS_MsgPtr ReadFragmentMsg.receive(TOS_MsgPtr m){
	FragmentRequest * data = (FragmentRequest *)m->data;
	int log_line;
	int i;
	if (i2c_pending == 0) {
	    i2c_pending = 1;
	    
	    call Leds.redToggle();
	
	    dest = data->dest;
	    if (data->prog_id == 0) {
		ProgFragment *data_ret;
		log_line = data -> addr;
		data_ret = (ProgFragment *) i2c_msg->data;
		data_ret -> addr = log_line;
		data_ret -> prog_id = TOS_PROG_ID;
		for (i=0; i < 16; i++) {
		    data_ret -> code[i] = 0x00; //_LPM(log_line++);
		}
		call Send.send(dest,
			       sizeof(ProgFragment),
			       i2c_msg);
	    } else {
		check = data->check;
		log_line = data->addr/* >> CAPSULE_POWER*/;
		dbg(DBG_PROG, "LOG_READ_START \n");
		((ProgFragment *)(i2c_msg->data))->addr = data->addr;
		call LoggerRead.read((uint16_t)(BASELINE+log_line),((ProgFragment *)(i2c_msg->data))->code);
	    }
	} 
	return m;
    }

    
    event result_t LoggerRead.readDone(uint8_t * data, result_t success) {
	ProgFragment * m = (ProgFragment *) i2c_msg->data;
	NewProgAnnounce *npa = (NewProgAnnounce *) i2c_msg->data;
	uint8_t allthere, i;
	uint8_t * ptr;
	if ((data != ((uint8_t*)frag_map)) && (data != ((uint8_t *)m->code)))
	    return SUCCESS;
	//	return TOS_SIGNAL_EVENT(PROG_COMM_READ_LOG_DONE)(data, success);
	dbg(DBG_PROG, "LOG_READ_DONE\n");
	if (state == NORMAL) {
	    allthere = 0xff;
	    if (check) {
		ptr = m->code;
		for (i = 0; i < 16; i++) {
		    allthere &= *ptr++;
		}
		i2c_msg->data[29] = allthere;
	    } else {
		allthere = 0;
	    }
	    check = 0;
	    call Leds.greenToggle();
	    if (allthere != 0xff) {
		call Send.send(dest,sizeof(ProgFragment),i2c_msg);
	    } else {
		i2c_pending = 0;
	    }
	} else if (state == BITMAP_READ) {
	    dbg(DBG_PROG, "Finished reading the bitmap page\n");
	    state = NORMAL;
	    i2c_pending = 0;
	    dbg(DBG_PROG, "writing the pending page");
	    write_frag();
	} else if (state == INIT0) {
	    /* Initialize the local ID from the EEPROM */
	    state = NORMAL;
	    i2c_pending = 0;
	    TOS_LOCAL_ADDRESS = frag_map[0] & 0xff;
	    TOS_LOCAL_ADDRESS |= frag_map [1]<< 8;
	    new_prog = frag_map[2] & 0xff;
	    new_prog |= frag_map[3] << 8;
	    prog_length = frag_map[4] & 0xff;
	    prog_length |= frag_map[5] << 8;
	    call Leds.yellowToggle();
	    npa->new_id = TOS_LOCAL_ADDRESS;
	    npa->prog_id = TOS_PROG_ID;
	    npa->prog_length = new_prog; 
	    for (i=0; i < 16; i++) { 
		m->code[i] = frag_map[i];
	    }
	    call Send.send(0x7d,
			   sizeof(ProgFragment),
			   i2c_msg);
	} 
	return SUCCESS;
    }

    event result_t Send.sendDone(TOS_MsgPtr m, result_t success){
	if (i2c_pending == 1){
	    i2c_pending = 0;
	} 
	return 0;
    }
    
    event TOS_MsgPtr WriteFragmentMsg.receive(TOS_MsgPtr m){
	TOS_MsgPtr local = m;
	ProgFragment * data = (ProgFragment *)local->data;
	if (data->prog_id != new_prog)
	    return m;
	if (i2c_pending == 0) {
	    i2c_pending = 1;
	    local = i2c_msg;
	    i2c_msg = m;
	    write_frag();
	}
	return local;
    }
    
    event result_t LoggerWrite.writeDone(result_t success){
	return write_done_handler();
    }

 
    event TOS_MsgPtr StartReprogrammignMsg.receive(TOS_MsgPtr m) {
	state = REPROGRAM;
	frag_map[0] = TOS_LOCAL_ADDRESS & 0xff;
	frag_map[1] = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
	frag_map[2] = new_prog & 0xff;
	frag_map[3] = (new_prog >> 8) & 0xff;
	frag_map[4] = prog_length & 0xff;
	frag_map[5] = (prog_length >> 8) & 0xff;
	frag_map[6] = 0xde;
	frag_map[7] = 0xad;
	frag_map[8] = 0xbe;
	frag_map[9] = 0xef;
	call LoggerWrite.write(METABASE, frag_map);
	return m;
    }
    
    event TOS_MsgPtr NewProgramMsg.receive(TOS_MsgPtr m) {
	NewProgAnnounce * packet = (NewProgAnnounce *)m->data;
	if (i2c_pending == 0) {
	    call Leds.greenOn();
	    state = INIT1;
	    new_prog = packet->prog_id;
	    prog_length = packet->prog_length;
	    if (packet->rename_flag) {
		TOS_LOCAL_ADDRESS = packet->new_id;
	    }
	    frag_map[0] = TOS_LOCAL_ADDRESS & 0xff;
	    frag_map[1] = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
	    frag_map[2] = new_prog & 0xff;
	    frag_map[3] = (new_prog >> 8) & 0xff;
	    frag_map[4] = prog_length & 0xff;
	    frag_map[5] = (prog_length >> 8) & 0xff;
	    call LoggerWrite.write(METABASE, frag_map);
	}
	return m;
    }

}
