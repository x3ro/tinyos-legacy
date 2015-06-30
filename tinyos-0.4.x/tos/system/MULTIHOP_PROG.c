/* -*-Mode: C; c-file-style: "BSD" -*- 
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:		Sam Madden, based on PROG_COMM by Robert Szewczyk
 *
  Augmented implementation of PROG_COMM which uses multihop routing
  to send code fragments to a multi-cell network.
  
  As with PROG_COMM, based on 4 message handlers:

  WRITE_FRAG_MSG: Write a 16-byte fragment to the EEPROM
  READ_FRAG_MSG: Read a 16-byte fragment from the EEPROM, reply with a
                 WRITE_FRAG_MSG 
  START_MSG: Start little-guy to transfer code fragments
             from EEPROM to flash (do the reprogramming) 
  NEW_MSG: Initialize a new program with a specified id-- the mote
           will only accepts fragments tagged with the program id from the last
           NEW_MSG it saw.

  The first 16k of EEPROM are reserved for network programming.

  Programs are written in 16 byte capsules (CAPSULE_SIZE == 4 ==
  log2(16)), starting from capsule offset BASELINE.  The capsules before
  BASELINE are used for system data.  Currently, on the first capsule is
  used -- it contains the mote id, which is fetched at initialization
  time.

  The four capsules following capsule MAX_CAPSULES are bitmaps which
  indicate which capsules have been written.

  Additions for multihop programming are as follows:
  - Motes forward all packets from the basestation, unless they have already forwarded those packets
    Packets are tagged with an id which the mote uses to determine which packets it has forwarded 
    (see forward_message)
  - All packets are tagged with a "level" which indicates the mote's depth in the tree
  - If a mote receives a packet from a child (note with a greater level) which contains data from
    that child's capsule-bitmap, it will AND that bitmap with its own capsule bitmap rather than
    forwarding the packet.

  There's a bunch of ugliness to make sure we don't forward packets while sending other packets
  for regular programming.

  Some weird caveats:
  - All messages are sent as broadcast messages
  - Doesn't support dots

 */

#include "tos.h"
#include "MULTIHOP_PROG.h"
#include "pgmspace.h"
#include "dbg.h"

#define DEBUG

#define NORMAL       0
#define BITMAP_WRITE 1
#define BITMAP_READ  2
#define BITMAP_READ_WAIT_1  3
#define BITMAP_READ_WAIT_2  4
#define LG_WAKEUP           5
#define LG_LISTEN           6

#define PRGM_ENABLE 8
#define READ_BYTE   9
#define WRITE_BYTE 10
#define UNKNOWN    11

#define INIT0      15
#define INIT1      16
#define INIT2      17
#define INIT3      18
#define INIT4      19

#define FINAL_CHECK1 26
#define FINAL_CHECK2 27
#define FINAL_CHECK3 28
#define FINAL_CHECK4 29

#define SS   4
#define MOSI 5
#define MISO 6
#define SCK  7 
/* Utility functions */

/* Code capsules are of size 2^n. This makes it simple to map them onto
   loglines, to account for them. Additionally, the uController memory is a
   multiple of that size. For the Atmel, we start out with 16 bytes of code
   per capsule */ 
#define CAPSULE_POWER 4

/* How many capsules can we fit in the entire memory? For Atmel 8535, this
   number is 512. */

#define MAX_CAPSULES 512

/* Where in the EEPROM should we allocate the code? The unit is in
   LOG_LINES. For the current LOG policy, each log line is 16 bytes in length,
   and there is a total of 2048 log lines. Bear in mind that the program code
   also needs some extra space for the bitmaps*/

#define BASELINE 4

typedef struct {
    char is_request:1; //set to 1 if message is a request, 0 if a response
    char level:7;
    short prog_id;
    short addr;
    short seqno;  //sequence number used to determine if we've forwarded this message
    unsigned char code[16];
} capsule;

typedef struct {
    char is_request:1; //set to 1 if message is a request, 0 if a response
    char level:7; //level we're currently at
    short  prog_id;
    short  addr;
    short dest;
    char check;
    short seqno;
} capsule_req;

