/**
 * Copyright (c) 2005 - Michigan State University.
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL MICHIGAN STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF MICHIGAN
 * STATE UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * MICHIGAN STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND MICHIGAN STATE UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 **/

#include <eeprom.h> 	

enum {
  AM_MnpMsg_ID = 47,
  EEPROM_ID = 47
};

#define TRUE    -1
#define FALSE    0
#define SUCCESS  1
#define FAIL	 0

//major states
#define SYSM_IDLE 0
#define SYSM_DOWNLOAD 1
#define SYSM_DOWNLOAD_DONE 2
#define SYSM_UPDATE 3
#define SYSM_UPDATE_DONE 4
#define SYSM_FORWARD 5
#define SYSM_FORWARD_DONE 6
#define SYSM_QUERY 7
#define SYSM_REBOOT 9
#define SYSM_ADVERTISE 10

//states
#define SYS_IDLE 0

#define SYS_DL_START	60
#define SYS_DL_START0	61
#define SYS_DL_START1	62
#define SYS_DL_START2 	63
#define SYS_DL_SRECWRITE 64
#define SYS_UP_SRECWRITE 65

#define SYS_DL_END		 73
#define SYS_DL_FAIL		 77
#define SYS_DL_FAIL_SIGNAL 78

#define SYS_EEFLASH_WRITE 67
#define SYS_EEFLASH_WRITEDONE 68

#define SYS_REQ_CIDMISSING	50
#define SYS_GET_CIDMISSING  51
#define SYS_GETDONE			56	   

#define SYS_FORWARD_START		100
#define SYS_FORWARDING			101
#define SYS_FORWARD_END			102
#define SYS_TERMINATE_FORWARD		103
#define SYS_QRY_START			104
#define SYS_QRY				105
#define SYS_QRY_DONE			106
#define SYS_FORWARD_QRY_DONE		107
#define SYS_CHECK_STATUS		108
#define SYS_WAIT_FOR_CHANNEL		110
#define SYS_WAIT_FOR_REQUEST		111
#define SYS_WAIT_FOR_RETRANSMIT		112
#define SYS_FORWARD_RESUME		113
#define SYS_FORWARD_RESUME_DONE		115
#define SYS_FORWARD_RESUME_DONE_PRE	116
#define SYS_REQUESTING			117
#define SYS_UP_SRECREAD			120
#define SYS_DL_REQUEST			121
#define SYS_ADVERTISE_START		122
#define SYS_BCAST_AD			123
#define SYS_FORWARD_START_RESUME	125
#define SYS_FORWARD_START_PRE		126
#define SYS_SLEEP			128
#define SYS_WAIT_FOR_DLSTART		129
#define SYS_ADINTERVAL			130
#define SYS_WAIT_FOR_NEXT_CAPSULE	132
#define SYS_SEND_REQUEST		134
#define SYS_DL_REQUESTING		135

#define SYS_START_FORWARDING		137
#define SYS_FORWARD_CONTINUE		138

#define SYS_GETDONE_SIGNAL	152

#define SYS_SEND_FAIL		154
#define SYS_ISP_EXEC_CONTINUE	155

#define SYS_WAKEUP_LISTEN	156

// Internal EEPROM Mappting Table structure
#define MT_PROG_START	0	// Program Address - start page number (2 bytes)
#define MT_PROG_ID	2	// ProgramID (2 bytes)
#define MT_NOFCAPSULES	4	// Number of Capsules (2 bytes)
#define MT_ITEM_SIZE	6	// Mapping Table Item Size	
#define MAPPING_TABLE_START	0x00

#define AVREEPROM_GROUPID_ADDR	 0xFF2
#define AVREEPROM_LOCALID_ADDR	 0xFF0
#define AVREEPROM_PID_ADDR 		0xFF4  
#define AVREEPROM_NOFCAPSULES_ADDR	0xFF6

#define EEPROM_NOFPAGES	1000 //Number of pages in EEPROM

#define DEF_PROG_START	1	// default position to store program
#define NOFBYTESPERLINE 16	//16bytes per EEPROM line
#define NOFLINESPERPAGE 16
#define EE_LINE_START  EE_PAGE_START<<4  //based on 16 lines per page!!
#define EEPROM_LAST_LINE   (EEPROM_NOFPAGES*NOFLINESPERPAGE) -1   //last eeprom write address     

//Application linebuffer
#define ELBUFF_NOFLINES 2
#define ELBUFF_SIZE NOFBYTESPERLINE * ELBUFF_NOFLINES  
#define ELBUFF_PERPAGE NOFLINESPERPAGE / ELBUFF_NOFLINES

//positions in FLASH Srex  	   
#define POS_PID 0	
#define POS_CID	POS_PID+2
#define POS_STYPE POS_CID+2
#define POS_SNOFB POS_STYPE+1
#define POS_S0_PID POS_SNOFB+1
#define POS_S0_CRC POS_S0_PID+2
#define POS_S1_ADDR POS_SNOFB+1
#define POS_S1_I0 POS_S1_ADDR+2	   //1st instruction
#define POS_S3_LOSTCID POS_SNOFB+1	// Link to next lost section
#define POS_S3_LEN_LOSTSECTION POS_S3_LOSTCID+2	// Length of this lost section	

