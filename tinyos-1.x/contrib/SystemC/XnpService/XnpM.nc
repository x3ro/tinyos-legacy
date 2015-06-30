/***************************************************************************
MODULE		XNetProg
FILE		XnpM.nc
PURPOSE		In Network Programming/Boot Module

PLATFORM	MICA2-128 mode only
			TOS NesC

REVISION	02mar03	mm	created
			04apr03	mm	restructure w/statemachine
			08may03 mm	datalength29 for TOS Packet size overrides application's packet size
			09may03	mm	add checksum test on incomming srecords
==============================================================================
DESCRIPTION

Provides In-Network Programming services to client/application.

There are 2 main phases:
1. Program/code download from network/host via radio.
2. Local reprogram of uP and reboot.

These operations are independent and coordinated with Mote Application (client)
to avoid resource conflicts.

TERMINOLOGY
-ProgramID aka PID 
Identifies the Program being downloaded, reprogramming etc. Corresponds to srec checksum
-CapsuleID aka CID
SREC record from Network - contained in a single TOS Message Packet
-INP In-Network Programming. Reprogram process over the network
-ISP In-System Programming. Typically refers to the Mote's internal reprogramming.
-Client. The user's application executing on the Mote.


RESOURCES
NP uses 
-EEPROM (External Flash memory).
-GENERIC_COMM / Active Message Handler#47
-RANDOMLFSR / to randomize delays in response to Query Missing CID

NOTES
-EEPROM resource is shared by NP and Client. T
Client must release EEPROM resource before acknowledging NP_DOWNLOAD_REQ.

-Only 1 Program image in EEPROM is currently supported.

-Client must INIT and TUNE radio. I.e. establish wireless link.
This module does NOT handle powerdown/sleep activities. I.e. radio/system link
must be active/on for NP messages to be received and processed.

-Application MUST be compiled for ATMega128 NATIVE mode. AT103 Compatiblity
Mode FUSE MUST be DISABLED/TURNED OFF.

-BOOTLOADER INPISP must be installed at BOOTLOADER_START address (0xFC00 default)
An absolute call/jump is made to this location to do in-sytem reprogramming of UP
- system will crash/reboot if the NPXISP code is not present.

-LOCAL/BROADCAST
Accepts BROADCAST Reprogram/boot messages.

-NETPROG Message Structures

NETWORK MEssage Format
0	DestinationAddr
1
2	ActiveMessageID
3	GroupID
4	TOS Message Length(NESC) 0x20
5	MessageID
6 	Extended Msg ID (reserved-PrivateModeID)0xFF:broadcast(donotrespond) 0xnn:specified mote acks
7	ProgramID
8
9	Message Specific: Eg CapsuleID
10
11	Message Specific: Eg CommandStatus
###


FLASH SREC Structure
byt	name
0	ProgID
1	
2	CID
3
4	SType
5	NofBytes
6	S0:ProgID, S1:Address
7
8	S1:Instruction0
...
--------------------------------------------------------------------------
INTERFACES

-Download Phase
NP_DOWNLOAD_REQ
Signal to Client that an in-network program download operation has been
received (over-air using AM#47).Passes to client planned EEPROM start page
and number of pages to be used to store download program

NP_DOWNLOAD_ACK
Acknowledge from Client that NP download operation can/cannot proceed with
download.

NP_DOWNLOAD_DONE
Signal to Client that in-network program download operation has completed.
Supplies actual EEROM Start Page, NofPages used to store downloaded program
Client is now responsible for maintaining integrity of code image downloaded
into EEPROM (i.e. must not overwrite/modify the section of EEPROM)


-Reprogram Phase
NP_REPROG_MSG
Signal to client that a in-network reprogram/reboot message has been received

NP_REPROG_REQ
Command from client to initiate a reprogram/reboot operation.
Client passes ProgramID which is matched with ID found in EEPROM. If match
UP reprogramming/reboot operation is started. Client should release all 
resources/ before issuing request.

MAJOR STATES

sEEMMODE	EEFLASH States
EE_WRITE
EE_READ
===============================================================================
REVISION HISTORY
02mar03	mm	created	from NPTB
04apr03	mm	major re-write - add broadcast download and missing capsule support
17apr03	mm	random delay in request for missing CID	
12jul03         Jaein Jeong, Sukun Kim
                Sends acknowledgement explicitly when a mote finishes receiving
                capsules.
****************************************************************************/


module XnpM {
  provides {
    interface Xnp;
    interface XnpConfig;
    interface StdControl;
  }
  uses {
	interface StdControl as XnpmControl;
    interface StdControl as GenericCommCtl;
    //interface StdControl as CommControl;
    interface StdControl as EEPROMControl;
    interface SendMsg;;
    interface ReceiveMsg; 
    interface Leds;     
    interface EEPROMRead;
    interface EEPROMWrite;
  	interface Random;
  }
}