#define TOS_FRAME_TYPE MULTIHOP_PROG_frame
TOS_FRAME_BEGIN(MULTIHOP_PROG_frame) {
    short dest;
    char state;
    char write_delay;
    char q;
    char i2c_pending;
    char forw_pending;
    char check;
    char done;
    char frag_map[16];
    int new_prog;
    int prog_length;
    short lastseq;  //last seen sequence number
    char history;  //messages in the past which we've forwarded

    char level; //level we're at
    char lastheard; //last time we heard a message from that level
    char brainxfer;

    TOS_Msg msg;
    TOS_Msg forw;  
    int pend_addr;
    char pend_amid;
    
    TOS_MsgPtr i2c_msg;
}
TOS_FRAME_END(MULTIHOP_PROG_frame);

void write_frag();
char forward_message(short seqno, char amid, char level, TOS_MsgPtr msg);

#define TOS_PROG_ID 0
#define MAX_LEVEL_WAIT 3  //time we wait at current level

char TOS_COMMAND(MULTIHOP_PROG_INIT)(){
    VAR(i2c_pending) = 0;
    VAR(q) = -1;
    VAR(dest) = TOS_BCAST_ADDR;
    VAR(i2c_msg) = &(VAR(msg));
    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_LOGGER_INIT)();
    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_COMM_INIT)();

    dbg(DBG_BOOT, ("MULTIHOP_PROG initialized\n"));

    VAR(i2c_pending) = 1;
    VAR(forw_pending) = 0;
    VAR(state) = INIT0;
    VAR(history) = 0;
    VAR(lastseq) = -1;
    VAR(level) = -1;
    VAR(brainxfer) = 0;
    VAR(lastheard) = MAX_LEVEL_WAIT;//get a level ASAP
    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_READ_LOG)(0, VAR(frag_map));
    return 1;
}

char TOS_COMMAND(MULTIHOP_PROG_START)(){
    return 1;
}

char TOS_COMMAND(MULTIHOP_PROG_WRITE_LOG)(int line, char* data){
    return TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_WRITE_LOG)(line, data);
}
char TOS_COMMAND(MULTIHOP_PROG_READ_LOG)(int line, char* dest){
    return TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_READ_LOG)(line, dest);
}

char TOS_COMMAND(MULTIHOP_PROG_SEND_MSG)(short addr, char type, TOS_MsgPtr data) {
    if (VAR(i2c_pending)) {
	//wait to forward this message until after i2c write / message handling is complete
	int i;
	
	VAR(pend_addr) = addr;
	VAR(pend_amid) = type;
	for (i = 0; i < DATA_LENGTH; i++) {
	    VAR(forw).data[i] = data->data[i];
	}
	VAR(forw_pending) = 1;
	return 1;
    } else {
	return TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(addr, type, data);
    }
}


TOS_MsgPtr TOS_EVENT(MULTIHOP_PROG_READ_MSG)(TOS_MsgPtr msg){
    capsule_req * data = (capsule_req *)msg->data;
    int log_line;
    int i;
    char level;

    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;

#ifdef DEBUG
	TOS_CALL_COMMAND(MULTIHOP_PROG_YELLOW_LED_ON)();
#endif
	//forward the message if we haven't forwarded this message before
	level = data->level;
	data->level = VAR(level);
	forward_message(data->seqno, AM_MSG(MULTIHOP_PROG_READ_MSG), level,msg);	
	//keep using TOS_BCAST_ADDR
	//VAR(dest) = data->dest;
	if (data->prog_id == 0) {
	    capsule *data_ret;
	    log_line = data -> addr;
	    data_ret = (capsule *) VAR(i2c_msg)->data;
	    data_ret -> addr = log_line;
	    data_ret -> prog_id = TOS_PROG_ID;
	    for (i=0; i < 16; i++) {
		data_ret -> code[i] = _LPM(log_line++);
	    }
	    data_ret->is_request = 0;
	    data_ret->level = VAR(level);
	    data_ret->prog_id = VAR(new_prog);
	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(VAR(dest),
					    AM_MSG(MULTIHOP_PROG_WRITE_FRAG_MSG),
					    VAR(i2c_msg));
	} else {
	    VAR(check) = data->check;
	    log_line = data->addr >> CAPSULE_POWER;
	    dbg(DBG_PROG, ("LOG_READ_START \n"));
	    ((capsule *)(VAR(i2c_msg)->data))->addr = data->addr;

	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_READ_LOG)(BASELINE+log_line,((capsule *)(VAR(i2c_msg)->data))->code);


	}
    } 
    return msg;
}