//SREC format
#define SREC_S0	0	//type S0
#define SREC_S1	1	//type S1
#define SREC_S9 9	//type S9
#define SREC_S3 3	//type S3

//structure of TOSMessage w/Stype record
//Data offset into data packet
#define TS_CMD          0	//command ID
#define TS_SUBCMD	1
#define TS_PID          2	//program id
#define TS_CAPSULEID	4	//Capsule ID location

#define TS_POWER_LEVEL			1
#define TS_CHANNEL_RATE			2

#define TS_DESTID			4
#define TS_SOURCEID			6	// mote id, who sent the message. 
#define TS_MSGDATA			8
#define TS_REQCNT			8
#define TS_TOTAL_CAPSULE		8
#define TS_TOTAL_SEGMENT		10
#define TS_TYPE				11
#define TS_LEN	  			12
#define TS1_ADDR_MSB			13
#define TS1_ADDR_LSB			14
#define TS_INSTR0_MSB			15	//first data/instruction byte (msb)

#define TS_MISS_PACKET			9

//TOS Message commands
#define CMD_START_DOWNLOAD  1    
#define CMD_DOWNLOADING  2    
#define CMD_DOWNLOAD_STATUS  4    
#define CMD_DOWNLOAD_COMPLETE      8    
#define CMD_ISP_EXEC 5
#define CMD_ADVERTISE	10
#define CMD_DL_REQUEST	11
#define CMD_BS_START		14
#define CMD_SYNC	15

//CMD_GET_CIDMISSING should be different from CMD_REQ_CIDMISSING
#define CMD_GET_CIDMISSING 6	//from network, query 
#define CMD_REQ_CIDMISSING 12	 //to network, request for missing capsules, query reply

#define CMD_RST 99

/* EEPROM Data storage
Each page in EEPROM is 264Bytes. We only use 256 bytes
The page is divided into Lines of 16bytes each.
Sixteen (16) Lines make a Page (useable 256 bytes)
*/

typedef struct {
	uint8_t Line[NOFBYTESPERLINE];
} EEBUF_line_struct;						//EELine structure - 16bytes


#define REV_ARRAY_SIZE		16

#define SIG_REQUEST		1
#define SIG_CHANNEL		2
#define SIG_RETRANSMIT		3
#define SIG_FORWARD_START	6
#define SIG_FORWARD		7
#define SIG_SLEEP		8
#define SIG_ADINTERVAL		10
#define SIG_ADVERTISE_START	11
#define SIG_NEXTCAPSULE		12
#define SIG_BS_START		14
#define SIG_REQUESTING		15
#define SIG_DL_REQUEST		16
#define SIG_FORWARD_END		17
#define SIG_FORWARD_RESUME_DONE	18
#define SIG_ADVTRIES		22
#define SIG_ISP			23
#define SIG_INIT_LISTEN		24
#define SIG_NONBS_START		25
#define SIG_FORWARD_CONTINUE	26
#define SIG_WAKEUP_LISTEN	27

#define DATA_SENT		1
#define CTL_SENT		2
#define ADV_SENT		3
#define DLREQ_SENT		4
#define FORWARDS		5
#define MSG_RVD			6
#define DATA_RVD		7
#define CTL_RVD			8
#define ADV_RVD			9
#define REQ_RVD			10
#define EEREADS			11
#define EEWRITES		12
#define SLEEP_TIME		13
#define START_TIME		14
#define PARENT			15

#define SENDER_SELECTION	1
#define ADV_NOREQ		2
#define INIT_SLEEP		3

#define BASE_ADDR		0
#define DEF_CHANNEL_RATE	1
#define ADVERTISE_RETRY		2
#define FORWARD_START_RETRY	3
#define FORWARD_TERMINATE_RETRY	2
#define	QUERY_RETRY		1
#define REQUEST_RETRY		3
#define QRY_TIMING		2
#define TIMER_SPAN		500
#define REQUEST_TIMING		1
#define NEXTCAPSULE_TIMING	3
#define CHANNEL_TRIES		50
#define WAITQRY_TIMING		1
#define MISSINDICATOR_SIZE	MNP_CAPSULE_PER_SEGMENT/8	
#define LOSS_LIMIT_PERCENT	0.4

#define TOSSIM_NMB_SEGMENT	2
#define MNP_CAPSULE_PER_SEGMENT	128
#define TOSSIM_LAST_SEGMENT_SIZE 128

#define MIN_RESPONSE_DELAY	1
#define MIN_RETRANSMIT_DELAY	10
#define	FAIL_RETRY_INTERVAL	20
#define MIN_AD_INTERVAL		10
#define MIN_AD_RESTART_INTERVAL	8000
#define FORWARD_RATE		160
#define START_FORWARD_RATE	64
#define MIN_QUERY_INTERVAL	200
#define EEPROM_RETRY		100
#define ADV_TRIES		50
#define SEND_ISP_TRIES		3
#define WAKEUP_LISTEN_PERIOD	500
#define WAIT_FORWARD_RATE	500
#define INITSLEEP_DURATION	4000
#define ADVSLEEP_DURATION	4000
#define SLEEP_DURATION		40000
#define MAX_RESTART		6