implementation {

/*----------------------DIRECTIVES ------------------------------------------*/
//#define  JTAG
//#define  JTAGHEX  1
//#define MICA2DOT

#include "Xnp.h"
#include "avr/eeprom.h"

//#define new
/*--------------------- INCLUDES --------------------------------------------*/


/*--------------------- DEFINES ---------------------------------------------*/
#define TRUE    -1
#define FALSE    0
#define SUCCESS  1
#define FAIL	 0

#ifdef JTAG
#define TOS_LOCAL 5		  //hack !!!! Must update to application/clients LA
//#define LOCAL_GROUP 0x13
#endif

#define DATA_LENGTH29	29		//XNP uses a 29byte data packet

//netprogramming states
#define SYSM_IDLE 		0
#define SYSM_DOWNLOAD 	1
#define SYSM_UPDATE 	2

#define SYS_IDLE 		0
#define SYS_IDLE_RENTRY 1
#define SYS_ACK			2

#define SYS_DL_START	60
#define SYS_DL_START0	61
#define SYS_DL_START1	62
#define SYS_DL_START2 	63
#define SYS_DL_SRECWRITE 64
#define SYS_UP_SRECWRITE 65

//Ending states
#define SYS_DL_ABORT 	70 //not used?
#define SYS_DL_END		 73
#define SYS_DL_END_SIGNAL 74
#define SYS_DL_FAIL		 77
#define SYS_DL_FAIL_SIGNAL 78

//Write States
#define SYS_EEFLASH_WRITE 67
#define SYS_EEFLASH_WRITEDONE 68

//Read/check states
#define SYS_REQ_CIDMISSING	50
#define SYS_GET_CIDMISSING  51
#define SYS_GETNEXTCID		54	   
#define SYS_GETDELAYED		55
#define SYS_GETDONE			56	   //

#define SYS_ISP_REQ		40	//isp
#define SYS_ISP_REQ1	41
#define SYS_GET_EEPID	43 //read PID from EEFLASH
#define SYS_BEACON 91

//ATMega INTERNAL  eeprom locations for storing TOS ID info used after reboot
#define AVREEPROM_GROUPID_ADDR	 0xFF2
#define AVREEPROM_LOCALID_ADDR	 0xFF0
#define AVREEPROM_PID_ADDR 		0xFF4  


#define EEPROM_NOFPAGES	1000 //Nof 256byte pages in EEPROM
//TEMP DEBUG
//#define EEPROM_NOFPAGES	20 //Nof 256byte pages in EEPROM
#define	EE_PAGE_START 1  //Start of EPROM - this MUST match LOGGER.c start!!
#define NOFBYTESPERLINE 16	//16bytes per EPROM line
#define NOFLINESPERPAGE 16
#define EE_LINE_START  EE_PAGE_START<<4  //based on 16 lines per page!!
#define EEPROM_LAST_LINE   (EEPROM_NOFPAGES*NOFLINESPERPAGE) -1   //last eprom write address      11/03

//Application linebuffer
#define ELBUFF_NOFLINES 2
#define ELBUFF_SIZE NOFBYTESPERLINE * ELBUFF_NOFLINES  
#define ELBUFF_PERPAGE NOFLINESPERPAGE / ELBUFF_NOFLINES
//#define EPROM_READ_SIZE (EPROM_SIZE/NOFBYTESPERLINE) -1
//#define EPROM_READ_SIZE 32768/4

//ATmel 4Mbit EEFLASH Definitions
#define EEBUF_PAGESIZE 256 //ignore extra 4 bytes
#define SAMPLE_NOFBYTES 6 //6bytes per sample set
#define LASTLINE_NOFSAMPLES 2  //lastline of each page has only 2 sample sets
#define EEBUF_NOFSAMPLES EEBUF_PAGESIZE/SAMPLE_NOFBYTES

//positions in FLASH Srex  	   
#define POS_PID 0	//new
#define POS_CID	POS_PID+2
#define POS_STYPE POS_CID+2
#define POS_SNOFB POS_STYPE+1
#define POS_S0_PID POS_SNOFB+1
#define POS_S0_CRC POS_S0_PID+2
#define POS_S1_ADDR POS_SNOFB+1
#define POS_S1_I0 POS_S1_ADDR+2	   //1st instruction

//SREC format
#define SX_TYPES2 0x02	//S2 type
#define SX_LEN14 0x14	//20bytes length
#define SREC_S0	0	//type S0
#define SREC_S1	1	//type S1
#define SREC_S9 9	//type S9

//structure of TOSMessage w/Stype record
//Data offset into data packet
#define TS_CMD                0     //command ID
#define TS_SUBCMD			1   
#define TS_PID             2     //program id
#define TS_CAPSULEID		4	//Capsule ID location
#define TS_MSGDATA			6
#define TS_TYPE				6
#define TS_LEN	  			7
#define TS1_ADDR_MSB			8
#define TS1_ADDR_LSB			9
#define TS_INSTR0_MSB		10	//first data/instruction byte (msb)


//TOS Messaging defines
//Commands from network (wireless)
#define CMD_START_DOWNLOAD  1    // sampl and write to eprom
#define CMD_DOWNLOADING  2    //
#define CMD_QUERY_COMPLETE 3   // received all the capsules.
#define CMD_DOWNLOAD_STATUS  4    // request/rsponse with download status
#define CMD_DOWNLOAD_COMPLETE      8    // DACTEST
#define CMD_ISP_EXEC 5
#define CMD_GET_PIDSTATUS 7	//Get Program ID

#define CMD_GET_CIDMISSING 6	//from network
//#define CMD_GET_CIDMISSING2 7
#define CMD_REQ_CIDMISSING 6	 //to network
//#define CMD_SET_SRECUPDATE 34		//scattered srec download

#define CMD_DUMP   32   // start reading data from ERPOM
#define CMD_START_READ 33
#define CMD_STATUS       9    // xmit status

#define CMD_RST 99

#define MSG_COMMAND			  1	 //RF message response to a command
#define MSG_LOGREAD			  0	 //RF message is part of Log dump
#define MSG_IDLE			  2  //Undefined
//NPX TOSMessage reponses
#define CMD_STATE_DONE        0	 //command accepted and processed
#define CMD_STATE_BUSY        1	 //command accepted but system busy
#define CMD_STATE_WRONGSTATE  2  //not in correct state to process command
#define CMD_STATE_BADSEQUENCE 3  //command or iteration out of sequence,order
#define CMD_STATE_BADCHECKSUM 4  //bad SREC CHecksum
#define CMD_STATE_BADSTYPE    5  //bad SREC Type
#define CMD_STATE_REQCID	10	//requesting a missing CID	 
#define CMD_STATE_UKNOWN      0xff	//unknown command

/* EEPROM Data storage
Each page in EEPROM is 264Bytes. We only use 256 bytes
The page is divided into Lines of 16bytes each.
Sixteen (16) Lines make a Page (useable 256 bytes)
*/


typedef struct {
	uint8_t Line[NOFBYTESPERLINE];
} EEBUF_line_struct;						//EELine structure - 16bytes

#define DELAY_PACKETTIME 0xFF<<5		   //0xFF approx 0.5mSec in mica2dot

/* Define the TOS Frame and variables it owns */

// #define TOS_FRAME_TYPE NPX_frame

    
	uint8_t sSYSState;			//CPU state:normal,sleep
	uint8_t sSYSMState; //major state
	TOS_Msg NETTOSMsg;          //double buffer rx
	TOS_Msg msg;				//tx buffer
	TOS_MsgPtr ptrmsg;   // message ptr
	uint8_t bTOSMsgBusy;
	uint8_t TOSMsgType;
	TOS_MsgPtr pNETTOSMsg;	//global incomming message for statemachine
	uint8_t bNXPMsgBusy;	//processing NPX message
	uint8_t bBCASTMsg;
	uint8_t bAckMessage;	 //acknowlege Newtwork messages
	uint16_t wTXReqDelay;
	//Netprogramming stuff
	uint8_t cCommand; //current command
	uint8_t cSubCommand; //extendedcurrent command
	uint8_t bCommandOK; //current command processed ok
	uint16_t wProgramID;
	uint16_t wPIDinFLASH;
	uint16_t wCapsuleNo; //code capsule number
	uint16_t wNofCapsules;	//expected number of capsules
	uint16_t wNofLostCapsules;	  //
	uint8_t bCIDMissing;
	uint16_t wCIDMissing;	
	uint16_t wCIDMissingPrevious;
	uint16_t wEEProgStart;	//start location in EEFlash
	uint8_t btest;           //true if test pattern is to be used
	uint16_t itest;            //test pattern incrementer

	uint8_t bEEWriteEnabled;			//EEFLASH is WRITE Enabled
	uint8_t bEEWriteContinuous;
	uint16_t EE_PageW;      //current EEPROM page written 
	uint16_t wEE_LineW;      //current/final eprom line written 
	uint16_t wEE_LineR;
//	uint16_t EE_LineEndR;      //last EEROMline to read 
  	uint8_t cLineinPage;			//line# within Page being read
    uint8_t bEELine1;          //1st line of 2 being written
            
	uint8_t bEELineWritePending;
	uint8_t bEELineReadPending;
	uint8_t bEEPROMBusy;  //0 if EPROM available for write 
	uint16_t read_line;          //line in eeprom read from
	uint16_t wLastEEPage;		//nof lines to log(page is 256bytes=16lines=32samples)

	EEBUF_line_struct EELineBuf;	//for readout
	uint8_t ELBuff[ELBUFF_SIZE];
	uint8_t bELBuffAWE;	//BufferA or B selected for write enable
	uint8_t bELBuffFull;

        bool DoneEveryCapsules;

//------------------------ LOCAL FUNCTIONS -----------------------------------
void fNPXSysVarInit();		//init vars to default
void fNPXStartDownload(TOS_MsgPtr msgptr);
void fNPXS0RecBuild();

void fNPXSRECDownload(TOS_MsgPtr msgptr);
//void fNPXBCastStartDownload(TOS_MsgPtr msgptr);
uint8_t fNPXSRECParse(TOS_MsgPtr msgptr);
void fNPXSRECStore(TOS_MsgPtr msgptr);
uint8_t fNPXSRecDownloadDone();
void fNPXSRECUpdate(TOS_MsgPtr msgptr);
uint8_t fNPXGetNextEmptySREC(uint16_t wCurrentCID);
void fProcessMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing);
void fReqMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing);
void fDownloadComplete(uint16_t wlPID);

void fNPXSendStatus();		//Sendstatus function
void fNPXInSystemProgramExec(TOS_MsgPtr msgptr);
void fNPXGetEEProgID(uint16_t wEEStart);

void fNPXGetProgramID(TOS_MsgPtr msgptr);
void fNPXSendPIDStatus(uint16_t wPID);

/****************************************************************************
 * Initialize the component. Initialize
 *
 ****************************************************************************/
  command result_t StdControl.init() {
    fNPXSysVarInit();				//set vars to init
    call GenericCommCtl.init();
    call EEPROMControl.init();
    call Leds.init();
   	return SUCCESS;
  }
 /****************************************************************************
 * Start the component..
 *
 ****************************************************************************/
  command result_t StdControl.start(){
    call GenericCommCtl.start();
    return SUCCESS;	
  }
 /****************************************************************************
 * Stop the component. Stop the clock
 *
 ****************************************************************************/
  command result_t StdControl.stop() {
    return SUCCESS;
  }
 /****************************************************************************
 * NPX__ISP: 
 * task to writes GROUP_ID and TOS_ID into eeprom, then invoke bootloader
 ****************************************************************************/
task void NPX_ISP() {
//setup parameters to pass
//R20,R21 wProgId, R22:PageStart, R24,25:nwProgID
   uint16_t wPID;
   //uint8_t cTemp;
   uint8_t *pAddr;

   cli(); //turnoff interrupts

// Store GROUPID and LOCAL ADDRESS into EEPROM
// note:this function blocks &waits until EEPROM is available

    eeprom_write_byte ((uint8_t*)(AVREEPROM_GROUPID_ADDR), TOS_AM_GROUP);
    eeprom_write_byte ((uint8_t*)(AVREEPROM_LOCALID_ADDR), TOS_LOCAL_ADDRESS);//lsbyte
	eeprom_write_byte ((uint8_t *)AVREEPROM_LOCALID_ADDR+1, (TOS_LOCAL_ADDRESS>>8));//msbyte
	//The following should really only be done when ISP has loaded the program...
    pAddr = (uint8_t*)(&wProgramID);	 //the prog id			   
	eeprom_write_byte ((uint8_t*)(AVREEPROM_PID_ADDR), *pAddr++);//lsbyte
	eeprom_write_byte ((uint8_t*)(AVREEPROM_PID_ADDR+1), *pAddr);//msbyte
  	while (!eeprom_is_ready()); //wait for eeprom to finish
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
    wPID = ~wProgramID;	 //inverted prog id
    __asm__ __volatile__ ("movw r20, %0" "\n\t"::"r" (wPID):"r20", "r21");

    wPID = wEEProgStart;
    __asm__ __volatile__ ("movw r22, %0" "\n\t"::"r" (wPID):"r22", "r23");

    wPID = wProgramID;	 //the prog id
    __asm__ __volatile__ ("movw r24, %0" "\n\t"::"r" (wPID):"r24", "r25");

//call bootloader - it may never return...
    __asm__ __volatile__ ("call 0x1F800" "\n\t"::);		//bootloader at 0xFC00
 //   __asm__ __volatile__ ("clr r1" "\n\t"::);
#endif

//if here reboot/reprog failed   
	bCommandOK= CMD_STATE_BADCHECKSUM;	 //default we don't recognize it
	if(bAckMessage)
		fNPXSendStatus();

	return;
}
	