//ugly code which decides whether or not to forward a request message from
//a parent.  we only forward packets which we haven't already forwarded.
//we keep an 8 bit history bitmap which tells us which of the previous
//8 packets we've already forwarded.  we assume all packets before
//those 8 have been forwarded.
//return 1 if message was forwarded, 0 otherwise
//also, update the level which we are sending at based on the level of the sender
#define MAX_SEQ 32000
#define MIN_SEQ 1000  //very unlikely we'll miss this many consecutive messages
char forward_message(short seqno, char amid, char level, TOS_MsgPtr msg) {
    short seqdiff;

    //handle wraparound
    if (VAR(lastseq) > MAX_SEQ && seqno < MIN_SEQ) {
	VAR(lastseq) = seqno;
	VAR(history) = 0;
    }

    //if seqdiff > 0, this is a message we may have already forwarded (need to check bitmap)
    //if seqdiff < 0, we haven't seen this message before
    seqdiff = VAR(lastseq) - seqno;

    if (seqdiff < 0 || (seqdiff < 8 && !(VAR(history) & (1 << seqdiff)))) {
	//we really mean SEND_MSG here, so that our forwarded messages don't step on the feets of 
	//regular network programming messages (since SEND_MSG buffers messages if we're in a multiprog segment)
	TOS_CALL_COMMAND(MULTIHOP_PROG_SEND_MSG)(TOS_BCAST_ADDR, amid , msg);
	if (seqdiff < 0) { //new message, shift history bitmap and set lastseq
	    VAR(history) <<= -seqdiff;
	    VAR(history) |= 0x01;
	    VAR(lastseq) = seqno;
	} else { //old message, set bit in history bitmap
	    VAR(history) |= (1 << seqdiff);
	}
	if (level != -1) { //update our level
	    if (level == VAR(level) -1) {
		VAR(lastheard) = 0;
	    } else {
		if (++VAR(lastheard) > MAX_LEVEL_WAIT) {
		    VAR(level) = level + 1;
		    VAR(lastheard) = 0;
		}
	    }
	}
	return 1;
    }
    return 0;

}


void brain_xfer() {
#if defined(__AVR_ATmega163__)
    reprogram();
#else
    int i;
    TOS_CALL_COMMAND(MULTIHOP_PROG_RED_LED_TOGGLE)();
    MAKE_I2C_BUS1_SDA_OUTPUT();
    CLR_I2C_BUS1_SDA_PIN();

    MAKE_LITTLE_GUY_RESET_OUTPUT();
    CLR_LITTLE_GUY_RESET_PIN();
    for (i=0; i<5000; i++){
	asm volatile("nop"::);
    }
    MAKE_LITTLE_GUY_RESET_INPUT();
    SET_LITTLE_GUY_RESET_PIN();
    for (i=0; i<5000; i++){
	asm volatile("nop"::);
    }
#endif
}


char TOS_EVENT(MULTIHOP_PROG_LOG_READ)(char* data, char success){
    capsule * msg = (capsule *) VAR(i2c_msg)->data;
    unsigned char allthere, i;
    char * ptr;
    if ((data != VAR(frag_map)) && (data != msg->code))
      return 1;
      //	return TOS_SIGNAL_EVENT(MULTIHOP_PROG_READ_LOG_DONE)(data, success);
    dbg(DBG_PROG, ("LOG_READ_DONE\n"));
    if (VAR(state) == NORMAL) {
	allthere = 0xff;
	if (VAR(check)) {
	    ptr = msg->code;
	    for (i = 0; i < 16; i++) {
	        allthere &= *ptr++;
	    }
	    VAR(i2c_msg)->data[29] = allthere;
	} else {
	    allthere = 0;
	}
	VAR(check) = 0;
	if (allthere != 0xff) {
	    msg->is_request = 0;
	    msg->prog_id = VAR(new_prog);
	    msg->level = VAR(level);
	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(VAR(dest),AM_MSG(MULTIHOP_PROG_WRITE_FRAG_MSG),VAR(i2c_msg));
	} else {
	    VAR(i2c_pending) = 0;
	    i = (unsigned char) (msg->addr & 0xff);
	    i >>= 4;
	    VAR(done) |= 1 << i;
	    if (VAR(done) == 0xf) {
		TOS_CALL_COMMAND(MULTIHOP_PROG_YELLOW_LED_ON)();
	    }
	}
    } else if (VAR(state) == BITMAP_READ) {
	dbg(DBG_PROG, ("Finished reading the bitmap page\n"));
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	dbg(DBG_PROG, ("writing the pending page"));
	write_frag();
    } else if (VAR(state) == INIT0) {
	/* Initialize the local ID from the EEPROM */
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	TOS_LOCAL_ADDRESS = VAR(frag_map)[0] & 0xff;
	TOS_LOCAL_ADDRESS |= VAR(frag_map) [1]<< 8;
	VAR(new_prog) = VAR(frag_map)[2] & 0xff;
	VAR(new_prog) |= VAR(frag_map)[3] << 8;
	VAR(prog_length) = VAR(frag_map)[4] & 0xff;
	VAR(prog_length) |= VAR(frag_map)[5] << 8;
    } 
    return 1;
}