/*****************************************************************************
TOS TASK 
Write specified buffer  out to EEPROM
On completion, the CORRECT buffer FULL status will be cleared...
Need a PENDING flag to keep trying until EEPROM ready or timeout

bELBuffAWE	[0,1] points to 1 of 2 256 byte buffers in EEPROM
wEE_LineW	Absolute line# as starting address for written data. Actually modulo
			16 because only 16 lines (16bytes/line * 16lines = 1page) are used.
			But wEE_LineW as an absolute line# is used elsewhere in the TestBench

ELBUFF_NOFLINES
			Number of Lines (16bytes) to write.

ELBuff		Data buffer. Must be 16*ELBUFF_NOFLINES bytes deep

When reach end of a Page Buffer (256bytes) we switch buffers for writing
And then EEWRITE_LINEDONE handler will flush out the previous buffer to EEPROM's
internal ROM

Notes"
1. hINSTANCE is a constant - should be variable set by StartEEPROM
!!!!This is handled differently (correctly) in NESC	!!!!


*****************************************************************************/
#define EEBufA 0	//Buffer IDs
#define EEBufB 1	//Buffer IDs

task void NPX_wEE_LineWrite() {
	uint8_t iRet;
 	if( bEEWriteEnabled ) {
 	 if( !bEEPROMBusy){

	//write the first of a 2line sequence
	  bEELine1 = TRUE;	// 1st line
	  iRet = call EEPROMWrite.write(wEE_LineW, (uint8_t*)&ELBuff );

// ADD RETRY TIMEOUT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	  if(!iRet)	//failed
    		post NPX_wEE_LineWrite(); //keep trying
		
	  bEEPROMBusy= TRUE;
  
	  //Handle variable number of line per buffer
	  wEE_LineW++;	 //track absolute line number
	  cLineinPage++; //next line within page


	  if( cLineinPage >= NOFLINESPERPAGE ) { //at page boundary
		bELBuffAWE = !bELBuffAWE; //toggle line buffer for writing lines
		bELBuffFull = TRUE; //tells LineDone handler to flush internal buffer
		cLineinPage = 0;	//reset line counter
		} 
   	}
		else	 //try again
    		post NPX_wEE_LineWrite();
 	}
}//tos-task
/*****************************************************************************
NPX_STATEMACHINE
Handles various states during SREC Download.
-On each SREC capsule received ()
	writes srec line if EEPROM not busy, otherwise loops until ready.

-SYS_DL_FAIL
Cleansup / releases EEPROM resource
Send message to Host
Goes into IDLE
******************************************************************************/
task void NPX_STATEMACHINE() {
	uint8_t cNextState;
	uint8_t bRePost;
	uint8_t bRet;
	uint16_t *wptr;

	cNextState = sSYSState; //default is no change
	bRePost = FALSE; //by default we do not repeat this statemachine task
	switch( sSYSState )
	{

	case SYS_REQ_CIDMISSING: //get control back
		//if the requested PID does not match our current PID we ignore the request
		wptr = (uint16_t *)&(pNETTOSMsg->data[TS_PID]);
		if( *wptr != wProgramID ) {
			bCommandOK = CMD_STATE_BADSEQUENCE;
			cNextState = SYS_ACK;
			bRePost = TRUE;
		}else {
		 	cNextState = SYS_GET_CIDMISSING;
			//Release EEFLASH
		     bRet = call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke NPX statemachine
			 if(bRet==FAIL) 
				bRePost = TRUE; //endWrite  will not signal enddone	go directly to next state
			}
		break;

	case SYS_GET_CIDMISSING:
		sSYSMState = SYSM_UPDATE;
	 	fNPXGetNextEmptySREC(wCIDMissingPrevious);//this starts reading sequentially thru EEFLASH
		cNextState = sSYSState;
		break;

	case SYS_DL_START:
		cNextState = SYS_DL_START0; //this is a pseudo state waiting for APP to ack start dl request
	    fNPXStartDownload(pNETTOSMsg); //prep & call app with DL request.Determines next state
		cNextState = sSYSState; //SYS state maybe changed by functioncall
		break;

	case SYS_DL_START1: //get system into clean known state
	 	cNextState = SYS_DL_START2;
		//Release EEFLASH unconditionally to get into clean state
	     bRet = call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke NPX statemachine
		 if(bRet==FAIL) 
			bRePost = TRUE; //no endWrite to signal enddone so go directly to START1
		break;

	case SYS_DL_START2: //
		//Clear flags
		bEEWriteContinuous = FALSE; 
		bEEWriteEnabled = FALSE;        // eeprom writing enabled flag
		bEEPROMBusy = FALSE;     //reset any pending eprom writes 
		//lock down EEPROM resource
	    bRet = call EEPROMWrite.startWrite(); //a function call - no event signal
	    if( !bRet )	{	  //eeprom not available
			bCommandOK = CMD_STATE_BUSY;
			sSYSState = SYS_DL_FAIL;
		} else {
			bEEWriteContinuous = TRUE; //donot release EEFLASH after each srec write
			bEEWriteEnabled = TRUE;        // eeprom writing enabled flag
			bEEPROMBusy = FALSE;     //reset any pending eprom writes 
			wEEProgStart = EE_PageW<<4;//the starting point in EEFlash
			wCapsuleNo = 0;		//update current capsule# -Network capsule# starts at 1
			//fNPXS0RecBuild(); //fNPXS0RecBuild sets up for EEFLASH write of S0

			bCommandOK = CMD_STATE_DONE;
			sSYSMState = SYSM_DOWNLOAD;	 //Entered DOWNLOAD Major State
			cNextState = SYS_ACK;	 //we are ready to accept SREC Downloads
		}
		bRePost = TRUE;		//goto next state	 
		break;

	case SYS_DL_SRECWRITE: //write SREC in DOWNLOAD Mode
			fNPXSRECStore(pNETTOSMsg);	//storesrec
			cNextState = sSYSState; //whatever fNPXSRECStore did to sSYSState
			break;

	case SYS_UP_SRECWRITE: //write SREC in UPDATE Mode
			fNPXSRECUpdate(pNETTOSMsg);
			cNextState = sSYSState; //whatever fNPXSRECUpdate did to sSYSState
			break;

	case SYS_EEFLASH_WRITE:
	  #ifdef PLATFORM_MICA2DOT
	  call Leds.redOn();
	  #endif
	  call Leds.yellowOn();
		if( bEELineWritePending ){ 	//waiting to post a task to EEWrite
		   	if( !bEEPROMBusy ){
				post NPX_wEE_LineWrite();//write buffer out to EEPROM
				bEELineWritePending = FALSE;
		     	} else //EEPROM is busy
					bRePost = TRUE;	//re-execute NPX_STATEMACHINE only if busy
			}//writepending
			else { //not pending 
				cNextState = SYS_EEFLASH_WRITEDONE; //nothing to so so endit
				bRePost = TRUE;
				}	  
		break;

	case SYS_EEFLASH_WRITEDONE:
		cNextState = SYS_ACK; //where we go next
		if( !bEEWriteContinuous	) { //release the resource after each write
            if( bEEWriteEnabled )
            	 call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke next state
			else
				bRePost = TRUE;	//chain to next state
		} else bRePost = TRUE; //chain to next state
    	call Leds.yellowOff();           //diagnostic 
		break;
	
	case SYS_DL_END:
			//release EEPROM resource
			cNextState = SYS_DL_END_SIGNAL;
            if( bEEWriteEnabled )
            	 call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke NPX statemachine
			else
				bRePost = TRUE;
			break;

	case SYS_DL_END_SIGNAL:	
	 //signal application that download process is finished	-good
	 	bCommandOK = CMD_STATE_DONE; 
		wCapsuleNo = 0; //reset current Capsule#
		signal Xnp.NPX_DOWNLOAD_DONE(wProgramID,TRUE, EE_PageW);
		cNextState = SYS_ACK;
		sSYSMState = SYSM_IDLE;	
		bRePost = TRUE;	//re-execute NPX_STATEMACHINE
		break;

	case SYS_DL_FAIL:
			//release EEPROM resource if required
			cNextState = SYS_DL_FAIL_SIGNAL;
            if( bEEWriteEnabled )
            	 call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke NPX statemachine
			else
				bRePost = TRUE;
			break;

	case SYS_DL_FAIL_SIGNAL:
			if(bAckMessage)
				fNPXSendStatus();
			sSYSMState = SYSM_IDLE;
			wCapsuleNo = 0; //reset current Capsule#
			//Tell client download has finished - badly
			signal Xnp.NPX_DOWNLOAD_DONE(wProgramID,FALSE, EE_PageW);
			cNextState = SYS_ACK;		// should wait for EEPROM flush buffer to fini?
			bRePost = TRUE;	//re-execute NPX_STATEMACHINE
		break;

		case SYS_IDLE_RENTRY:		//resume idle conditions
			cNextState = SYS_IDLE;
  		   	bNXPMsgBusy = FALSE;
			//call Leds.greenOn();       
			break;

		case SYS_IDLE:
 			 bNXPMsgBusy = FALSE;
			break;

		case SYS_ISP_REQ:
			wptr = (uint16_t *)&(pNETTOSMsg->data[TS_PID]);
			wProgramID = *wptr++;
			EE_PageW = EE_PAGE_START;
			wEEProgStart = EE_PageW<<4;//the starting point in EEFlash
			//check EEFLASH Capsule #1 (2lines per capsule)to verify this programID is present
			wEE_LineR = wEEProgStart+2;	//Capsule#0 is legacy/expansion-future
		   	bEELineReadPending = TRUE;	//statemachine handles retries etc
		   	cNextState = SYS_ISP_REQ1;	
			bRePost = TRUE;
			break;


		case SYS_ISP_REQ1:
		case SYS_GETNEXTCID:	   //have read 1st half of srec from FLASH
			if( bEELineReadPending ){
				#ifdef PLATFORM_MICA2DOT
				call Leds.redOn();	   //led off during read/missing capsule check, ON at end if ok
				#endif
				call Leds.yellowOn();       
				call EEPROMRead.read(wEE_LineR, (uint8_t*)&ELBuff );
				}
			//if fail do what? - go idle?
			break;

		case SYS_ACK: //send ack to network if required and then go idle
			if(bAckMessage ) //acknowledge to network
				fNPXSendStatus();
 			bNXPMsgBusy = FALSE;
    		call Leds.redOff();           //diagnostic 
			cNextState = SYS_IDLE;
			break;	

		case SYS_GETDONE:
			call Leds.yellowOff();       
		   //	sSYSMState = SYS_IDLE;		//no ack and leaves LED ON
			cNextState = SYS_IDLE;
  		   	bNXPMsgBusy = FALSE;
			break;



		case SYS_BEACON:
    	 //	call Leds.redOn();           //diagnostic 
		 //	fNPXSendStatus();
			if( !bTOSMsgBusy )
				fProcessMissingCapsule(wProgramID, wCapsuleNo);
			bRePost = TRUE;	//re-execute NPX_STATEMACHINE
    	 //	call Leds.redOff();           //diagnostic 
			break;

		default:
		 break;
	}	//switch
// update state
	sSYSState = cNextState; //this updates BEFORE any new tasks start
	if( bRePost )
		post NPX_STATEMACHINE(); //try again
return;
}//TASK NXP Statemachine	

/*****************************************************************************
 receive()
 - message from newtork
******************************************************************************/
event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msgptr) {
   int (*ptr)();
  uint16_t *wptr;
  uint8_t cNextState;
  TOS_MsgPtr pPrevious;

//Filter for correct GROUP_ID and MOTEID for GSK compatibility
	if (msgptr->group != TOS_AM_GROUP) return msgptr;
	if ((msgptr->addr != TOS_BCAST_ADDR) && (msgptr->addr != TOS_LOCAL_ADDRESS) )return msgptr;

  if (bTOSMsgBusy) return msgptr;
  if (bNXPMsgBusy) return msgptr;
	//call Leds.yellowOff();
    call Leds.greenOff();           //leds off
    call Leds.redOn();           //diagnostic - turns off at exit of statemachine SYS_ACK
  bNXPMsgBusy = TRUE;
  pPrevious = pNETTOSMsg;	//save ptr to previous buffer
  pNETTOSMsg = msgptr;	  //point to new buffer
  cNextState = sSYSState; //statemachine updates
// -------LOCAL COMMANDS addressed to this specific node
  if( (msgptr->addr == TOS_LOCAL_ADDRESS) )
	{
	cCommand = msgptr->data[TS_CMD]; //save the netprog command ID
	cSubCommand = msgptr->data[TS_SUBCMD]; //save the  command ID
	bCommandOK= CMD_STATE_UKNOWN;	 //default we don't recognize it
	bBCASTMsg = FALSE;
	bAckMessage = TRUE;
	switch (cCommand)	     //was [4]
	{
		case CMD_RST:	 //REBOOT
		   ptr = 0;
			ptr();
			break;

		case CMD_DOWNLOAD_STATUS:
			bCommandOK= CMD_STATE_DONE;	 //status command req reqognized
			cNextState = SYS_ACK;
			break;

		case CMD_STATUS:	//Get node status
			bCommandOK= CMD_STATE_DONE;	 //status command req reqognized
			cNextState = SYS_ACK;
			break; 
			
		case CMD_START_DOWNLOAD: //Header info for a code download
//		    fNPXStartDownload(pNETTOSMsg);
			cNextState = SYS_DL_START;
			break;

		case CMD_DOWNLOADING:
			if(sSYSMState==SYSM_DOWNLOAD)
				cNextState = SYS_DL_SRECWRITE;
			else if (sSYSMState == SYSM_UPDATE)
				cNextState = SYS_UP_SRECWRITE;
			else cNextState = SYS_ACK; //ignore
		  break;

		case CMD_DOWNLOAD_COMPLETE:
			cNextState = SYS_DL_END;
			break;

		case CMD_ISP_EXEC:
			cNextState = SYS_ISP_REQ;
			break;

		case CMD_GET_CIDMISSING:
//			wptr = &(pNETTOSMsg->data[TS_PID]);	//tests are done in statemachine
//			wProgramID = *wptr;
			cNextState = SYS_REQ_CIDMISSING;
		 	break;


		case CMD_GET_PIDSTATUS:
			fNPXGetProgramID(pNETTOSMsg);
 			 bNXPMsgBusy = FALSE;
    		call Leds.redOff();           //diagnostic - turns off at exit 
			break;

		default:
//			call Leds.yellowOn(); 
			cNextState = SYS_ACK;
			break; //invalid command
	}//switch command
	sSYSState = cNextState;
	post NPX_STATEMACHINE(); //try again
	return pPrevious;	//TOS LOCAL COmmand exit  - return original buffer??
   } // if TOS_LOCAL_ADDRESS

// -------TOS_BCAST_ADDR COMMANDS addressed to this specific node
  if( (msgptr->addr == TOS_BCAST_ADDR) )
	{
	cCommand = msgptr->data[TS_CMD]; //save the  command ID
	cSubCommand = msgptr->data[TS_SUBCMD]; //save the  command ID
	bCommandOK= CMD_STATE_UKNOWN;	 //default we don't recognize it
	bBCASTMsg = TRUE;
	bAckMessage = FALSE;  //bydefault no message acknowledment
	switch (cCommand)	     //was [4]
	{

		case CMD_START_DOWNLOAD: //Header info for a code downloaf
			if( cSubCommand == TOS_LOCAL_ADDRESS )
				bAckMessage = TRUE; //acknowledge broadcast message
                        DoneEveryCapsules = FALSE;
			cNextState = SYS_DL_START;
			break;

		case CMD_DOWNLOADING:
			if( cSubCommand == TOS_LOCAL_ADDRESS )
				bAckMessage = TRUE; //acknowledge broadcast message
			if(sSYSMState==SYSM_DOWNLOAD)
				cNextState = SYS_DL_SRECWRITE;
			else if (sSYSMState == SYSM_UPDATE)
				cNextState = SYS_UP_SRECWRITE;
			else 
				cNextState = SYS_ACK;
		  break;

		case CMD_DOWNLOAD_COMPLETE:
			if( cSubCommand == TOS_LOCAL_ADDRESS )
				bAckMessage = TRUE; //acknowledge broadcast message
			cNextState = SYS_DL_END;
			break;

		case CMD_ISP_EXEC:
			cNextState = SYS_ISP_REQ;
			break;

		case CMD_GET_PIDSTATUS:
			fNPXGetProgramID(pNETTOSMsg);
 			 bNXPMsgBusy = FALSE;
    		call Leds.redOff();           //diagnostic - turns off at exit 
			break;

		case CMD_GET_CIDMISSING:
 			wptr = (uint16_t*)(&(msgptr->data[TS_PID]));
			if( (cSubCommand == TOS_LOCAL_ADDRESS) || (!cSubCommand) ){ //for this mote or all motes (subC==0)
				bAckMessage = TRUE; //acknowledge broadcast message
			}
			if( wProgramID != *wptr)
				bAckMessage = FALSE; //keep quiet if incorrect ProgramID - but call statemachine for cleanup

                        // added so that the PC side gets reply.
                        if (DoneEveryCapsules &&
                            cSubCommand == TOS_LOCAL_ADDRESS) {
                                fDownloadComplete(wProgramID);
                        } else {
                                cNextState = SYS_REQ_CIDMISSING;
                        }

			break;


	default:
			cNextState = SYS_ACK;
            break; //invalid command
	}//switch command
	sSYSState = cNextState;
	post NPX_STATEMACHINE(); //try again
	return msgptr;	//TOS broadcast COmmand exit  - return original buffer??
   } // if TOS_BCAST

	sSYSState = cNextState;
  return pPrevious;
}//NPX_TOSMsg_Rx
/*****************************************************************************
SendDone
TOS Message Sent
*****************************************************************************/
event result_t SendMsg.sendDone(TOS_MsgPtr msg_rcv, bool success) {
    
    bTOSMsgBusy = 0;            //broadcast message complete
    ptrmsg = msg_rcv;               //hold onto the buffer for next message

	switch( TOSMsgType )  {
		default:
			  TOSMsgType = MSG_IDLE;              //command message complete
			break;
	}
	return(1);
	
}//MSG_SEND_DONE