char TOS_EVENT(MULTIHOP_PROG_MSG_SENT)(TOS_MsgPtr msg){
    if ((VAR(i2c_pending) == 1) && (msg == VAR(i2c_msg))) {
	VAR(i2c_pending) = 0;
	if (VAR(forw_pending)) {
	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(VAR(pend_addr), VAR(pend_amid), &VAR(forw));
	    return 1;
	}
    } else if ((VAR(forw_pending) == 1) && (msg == &VAR(forw))) {
	VAR(forw_pending) = 0;
	if (VAR(brainxfer)) {
	    TOS_SIGNAL_EVENT(MULTIHOP_PROG_START_PROG)(msg);
	    return 1;
	}
    }else {
	return TOS_SIGNAL_EVENT(MULTIHOP_PROG_MSG_SEND_DONE)(msg);
    }

    return 0;
}

void write_frag() {
    capsule * data = (capsule *) VAR(i2c_msg)->data;
    int log_line;
    int i;

    if (!data->is_request) {
	/*HACK -- for the right bitmap segment into frag_map
	  we won't actually write data to this line thanks to the (!data->is_request) 
	  statment below.
	*/
	log_line = (((data->addr >> CAPSULE_POWER) - MAX_CAPSULES)) << (7 +  CAPSULE_POWER);
    } else {
	log_line = data->addr;
    }
    dbg(DBG_PROG, ("LOG_WRITE_FRAG_START 0x%04x\n", log_line & 0xffff));
    log_line >>= CAPSULE_POWER;
    if (VAR(q) != ((log_line >> (CAPSULE_POWER+3)) & 0x3)) {
	VAR(state) = BITMAP_WRITE;
	if (VAR(q) == -1) {
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	    TOS_SIGNAL_EVENT(MULTIHOP_PROG_WRITE_LOG_DONE)(0);
	} else {
	    dbg(DBG_PROG, ("Storing to logline %04x\n", BASELINE +MAX_CAPSULES + VAR(q)));

	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_WRITE_LOG)(BASELINE + MAX_CAPSULES + VAR(q),
						  VAR(frag_map)); 
	    VAR(q) =  (log_line >> (CAPSULE_POWER+3)) & 0x3;
	}
    } else {
	if (!data->is_request) {
	    //this is a bitmap from a child node -- AND its bitmap with our bitmap
	    //frag map will be flushed the next time we do a write
	    if (!data->is_request) TOS_CALL_COMMAND(MULTIHOP_PROG_RED_LED_TOGGLE)();
	    for (i = 0; i < 16; i++) {
		VAR(frag_map)[i] &= data->code[i];
	    }
	    TOS_SIGNAL_EVENT(MULTIHOP_PROG_WRITE_LOG_DONE)(0);
	} else {
	    VAR(frag_map)[(log_line>>3)& 0xf] |= 1 << (log_line & 0x07);

	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_WRITE_LOG)(BASELINE+log_line, data->code);
	}
    }
}



TOS_MsgPtr TOS_MSG_EVENT(MULTIHOP_PROG_WRITE_FRAG_MSG)(TOS_MsgPtr msg){
    TOS_MsgPtr local = msg;
    capsule * data = (capsule *)local->data;

    //if this is a response containing another nodes bitmap, just AND that bitmap
    //into ours.  otherwise, forward the data on...
    if (data->is_request || (short)data->addr < (short)(MAX_CAPSULES << CAPSULE_POWER) ) {
	char i2c = VAR(i2c_pending);
	char level;

	VAR(i2c_pending) = 1;
	level = data->level;
	//mark the level of messages going down the tree with our level
	if (data->is_request) {
	    data->level = VAR(level);
	}
	forward_message(data->seqno, AM_MSG(MULTIHOP_PROG_WRITE_FRAG_MSG), level, msg);
	
	VAR(i2c_pending) = i2c;
	if (!data->is_request) {
	    return local; /* don't write others fragments unless they're 
					       a part of the bitmap */
	}
    }

    //don't AND in bitmaps from nodes at our level or higher
    if (!data->is_request && data->level <= VAR(level)) {
	return local;
    }
    if (!data->is_request) TOS_CALL_COMMAND(MULTIHOP_PROG_GREEN_LED_TOGGLE)();
    if (data->prog_id != VAR(new_prog))
	return msg;
    if (VAR(i2c_pending) == 0) {
	VAR(i2c_pending) = 1;
	local = VAR(i2c_msg);
	VAR(i2c_msg) = msg;
	write_frag();
    }
    return local;
}