/*****************************************************************************
 writeDone
 - EEPROM finished writing a line of data to eprom buffer
 If buffer is full, execute EEPROM command to flush buffer into ROM
 Note that during this flush, line writing can continue by writing into alternate
 buffer.
 bEEPROMBusy is NOT set during FLUSH operation.
 Need to add EEPROM_GetStatus to check EEPROM is idle before doing FLUSH
 
 A flush of 256byte page takes 20mSec + some overhead 
 20msec/256bytes = 78uSec/byte or ~100Kbit/sec
*****************************************************************************/
event result_t EEPROMWrite.writeDone(uint8_t *buf){
  uint8_t cRet;
	if(bEELine1 )	{  //write 2nd line out-still busy
		bEELine1 = FALSE;
	    cRet = call EEPROMWrite.write(wEE_LineW, (uint8_t*)&ELBuff[ELBUFF_SIZE/2]);
        //wEE_LineW++;	 //EELine now maintained by SREC Parser
		return( TRUE );
    }  
	bEEPROMBusy=0;
	post NPX_STATEMACHINE(); //execute the NPX Statemachine for next state
    return( TRUE) ; 
}
/*****************************************************************************
 endWriteDone()
 -  finished use of  eeprom for writing - release resource
*****************************************************************************/
event result_t EEPROMWrite.endWriteDone(result_t success){
	bEEWriteContinuous = FALSE;
	bEEWriteEnabled = 0;          //disable writing
	post NPX_STATEMACHINE(); //execute the NPX Statemachine for next state
	return(success);	 //1=success
}
/******************************************************************************
* NPX_SET_IDS
* -Check to see if Mote_Id and Group_Id are in Atmega eeprom. If so, use them
* -If values returned have 0xff byte values then eeprom was erased and 
*  never written. Default to original values stored in Atmega code space.
* -If values returned <>0xff then assume the Mote_Id and Group_Id were 
*  stored in eeprom during net reprogramming.
 ******************************************************************************/
command result_t Xnp.NPX_SET_IDS(){
  uint8_t  cTemp;
  uint16_t wTemp;
    if((cTemp=eeprom_read_byte ((uint8_t *)AVREEPROM_GROUPID_ADDR)) != 0xFF )
    	TOS_AM_GROUP = cTemp;

    if((wTemp=eeprom_read_word ((uint16_t *)AVREEPROM_LOCALID_ADDR)) != 0xFFFF )
    	TOS_LOCAL_ADDRESS = wTemp;
#ifdef JTAG
    TOS_LOCAL_ADDRESS = TOS_LOCAL;               //Jtag debug
#endif
    return SUCCESS;
}

/******************************************************************************
******************************************************************************/
command uint16_t XnpConfig.getProgramID()
{
  return eeprom_read_word( (uint16_t*)AVREEPROM_PID_ADDR );
}

command void XnpConfig.saveGroupID()
{
  eeprom_write_byte((uint8_t*)(AVREEPROM_GROUPID_ADDR), TOS_AM_GROUP);
}


/******************************************************************************
NPX_SENDSTATUS
Client can send a status message to Network - diagnostic
******************************************************************************/
 command result_t Xnp.NPX_SENDSTATUS(uint16_t wAck ) {
	uint8_t bRet;
	wCapsuleNo = wAck; //code capsule number
	fNPXSendStatus();
	return(1);
	}//send
/*****************************************************************************
NPX_ISP_REQ
-Allows application to invoke In System Programming
Caller must supply Program ID and its inverse.
If these do compare function returns - avoids inadvertent call/jump
******************************************************************************/
command result_t Xnp.NPX_ISP_REQ(uint16_t wProgID, uint16_t wEEPageStart, uint16_t nwProgID){
	if( wProgID != ~nwProgID )
		return(FALSE);
	wEEProgStart = wEEPageStart<<4;	  //translate to line number
	wProgramID = wProgID;
	fNPXGetEEProgID(wEEProgStart); //check valid progid and invoke ISP
    return(SUCCESS);  //not quite correct - wait for result of GetEEProgID
}
/*************************************************************************
fStartDownload
Get header info for upcoming code download
Signal CLient application for Request
*************************************************************************/
void fNPXStartDownload(TOS_MsgPtr msgptr)  {
  uint16_t *wptr;
  //TOS_MsgPtr *wptr;

  // CSS: ^-- Whoever changed wptr from uint16_t* to TOS_MsgPtr* is dumb and
  // should learn not to poke at and commit code when they don't understand
  // and obviously must know they don't understand pointers.  Both
  // wProgramID and wNofCapsules were garbage.  To that person: each time
  // you do that again, I kill you.

		wptr = (uint16_t*)(&(msgptr->data[TS_PID]));
		wProgramID = *wptr++;
		wNofCapsules= *wptr;
		//Initialize EEPROM writing
		wEE_LineW = EE_LINE_START;      //reset eprom write count
		EE_PageW = EE_PAGE_START;      //reset eprom page
		
		wCIDMissingPrevious = 1;
		wCIDMissing = 1;
		bCIDMissing = FALSE;
		bCommandOK = CMD_STATE_BUSY;	 //assume we are busy
		//Ask client to stop/suspend main application etc
		//	-16 capsules per EEPage

		signal Xnp.NPX_DOWNLOAD_REQ(wProgramID,EE_PageW, wNofCapsules<<4);

		//now wait for client to respond. If doesnt should have a timeout and goto idle?
	return;
}//fNPXStartDownload

/******************************************************************************
 NPX_DOWNLOAD_ACK:
 Acknowledge from Client to proceed/cancel Netprogramming pending download
 request
******************************************************************************/
 command result_t Xnp.NPX_DOWNLOAD_ACK(uint8_t cAck ) {
	//uint8_t bRet;

	if( (sSYSState != SYS_DL_START ) ){ //bogus call from app!
		sSYSState = SYS_IDLE;
		bCommandOK = CMD_STATE_WRONGSTATE;
		return(FALSE);
		}
		
	if( !cAck ) {
		//Client is not allowing download
		bCommandOK = CMD_STATE_BUSY;
		sSYSState = SYS_ACK;
	}else {
	 	//Check status of Battery and return OK/Bad status
		//Reset/init all states and start
		bCommandOK = CMD_STATE_BUSY;  //still processing the start request
		sSYSState = SYS_DL_START1;
	}//ack is OK
	post NPX_STATEMACHINE();//get going
	return(FALSE);
 }
/******************************************************************************
 fNPXS0RecBuild:
 Write an S0 record and go...
******************************************************************************/
void fNPXS0RecBuild(){

	wEEProgStart = EE_PageW<<4;//the starting point in EEFlash
	wCapsuleNo = 0;		//update current capsule# -Network capsule# starts at 1
	wPIDinFLASH = wProgramID;
//Write a pseudo S0 record w/ ProgramID into Flash
	ELBuff[POS_PID] = (uint8_t) wProgramID;	   //lsbyte of ProgID
	ELBuff[POS_PID+1] = (uint8_t)(wProgramID>>8);  //ms of address
	ELBuff[POS_CID] = 0;	 //capsule number is 0 
	ELBuff[POS_CID+1] = 0;
	ELBuff[POS_STYPE] = SREC_S0;
	//srec9 only has 2byte address
	ELBuff[POS_SNOFB] = 3; //progid plus crc
	ELBuff[POS_S0_PID] = (uint8_t)wProgramID;	   //lsbyte of ProgID
	ELBuff[POS_S0_PID+1] = (uint8_t)(wProgramID>>8);  //ms of address
	ELBuff[POS_S0_CRC] = 0xAA; //progid plus crc
	wEE_LineW = wEEProgStart;	 //2 lines per srec	-1st line is S0

	bEELineWritePending = TRUE;	//main state machine handles posting task and busy retries
   	sSYSState = SYS_EEFLASH_WRITE;
	post NPX_STATEMACHINE();//store srec to eeprom

	bCommandOK = CMD_STATE_DONE;
	return;
}//fnpx_downloadgo
//======================= LOCAL FUNCTIONS ==================================
/********************************************************************************************
fNPXGetProgramID
Compare current applications ProgramID with caller	
If request 	TS_MSGDATA parameter is TRUE , acknowledge if PIDs match
If request 	TS_MSGDATA parameter is FALSE , acknowledge if PIDs do NOT match

*******************************************************************************************/
void fNPXGetProgramID(TOS_MsgPtr msgptr){

//Get programID from ATMEL EEPROM and compare with Network Requested PROGID
 	uint8_t bPIDMatch;
 	uint8_t bIFMatch;
 	uint16_t wlPID;
 	uint16_t *wptr;
 	uint16_t wTemp;   

	bIFMatch = msgptr->data[TS_MSGDATA];
	wptr = (uint16_t*)(&(msgptr->data[TS_PID]));
	wTemp = *wptr;
    wlPID = eeprom_read_word ((uint16_t *)AVREEPROM_PID_ADDR);
    bPIDMatch = (wTemp== wlPID);
	bCommandOK = CMD_STATE_DONE;
	if( bBCASTMsg ) {//only respond according to flag
	   if( (bIFMatch && bPIDMatch) | (!bIFMatch && !bPIDMatch))	//re match
		fNPXSendPIDStatus(wlPID);
		}//broadcast
	else
		fNPXSendPIDStatus(wlPID);
}


/*************************************************************************
fNPXSRECStore
Got a code capsule containing 1 srec from radio
[0]:commandid
[1.2]:program id
[3:4]:nofcapsules (srecords)

Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.
NOTES
1.Desireable to reuse msgptr buffer vs EELinebuffer to avoid locking up RAM
space that is used only during boot-download.
*************************************************************************/
void fNPXSRECStore(TOS_MsgPtr msgptr)  {
	//uint8_t bRet;
	//uint8_t j;
	unsigned short wTemp;
	//uint8_t cLen;
	uint8_t cSRecType;
	uint8_t bSRecValid;
	//uint8_t bFini = FALSE;
	uint16_t *wptr;

	if( sSYSMState != SYSM_DOWNLOAD ) {
			bCommandOK = CMD_STATE_WRONGSTATE; //
			sSYSState = SYS_ACK;
			post NPX_STATEMACHINE();//exec new state
			return;	//back to statemachine
			}

	wptr = (uint16_t *)&(msgptr->data[TS_PID]);
	wTemp = *wptr;
	if( wTemp != wProgramID ) {	  //not the same ProgramID so ignore
			bCommandOK = CMD_STATE_BADSEQUENCE;
			sSYSState = SYS_ACK;
			post NPX_STATEMACHINE();//exec new state
			return;	 //back to statemachine  
			}

	//Get and check capsule #

	wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
	wTemp = *wptr;
	if( wTemp != wCapsuleNo+1 ) {	//missed a capsule?
	   if(!bCIDMissing ) {//first one missed?
		   	bCIDMissing = TRUE;
			wCIDMissing = wCapsuleNo+1;
		   	wCIDMissingPrevious	= wCIDMissing;
		   	}
		wNofLostCapsules = wTemp-wCapsuleNo-1;
	}//here if wrong capsule # but we continue on...

	wCapsuleNo = wTemp;		//update current capsule#

	cSRecType = msgptr->data[TS_TYPE];
	bSRecValid = fNPXSRECParse( msgptr );		//parse the srec
	if(!bSRecValid) {
		bCommandOK = CMD_STATE_BADSTYPE;
		sSYSState = SYS_ACK;
	   	post NPX_STATEMACHINE();//exec new state
		return;	 //back to statemachine  
	}//!srecvalid

	//if srec parsed then save to external flash   -Capsule starts at 1
	wEE_LineW = wEEProgStart + (wCapsuleNo<<1);	 //2 lines per srec
	bCommandOK = CMD_STATE_DONE;
	
	bEELineWritePending = TRUE;	//main state machine handles posting task and busy retries
	sSYSState = SYS_EEFLASH_WRITE;
   	post NPX_STATEMACHINE();//store srec to eepromn
return;
} //fnpx_srecstore
/*************************************************************************
fNPXSRECUpdate
Got an update code capsule containing 1 srec from radio
Replaces a missing or bad srec in EEFLASH 

Verifies correct PID
Verifies a valid srec
Enables EEFLASH Write
write
Release EEFLASH

Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.
NOTES

*************************************************************************/
void fNPXSRECUpdate(TOS_MsgPtr msgptr)  {
	uint8_t bRet;
	//uint8_t j;
	unsigned short wTemp;
	//uint8_t cLen;
	uint8_t cSRecType;
	uint8_t bSRecValid;
	//uint8_t bFini = FALSE;
	uint16_t *wptr;

	if( sSYSMState != SYSM_UPDATE ) {
			bCommandOK = CMD_STATE_WRONGSTATE;
			sSYSState = SYS_ACK;
		   	post NPX_STATEMACHINE();//exec new state
			return;
			}
	wptr = (uint16_t *)&(msgptr->data[TS_PID]);
	wTemp = *wptr;
	if( wTemp != wProgramID ) {	  //not the same ProgramID downloading
			bCommandOK = CMD_STATE_BADSEQUENCE;
			sSYSState = SYS_ACK;
		   	post NPX_STATEMACHINE();//exec new state
			return;	   
			}

	//Get and check capsule #

	wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
	wCapsuleNo = *wptr;		//update current capsule#

	cSRecType = msgptr->data[TS_TYPE];
	bSRecValid = fNPXSRECParse( msgptr );		//parse the srec
	if(!bSRecValid) {
		bCommandOK = CMD_STATE_BADSTYPE;
		sSYSState = SYS_ACK;
	   	post NPX_STATEMACHINE();//exec new state
		return;
	}//!srecvalid

	//if srec parsed then save to external flash   -Capsule starts at 1
	wEE_LineW = wEEProgStart + (wCapsuleNo<<1);	 //2 lines per srec
	bCommandOK = CMD_STATE_DONE;
	
	bEELineWritePending = TRUE;	//main state machine handles posting task and busy retries
    if( !bEEWriteEnabled ) { //here if doing random SREC writes so must Writeenable the EEFLASH
    	bRet = call EEPROMWrite.startWrite();
	    if( !bRet )	{	  //eeprom not available
			bCommandOK = CMD_STATE_BUSY;
			sSYSState = SYS_ACK;
		   	post NPX_STATEMACHINE();//exec new state
			return;
			}
		}//!beeLocked
	bEEWriteEnabled = 1;        // eeprom writing enabled flag
	bEEWriteContinuous = FALSE; //MUST release EEFLASH WriteEnable to do future reads on EEFLASH

	sSYSState = SYS_EEFLASH_WRITE;
	post NPX_STATEMACHINE();//store srec to eepromn
return;
} //fnpx_srecupdate
/*************************************************************************
fNPXSRecDownloadDone
End of broadcast srec download.
Network will interrogate motes for missing packets
cleanup regardless of state - this function can also be used to abort

*************************************************************************/
uint8_t fNPXSRecDownloadDone() {
	sSYSState = SYS_DL_END;//we are finished....flush eeprom buffer 
	sSYSMState = SYSM_IDLE;
	   
	post NPX_STATEMACHINE();//fetch srec from eeprom flash
return(1);
}//fNPXSrecDownloadDone
/*************************************************************************
fNPXGetEEProgID
Read the ProgramID currently in the External EEFLASH
*************************************************************************/
void fNPXGetEEProgID(uint16_t wEEStart) {
	wEE_LineR = wEEStart;
   	sSYSState = SYS_ISP_REQ;	
   	bEELineReadPending = TRUE;	//main state machine handles posting task and busy retries
	post NPX_STATEMACHINE();//fetch srec from eeprom flash
	return;
}
/*************************************************************************
fNPXGetNextEmptySREC
Starte/Resume Scan thru EEPROM from specified point and starts search for next missing srec.
NOTES
1.Need terminator (S9 record) indicating end of program
2. Actual work is done in READ_DONE 
3. Must have released FLASH from writing
*************************************************************************/
uint8_t fNPXGetNextEmptySREC(uint16_t wCurrentCID) {
//	VAR(wEEProgStart2) = wEEProgStart+2;
  call Leds.greenOff();           //diagnostic 
	wCapsuleNo = wCurrentCID;	  //where we are...
	wEE_LineR = wEEProgStart+ (wCurrentCID<<1);	 //2 lines per srec	-1st line is S0
   	sSYSState = SYS_GETNEXTCID;	
   	bEELineReadPending = TRUE;	//main state machine handles posting task and busy retries
	post NPX_STATEMACHINE();//fetch srec from eeprom flash
	return(TRUE);
}
/*************************************************************************
EEPROM_READ_DONE
EEPROM read record completed.
Handle per current state
*************************************************************************/