char TOS_EVENT(MULTIHOP_PROG_WRITE_LOG_DONE)(char success){
    int i;
#ifdef DEBUG
	TOS_CALL_COMMAND(MULTIHOP_PROG_YELLOW_LED_TOGGLE)();
#endif
    dbg(DBG_PROG, ("LOG_WRITE_DONE\n"));
    for (i = 0; i < 16; i++) {
	dbg(DBG_PROG, ("%02x ", VAR(frag_map)[i] & 0xff));
    } 
    dbg(DBG_PROG, ("\n"));
    if (VAR(state) == BITMAP_WRITE) {
	dbg(DBG_PROG, ("Finished writing the capsule bitmap\n"));
	VAR(state) = BITMAP_READ;
	TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_READ_LOG)(BASELINE + MAX_CAPSULES + VAR(q), VAR(frag_map)); 
    } else if ((VAR(state) >= INIT1) && (VAR(state) <= INIT4)) {
	for ( i = 0; i < 16; i++) { 
	    VAR(frag_map)[i] = 0;
	}
	TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_WRITE_LOG)(BASELINE + MAX_CAPSULES +
					      VAR(state) - INIT1,
					      VAR(frag_map));
	VAR(state)++;
    } else {
	VAR(state) = NORMAL;
	VAR(i2c_pending) = 0;
	//we need forward a message now that i2c is freed up
	//DANGER -- possibly already forwarding message at this point, if i2c_pending was == 0
	if (VAR(forw_pending)) {
	    TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(VAR(pend_addr), VAR(pend_amid), &VAR(forw));
	}
    }
    //    TOS_SIGNAL_EVENT(MULTIHOP_PROG_APPEND_LOG_DONE)(success);
    return 1;
}


TOS_MsgPtr TOS_MSG_EVENT(MULTIHOP_PROG_START_PROG) (TOS_MsgPtr msg) {
    int i;
    char fwd;

    if (VAR(brainxfer) == 0) {	    
	//we're gonna die, so go ahead and forward blindly...
	TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_SEND_MSG)(TOS_BCAST_ADDR , AM_MSG(MULTIHOP_PROG_START_PROG), msg);
	VAR(brainxfer) = 1;
	if (fwd) return msg;
    } 
    brain_xfer();
    return msg;
}



TOS_MsgPtr TOS_MSG_EVENT(MULTIHOP_PROG_NEW_PROG) (TOS_MsgPtr msg) {
    if (VAR(i2c_pending) == 0) {
#ifdef DEBUG
    TOS_CALL_COMMAND(MULTIHOP_PROG_GREEN_LED_ON)();
#endif
	
	VAR(state) = INIT1;
	VAR(new_prog) = msg->data[2] & 0xff; //first two bytes are the sequence number
	VAR(new_prog) |= msg->data[3] << 8;
	VAR(prog_length) = msg->data[4] & 0xff;
	VAR(prog_length) |= msg->data[5] << 8;
	VAR(frag_map)[0] = TOS_LOCAL_ADDRESS & 0xff;
	VAR(frag_map)[1] = (TOS_LOCAL_ADDRESS >> 8) & 0xff;
	VAR(frag_map)[2] = msg->data[2]; 
	VAR(frag_map)[3] = msg->data[3];
	VAR(frag_map)[4] = msg->data[4];
	VAR(frag_map)[5] = msg->data[5];
	VAR(i2c_pending) = 1;
	forward_message(*(short *)(msg->data), AM_MSG(MULTIHOP_PROG_NEW_PROG), -1, msg);
	TOS_CALL_COMMAND(MULTIHOP_PROG_SUB_WRITE_LOG)(0,
					      VAR(frag_map));
    }

    return msg;
}