event result_t EEPROMRead.readDone(uint8_t *pEEB, result_t result){

uint16_t* pW;
uint16_t	wCID,wPID;

bEELineReadPending = FALSE;	//main state machine handles posting task and busy retries
call Leds.redOff();           //diagnostic=LED on during read now off 
switch (sSYSState)
{
#ifdef new1
case SYS_GET_EEPID: //read EEFLASH program ID and store
	pW = &pEEB[POS_PID];
	wPIDinFLASH = pW;
	break;
#endif
case SYS_ISP_REQ1: //check the EEFLASH programid matches the ISP requested PID
	pW = (uint16_t*)(&pEEB[POS_PID]);
	if( *pW == wProgramID ) { //this matches so invoke ISP
		bCommandOK = CMD_STATE_DONE;
		post NPX_ISP();
	}else
	{  //programids do not match - donot invoke ISP
		bCommandOK = CMD_STATE_BADSEQUENCE;
	}
	sSYSMState = SYSM_IDLE;	//reset state because SYS_ACK does not
	sSYSState = SYS_ACK;	//we are finished-turnoff led
	post NPX_STATEMACHINE();//fetch srec from eeprom flash
	break;

case SYS_GETNEXTCID:  //searching for bad/missing srecs
//check correct ProgramID and expected Capsule ID
	pW = (uint16_t*)(&pEEB[POS_CID]);
	wCID = *pW;	   //type cast
	pW = (uint16_t*)(&pEEB[POS_PID]);
	wPID = *pW;
	if( (wPID != wProgramID ) | (wCID != wCapsuleNo) )
	{ //something is wrong
		fProcessMissingCapsule(wPID, wCapsuleNo);
	} else //ProgramID and CapsuleID are correct
	{
		//if at end - clear bMissingCapsules flag and exit
		if( pEEB[POS_STYPE] == SREC_S9 ) {
			bCIDMissing = FALSE;
			wCIDMissing = 0;
			wCIDMissingPrevious = 1;	//wrap around so next REQ will check again
                        DoneEveryCapsules = TRUE;
			bCommandOK = CMD_STATE_DONE;
//			if(bAckMessage)				 //no response if at end...
//				fNPXSendStatus();
	   		sSYSState = SYS_GETDONE;	//we are finished
			#ifdef PLATFORM_MICA2DOT
			call Leds.redOn();		  //turn on => Program is loaded and OK
			#endif
			call Leds.greenOn();           //diagnostic 
			post NPX_STATEMACHINE();//fetch srec from eeprom flash
			break;
			}
		wCapsuleNo = wCID+1;	 //advance to next CID
		wEE_LineR = wEEProgStart+ (wCapsuleNo<<1);	 //2 lines per srec	

	   //	wEE_LineR = wEE_LineR+2; 	  //advance to next srec locaction
	   	sSYSState = SYS_GETNEXTCID;	
	   	bEELineReadPending = TRUE;	//main state machine handles posting task and busy retries
		post NPX_STATEMACHINE();//store srec to eeprom or other operation
	}
	break;
} //switch
return( 1 );
}
/*************************************************************************
fProcessMissingCapsule
Location of a missing capsule
Set flags for future request to network
*************************************************************************/
void fProcessMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing){
	uint16_t wPacketTime;

		bCIDMissing = TRUE;
		wCIDMissing = wlCIDMissing;
	   	wCIDMissingPrevious	= wCIDMissing;   //forces next scan to verify it has been fixed
		
		if( bAckMessage ) {		//xmit request if network allows it
			//introduce a random delay before TXing the request	- in multiples of Packet time
			//8MHz CPU clock =>256 instructions per packet time at 38.4KBaud
			//		call Leds.redOn();           //diagnostic 
			wCIDMissing = call Random.rand(); //should be multiples of Packet Time
			wTXReqDelay = (wCIDMissing & 0x000f) +1;
			wPacketTime = DELAY_PACKETTIME;
			while (wTXReqDelay ) {
				while(wPacketTime)
					wPacketTime--;
				wPacketTime = DELAY_PACKETTIME;
				wTXReqDelay--;
				}
			//call Leds.redOff();           //diagnostic 
			fReqMissingCapsule(wlPID,wlCIDMissing); //tx request
		}
		sSYSMState = SYSM_UPDATE;	   //allow random srec updates in this mote
	   	sSYSState = SYS_GETDONE;	//we are finished for this scan
		post NPX_STATEMACHINE();//
return;
}

/*************************************************************************
fDownLoadAbort
Abort and return to idle state
*************************************************************************/
void fDownLoadAbort(){
	   	sSYSState = SYS_DL_ABORT;	
		sSYSMState = SYS_IDLE;	   
		post NPX_STATEMACHINE();
return;
}
/*************************************************************************
fSendStatus
Build a Status TOS message and Send it to Generic Com if RF not busy
*************************************************************************/
void fNPXSendStatus()
{
  uint8_t i;
  //ptrmsg->data[0]    =  32;  //NESC's TOS MEssage Length
  ptrmsg->data[TS_CMD]    =  CMD_DOWNLOAD_STATUS;             
  ptrmsg->data[TS_SUBCMD]    =  TOS_LOCAL_ADDRESS;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wProgramID;	   //who I am
  ptrmsg->data[TS_PID+1]    =  wProgramID>>8;  //msg id
  ptrmsg->data[TS_CAPSULEID]    =  wCapsuleNo;				   //reserved- extended msg type
  ptrmsg->data[TS_CAPSULEID+1]    =  wCapsuleNo>>8;				   //reserved- extended msg type
  ptrmsg->data[TS_MSGDATA]    =  cCommand;				   //reserved- extended msg type
  ptrmsg->data[TS_MSGDATA+1]  =  bCommandOK;    //Last command recevied/processed
  for (i=8;i<20;i++ )
  {
 	 ptrmsg->data[i]  = i;  //fill
  }
  TOSMsgType = MSG_COMMAND;           //command response message is xmitting
  if(  bTOSMsgBusy == FALSE ){   
    bTOSMsgBusy = call SendMsg.send(TOS_LOCAL_ADDRESS, DATA_LENGTH29,ptrmsg);
  }
  return;		
}  //fStatus
/*************************************************************************
fSendPIDStatus
Build a Status TOS message and Send it to Generic Com if RF not busy
*************************************************************************/
void fNPXSendPIDStatus(uint16_t wlPID)
{

  uint8_t i;
  //ptrmsg->data[0]    =  32;  //NESC's TOS MEssage Length
  ptrmsg->data[TS_CMD]    =  CMD_GET_PIDSTATUS;             
  ptrmsg->data[TS_SUBCMD]    =  TOS_LOCAL_ADDRESS;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wlPID;	   //who I am
  ptrmsg->data[TS_PID+1]    =  wlPID>>8;  //msg id
  ptrmsg->data[TS_CAPSULEID]    =  0;				   //reserved- extended msg type
  ptrmsg->data[TS_CAPSULEID+1]    =  0;				   //reserved- extended msg type
  ptrmsg->data[TS_MSGDATA]    =  cCommand;				   //reserved- extended msg type
  ptrmsg->data[TS_MSGDATA+1]  =  bCommandOK;    //Last command recevied/processed
  for (i=8;i<20;i++ )
  {
 	 ptrmsg->data[i]  = i;  //fill
  }
  TOSMsgType = MSG_COMMAND;           //command response message is xmitting
  if(  bTOSMsgBusy == FALSE ){   
    bTOSMsgBusy = call SendMsg.send(TOS_LOCAL_ADDRESS, DATA_LENGTH29,ptrmsg);
  }
  return;		
}  //fPIDStatus
/*************************************************************************
fNPXInSystemProgramExec
Execute ISP using specfied ProgID
*************************************************************************/
void fNPXInSystemProgramExec(TOS_MsgPtr msgptr){
	uint16_t *wptr;
	
		wptr = (uint16_t *)&(msgptr->data[TS_PID]);
		wProgramID = *wptr++;
		EE_PageW = EE_PAGE_START;
		wEEProgStart = EE_PageW<<4;//the starting point in EEFlash
		//check EEFLASH to verify this programID is present
		fNPXGetEEProgID(wEEProgStart); //check valid progid and invoke ISP
		//EEProgID invokes ISP if all ok
return;
}//fNPXInSystemProgramExec 

/*************************************************************************
fReqMissingCapsule
Request a missing capsule
*************************************************************************/
void fReqMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing)
{
  uint8_t i;
  if( bCIDMissing )
  	bCommandOK = CMD_STATE_REQCID;
  else
	bCommandOK = CMD_STATE_DONE;  //no CID requested

  if (bTOSMsgBusy) return;

  wlCIDMissing--; 	//Network wants CID 0 based on return but 1 on xmit
  ptrmsg->data[TS_CMD]    =  CMD_REQ_CIDMISSING;             
  ptrmsg->data[TS_SUBCMD]    =  TOS_LOCAL_ADDRESS;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wlPID;	   //who I am... or want to be....
  ptrmsg->data[TS_PID+1]    =  wlPID>>8;  //msg id
  ptrmsg->data[TS_CAPSULEID]    =  wlCIDMissing;				   //e
  ptrmsg->data[TS_CAPSULEID+1]    =  wlCIDMissing>>8;				   //pe
  ptrmsg->data[TS_MSGDATA]    =  cCommand;				  
  ptrmsg->data[TS_MSGDATA+1]  =  bCommandOK;    
  for (i=8;i<20;i++ )
  {
 	 ptrmsg->data[i]  = i;  //fill
  }
  wlCIDMissing++; //restore to 1 based
  TOSMsgType = MSG_COMMAND;           //command response message is xmitting
  if(  bTOSMsgBusy == FALSE ){   
    bTOSMsgBusy = call SendMsg.send(TOS_LOCAL_ADDRESS, DATA_LENGTH29,ptrmsg);
  	}
  return;		
}  //fmissingcid

/*************************************************************************
fDownloadComplete
Request a missing capsule
*************************************************************************/
void fDownloadComplete(uint16_t wlPID)
{
  uint8_t i;

  bCommandOK = CMD_STATE_DONE;  //no CID requested

  if (bTOSMsgBusy) return;

  ptrmsg->data[TS_CMD]    =  CMD_QUERY_COMPLETE;
  ptrmsg->data[TS_SUBCMD]    =  TOS_LOCAL_ADDRESS;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wlPID;        //who I am... or want to be....
  ptrmsg->data[TS_PID+1]    =  wlPID>>8;  //msg id
  ptrmsg->data[TS_CAPSULEID]    =  0; // not used
  ptrmsg->data[TS_CAPSULEID+1]    =  0; // not used
  ptrmsg->data[TS_MSGDATA]    =  cCommand;
  ptrmsg->data[TS_MSGDATA+1]  =  bCommandOK;
  for (i=8;i<20;i++ )
  {
         ptrmsg->data[i]  = i;  //fill
  }
  TOSMsgType = MSG_COMMAND;           //command response message is xmitting
  if(  bTOSMsgBusy == FALSE ){
    bTOSMsgBusy = call SendMsg.send(TOS_LOCAL_ADDRESS, DATA_LENGTH29,ptrmsg);
        }
  return;
}  // fDownloadComplete

/*************************************************************************
fNPXSRECParse
Got a code capsule containing 1 srec from radio
[0]:commandid
[1.2]:program id
[3:4]:nofcapsules (srecords)

Computes destination EEFlash address based on SREC address and stores in
EEFlash. Does NOT respond to Host - this used during Broadcast downloads.

Accepts non-contiguous srecs.

If bEEPROMBusy we abort because EEBuf is not available

NOTE
1. Changes sSYSState if last/S9 record

Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.
*************************************************************************/
uint8_t fNPXSRECParse(TOS_MsgPtr msgptr)  {
	uint8_t i,j;
	//uint16_t wTemp;
	//uint8_t cTemp;
	uint8_t cLen;
	uint8_t cSRecType;
	uint8_t bSRecValid;
	//uint8_t bFini = FALSE;
	//uint16_t *wptr;
	uint8_t cCheckSum;


	bSRecValid = TRUE;	//assume we can parse the sREC

	//Verify Checksum 
	cLen = msgptr->data[TS_LEN];		//get nof bytes in srec
	cCheckSum = 0;
	for (j=TS_LEN;j<TS_LEN+cLen;j++ )
		cCheckSum = cCheckSum + msgptr->data[j];
	cCheckSum = ~cCheckSum;
	if( cCheckSum != (uint8_t)msgptr->data[j])	//j is sitting at srec checksum
		return(FALSE);	   //bad so ignore

	if( bEEPROMBusy )
		return(FALSE);	   //busy so ignore
	cSRecType = msgptr->data[TS_TYPE];
	

	switch ( cSRecType ) {

	case SREC_S1:
/*---------------------------------------------------------------------------
Build	S1 in binary format-2byte address field
S11300700C9463000C9463000C9463000C94630070
S11300800C9463000C9463000C94630011241FBE51
S1130090CFEFD0E1DEBFCDBF11E0A0E0B1E0EAEEEA
----------------------------------------------------------------------------*/
//		TOS_CALL_COMMAND(RED_LED_TOGGLE)();	//diag
		ELBuff[POS_PID] = wProgramID;	   
		ELBuff[POS_PID+1] = wProgramID>>8;	   
		ELBuff[POS_CID] = msgptr->data[TS_CAPSULEID];	   
		ELBuff[POS_CID+1] = msgptr->data[TS_CAPSULEID+1];
		
		//Build an SREC Format
		ELBuff[POS_STYPE] = SREC_S1;
		ELBuff[POS_SNOFB] = cLen = msgptr->data[TS_LEN];		//get nof bytes in srec
		ELBuff[POS_S1_ADDR] = msgptr->data[TS1_ADDR_LSB];	   //lsbyte of address
		ELBuff[POS_S1_ADDR+1] = msgptr->data[TS1_ADDR_MSB];  //mostbyte of address

		//fill the buffer with data section of the SRec	w/ lsbyte first
		cLen = (cLen - 3); //nof Instructions (bytes)
		for (i=POS_S1_I0,j=TS_INSTR0_MSB;i<POS_S1_I0+cLen;i++,j++ ) {	  
			ELBuff[i] = msgptr->data[j];	 //get lsbyte
//		  	ELBuff[i+1] = msgptr->data[j];	 //get msbyte
			}
		//place holder for binary computed checksum	- i is sitting at correct position
		ELBuff[i] = 0x77;	  //diag-indicates stored via SRECStore
		//fill rest of buffer
		for (j=i+1;j<32;j++)
			ELBuff[j] = j; //fillbytes
		break; //SRec S1

	case SREC_S9:  //s9 contains boot address - and is last record of sfile
//		 S9030000FC
		ELBuff[POS_PID] = wProgramID;	   
		ELBuff[POS_PID+1] = wProgramID>>8;	   
		//Store CapsuleID 
		ELBuff[POS_CID] = msgptr->data[TS_CAPSULEID];	   
		ELBuff[POS_CID+1] = msgptr->data[TS_CAPSULEID+1];	   
		//Build an SREC Format
		ELBuff[POS_STYPE] = SREC_S9;
		//srec9 only has 2byte address
		ELBuff[POS_SNOFB] = cLen = msgptr->data[TS_LEN];		//get nof bytes in srec
		ELBuff[POS_S1_ADDR] = msgptr->data[TS1_ADDR_LSB];	   //lsbyte of address
		ELBuff[POS_S1_ADDR+1] = msgptr->data[TS1_ADDR_MSB];  //midsbyte of address
	   //	bFini = TRUE;	  /
		break;

	default:

		bSRecValid = FALSE;	//unrecognized sREC
		break;	//unknown SRec type

	}//switch srectype

return(bSRecValid);
}//fNPXSRECParse
/*************************************************************************
fSysVarInit
Init all VARS to defaults
*************************************************************************/
void fNPXSysVarInit()  {
 #ifdef JTAG
 	TOS_LOCAL_ADDRESS = TOS_LOCAL;   //local address set in client
 #endif
	sSYSState = SYS_IDLE;
//	sSYSState = SYS_BEACON;
//   	post NPX_STATEMACHINE();//store srec to eepromn
	//Netprogramming stuff
	cCommand = 0; //current command
	bCommandOK = FALSE; //current command processed ok
	wCapsuleNo = 0; //code capsule number
	wNofCapsules = 0;	//expected number of capsules
	wEEProgStart = 0;
	bEEWriteEnabled = 0;          //no EEFLASH after init
	EE_PageW = EE_PAGE_START;
	wEEProgStart = EE_PageW<<4;
	wLastEEPage = EEPROM_NOFPAGES-1; //maxnof lines in EEPROM
	bEEPROMBusy = 0;     //EPROM available to write
	bEELineWritePending = FALSE;
	bELBuffAWE = TRUE;	//BufferA or B selected for write enable
	bELBuffFull = FALSE; //EEPROM buffer is full and should be flushed
	cLineinPage = 0; //reset the line count	

	TOSMsgType = MSG_IDLE;
	itest = 240;
	btest = 0;             //0:no test pattern
	//Init message parameters
	pNETTOSMsg = &NETTOSMsg;   //rx buffer
	ptrmsg = &msg;    //init pointer to tx buffer
	bTOSMsgBusy = 0;       //no message pending
	bNXPMsgBusy = FALSE;
	itest = TOS_LOCAL_ADDRESS;
	return;
}//fSysVarInit	   

} //end implementation
/*****************************************************************************/
/*ENDOFFILE******************************************************************/
