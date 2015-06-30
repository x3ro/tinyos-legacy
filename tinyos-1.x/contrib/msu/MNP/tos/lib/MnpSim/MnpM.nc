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
 * This module implements Multi-hop Network Programming (MNP). This program runs on TOSSIM. 
 * 
 * Some parts of the code (e.g., write to EEPROM) are adapted from Xbow XNP. 
 * 
 * Authors: Limin Wang, Sandeep Kulkarni
 * 
 **/

module MnpM {
  provides {
    interface Mnp;
    interface StdControl;
  }
  uses {
    interface StdControl as GenericCommCtl;
    interface StdControl as EEPROMControl;
    interface SendMsg;
    interface ReceiveMsg; 
    interface Leds;     
    interface EEPROMRead;
    interface EEPROMWrite;
    interface Timer;
    interface Random;
  }
}


implementation {
		
#include "Mnp.h"

    	int bQryTiming;
	uint16_t wParentID;
    	int bQryRetries;
    	int bRequestRetries;
    	uint8_t bWaitSig;
    	uint8_t resumePos;
    	int remainLen;
    	TOS_Msg smsg;
    	TOS_MsgPtr sptrmsg;
	TOS_Msg	revMsg;
    	uint8_t bRetransmit;
    	int iRequestTiming;
	uint8_t bLost;
	uint16_t wMissingStart;
	uint16_t wMissingNmb;
	uint8_t bRequestDL;
	int AdRetry;
	int bFWStartRetry;
	int bFWTermRetry;
	uint8_t bGotTermDownload;
	uint8_t bSleep;
	uint8_t bForwardInit;
	uint8_t bDownloadEnd;
	uint8_t bChannelTries;
  	double TransmitTime;
  	double ListenTime;
  	double NextAdvTime;
  	uint32_t AdInterval;
  	uint16_t wExpectPID;
  	uint16_t wExpectSourceID;
  	uint8_t bNofRequest;	// number of requests from competitor 
  	uint8_t ReceiverArray[REV_ARRAY_SIZE];
  	uint8_t bNofReceivers;	// number of requests I have received
  	uint16_t wReqCIDMissing;
  	uint16_t wNofLostInSection;
  	uint8_t bUpRead;
  	int iNextCapsuleTiming;
  	int bWaitQryTiming;
  	uint8_t bGotQry;

	uint8_t sSYSState;			
	uint8_t sSYSMState; //major state
	TOS_Msg msg;          
	TOS_MsgPtr ptrmsg;   // message ptr
	uint8_t bTOSMsgBusy;
	TOS_MsgPtr pNETTOSMsg;	//global incoming message for statemachine

	uint16_t wProgramID;
	uint16_t wCapsuleNo; //code capsule number
	uint16_t wNofCapsules;	//expected number of capsules
	uint8_t bCIDMissing;
	uint16_t wCIDMissing;	
	uint16_t wCIDMissingPrevious;
	uint16_t wEEProgStart;	//start location in EEFLASH

	uint8_t bEEWriteEnabled;			//EEFLASH is WRITE Enabled
	uint8_t bEEWriteContinuous;
	uint16_t wEE_LineW;      //current/final eeprom line written 
	uint16_t wEE_LineR;
  	uint8_t cLineinPage;			//line# within Page being read
    	uint8_t bEELine1;          //1st line of 2 being written
            
	uint8_t bEELineWritePending;
	uint8_t bEEPROMBusy;  //0 if EEPROM available for write 

	EEBUF_line_struct EELineBuf;	//for readout
	uint8_t ELBuff[ELBUFF_SIZE];
	uint8_t bELBuffAWE;	//BufferA or B selected for write enable
	uint8_t bELBuffFull;
	uint8_t channel_rate;
	
	// changes made for pipelining
	uint8_t bNmbSegRvd;		// number of segments received
	uint8_t bNmbSegTotal;		// number of segments in total
	uint8_t bAdvSeg;		// the segment advertised, initially set to be bNmbSegRvd, 
					// can be changed to an older segment if it receives a request for an older segment
	uint8_t bExpectSegID;		
	uint16_t wLastSegSize;
	uint8_t ReStartCount;
	uint8_t MissPacketsIndicator[MISSINDICATOR_SIZE];
	uint8_t ForwardPacketsIndicator[MISSINDICATOR_SIZE];
	
	uint8_t bSleepType;
	uint8_t bSendSig;
	
	uint8_t bEndSig;
	uint8_t bLine1;
	int bEERetry;
	int bAdvTries;
	int bSendISP;
	uint8_t bReceiveData;
	
	char timeBuf[128];

	uint8_t started;
	double percent;
	
	uint8_t smallAdvCtr;
	uint8_t ReqCtr;
	
//------------------------ LOCAL FUNCTIONS -----------------------------------
void fSysVarInit();		//init vars to default
void fStartDownload();
void fSRECDownload(TOS_MsgPtr msgptr);
uint8_t fSRECParse(TOS_MsgPtr msgptr);
void fSRECStore(TOS_MsgPtr msgptr);
void fSRECUpdate(TOS_MsgPtr msgptr);
void fReqMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing);
void fSendStatus();		//Sendstatus function
void fStartForward();
void fTerminateForward();
void fLostSRECBuild();
void fUpdateCIDMissing();
void fRetransmit();
void fSendQryMessage();
void fSendDLRequest();
void fSendAdvertise();
void fSendStartForward();
uint8_t checkMissing(uint16_t wCID);
uint8_t haveMissing();
uint8_t manyMissing();
uint8_t checkForward(uint16_t wCID);
void MarkMissing(uint16_t wCID);
void MarkReceive(uint16_t wCID);
uint16_t FindAnyMissing();
uint16_t FindAnyForward();
void MarkForward(uint16_t wCID);
bool IsBase(uint16_t addr);

/****************************************************************************
 * Initialize the component. Initialize
 *
 ****************************************************************************/
  command result_t StdControl.init() {
    fSysVarInit();				//set vars to init
    call GenericCommCtl.init();
    call EEPROMControl.init();
    call Leds.init();
    call Random.init();
    return SUCCESS;
  }
 /****************************************************************************
 * Start the component..
 *
 ****************************************************************************/
  command result_t StdControl.start(){
    call GenericCommCtl.start();
    if(IsBase(TOS_LOCAL_ADDRESS))
    {
    	bAdvSeg = 1;
	wProgramID = 0xDF85;
	wNofCapsules = MNP_CAPSULE_PER_SEGMENT;
	bNmbSegRvd = TOSSIM_NMB_SEGMENT;
	wLastSegSize = TOSSIM_LAST_SEGMENT_SIZE;
	bNmbSegTotal = bNmbSegRvd;
	bNofReceivers = 0;
	bWaitSig = SIG_BS_START;
	call Timer.start(TIMER_ONE_SHOT, 1);
    }
    else
    {
    	bWaitSig = SIG_NONBS_START;
    	call Timer.start(TIMER_ONE_SHOT, 5000);
    }
    return SUCCESS;	
  }
 /****************************************************************************
 * Stop the component.
 *
 ****************************************************************************/
  command result_t StdControl.stop() {
    return SUCCESS;
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

*****************************************************************************/
#define EEBufA 0	//Buffer IDs
#define EEBufB 1	//Buffer IDs

task void EE_LineWrite() {
	uint8_t iRet;
 	if( bEEWriteEnabled ) {
 	 if( !bEEPROMBusy){

	//write the first of a 2line sequence
	  bEELine1 = TRUE;	// 1st line
	  iRet = call EEPROMWrite.write(wEE_LineW, (uint8_t*)&ELBuff );

// Add retry timeout later
	  if(!iRet)	//failed
    		post EE_LineWrite(); //keep trying
		
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
    		post EE_LineWrite();
 	}
}

/*****************************************************************************
STATEMACHINE
******************************************************************************/
task void STATEMACHINE() {
	uint8_t cNextState, cCurrentState;
	uint8_t bRePost;
	uint8_t bRet;
	uint16_t *wptr;
	uint16_t wTemp, wTemp2;
	uint8_t lTOSMsgBusy;
	uint16_t i;
	uint32_t RandNum;

	cNextState = sSYSState; //default is no change
	cCurrentState = cNextState;

	bRePost = FALSE; //by default we do not repeat this statemachine task
	
	switch( cCurrentState )
	{
	case SYS_REQ_CIDMISSING: 
	 	cNextState = SYS_GET_CIDMISSING;
		sSYSMState = SYSM_UPDATE;
		bUpRead = TRUE;
   	        bRet = call EEPROMWrite.endWrite();  
		bRePost = TRUE; 
		break;

	case SYS_GET_CIDMISSING:	
		if( !haveMissing() )
		{
			cNextState = SYS_GETDONE;
		}
		else if( manyMissing() )
		{
			cNextState = SYS_DL_FAIL;
		}
		else
		{
			bRequestRetries = REQUEST_RETRY;
			cNextState = SYS_REQUESTING;
		}
		bRePost = TRUE;
		break;

	case SYS_REQUESTING:
		RandNum = MIN_RESPONSE_DELAY+((call Random.rand())& 0x3FF);
		bWaitSig = SIG_REQUESTING;
		call Timer.start(TIMER_ONE_SHOT, RandNum);
		break;
	
	case SYS_SEND_REQUEST:
		if( wCIDMissing == 0 )
  		{
  			cNextState = SYS_GETDONE;
  		}
  		else
  		{
			fReqMissingCapsule(wProgramID, wCIDMissing);	// wCIDMissing is updated after retransmitted capsules arrive
			iRequestTiming = REQUEST_TIMING;
			cNextState = SYS_WAIT_FOR_RETRANSMIT;
		}
		bRePost = TRUE;
		break;

	case SYS_WAIT_FOR_RETRANSMIT:
		if( iRequestTiming > 0 )
		{
			RandNum = MIN_RETRANSMIT_DELAY+((call Random.rand())& 0x1FF);
			bWaitSig = SIG_RETRANSMIT;
			call Timer.start(TIMER_ONE_SHOT, RandNum);
			iRequestTiming--;
		}
		else
		{
			wCIDMissing = FindAnyMissing();
			if(wCIDMissing == 0)	
				cNextState = SYS_GETDONE;
			else
			{
				if( bRequestRetries > 0 )
				{
					bRequestRetries--;
					cNextState = SYS_REQUESTING;
				}
				else
				{
					cNextState = SYS_DL_FAIL;
				}
			}
			bRePost = TRUE;
		}
		break;
		
	case SYS_DL_REQUEST:
		RandNum = MIN_RESPONSE_DELAY+((call Random.rand())& 0xFF);
		bWaitSig = SIG_DL_REQUEST;
		call Timer.start(TIMER_ONE_SHOT, RandNum);
		break;
	
	case SYS_DL_REQUESTING:
		fSendDLRequest();
		bRequestDL = FALSE;
		cNextState = SYS_IDLE;
		sSYSMState = SYSM_IDLE;
		bRePost = TRUE;
		break;
			
	case SYS_DL_START:
		cNextState = SYS_DL_START0; //this is a pseudo state waiting for APP to ack start dl request
	    	fStartDownload(); //prep & call app with DL request.Determines next state
		cNextState = sSYSState; //SYS state maybe changed by functioncall
		break;

	case SYS_DL_START1: 
		cNextState = SYS_DL_START2;
		//Release EEFLASH unconditionally to get into clean state
        	bRet = call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke statemachine
		bRePost = TRUE; //no endWrite to signal enddone so go directly to START1
		break;

	case SYS_DL_START2: //
		//Clear flags
		bEEWriteContinuous = FALSE; 
		bEEWriteEnabled = FALSE;        // eeprom writing enabled flag
		bEEPROMBusy = 0;     //reset any pending eprom writes 
		//lock down EEPROM resource
	    bRet = call EEPROMWrite.startWrite(); //a function call - no event signal
	    if( !bRet )	{	  //eeprom not available
			cNextState = SYS_DL_FAIL;
		} else {
			bEEWriteContinuous = TRUE; //donot release EEFLASH after each srec write
			bEEWriteEnabled = TRUE;        // eeprom writing enabled flag
			bEEPROMBusy = 0;     //reset any pending eprom writes 
			wEEProgStart = DEF_PROG_START<<4;//the starting point in EEFlash
			wCapsuleNo = 0;		//update current capsule# -Network capsule# starts at 1

			sSYSMState = SYSM_DOWNLOAD;	 //Entered DOWNLOAD Major State

			if(bReceiveData)
			{
				cNextState = SYS_DL_SRECWRITE;
				bReceiveData = FALSE;
			}
			else
			{
				iNextCapsuleTiming = NEXTCAPSULE_TIMING;
				cNextState = SYS_WAIT_FOR_NEXT_CAPSULE; //where we go next
			}
			bGotTermDownload = FALSE;
		}
		bRePost = TRUE;		//goto next state	 
		break;

	case SYS_DL_SRECWRITE: //write SREC in DOWNLOAD Mode
			fSRECStore(pNETTOSMsg);
			cNextState = sSYSState; //whatever fSRECStore did to sSYSState
			break;

	case SYS_UP_SRECWRITE: //write SREC in UPDATE Mode
			fSRECUpdate(pNETTOSMsg);
			cNextState = sSYSState; //whatever fSRECUpdate did to sSYSState
			break;

	case SYS_EEFLASH_WRITE:
		if( bEELineWritePending ){ 	//waiting to post a task to EEWrite
		   	if( !bEEPROMBusy ){
				post EE_LineWrite();//write buffer out to EEPROM
				bEELineWritePending = FALSE;
		     	} else //EEPROM is busy
		     	{
				bRePost = TRUE;	//re-execute STATEMACHINE only if busy
			}
			}//writepending
			else { //not pending 
				cNextState = SYS_EEFLASH_WRITEDONE; //nothing to do so end it
				bRePost = TRUE;
			}	  
		break;

	case SYS_EEFLASH_WRITEDONE:
	  	call Leds.yellowToggle();
		bEELineWritePending = FALSE;
		if(sSYSMState == SYSM_UPDATE)
			cNextState = SYS_GET_CIDMISSING;
		else
		{
			iNextCapsuleTiming = NEXTCAPSULE_TIMING;
			cNextState = SYS_WAIT_FOR_NEXT_CAPSULE; 
		}

		bRePost = TRUE; 

		break;
	
	case SYS_WAIT_FOR_NEXT_CAPSULE:
		if(!haveMissing())
		{
			cNextState = SYS_GETDONE;
			bRePost = TRUE;
		}
		else
		{
			if( iNextCapsuleTiming > 0 )
			{
				bWaitSig = SIG_NEXTCAPSULE;
				call Timer.start(TIMER_ONE_SHOT, TIMER_SPAN);
				iNextCapsuleTiming--;
			}
			else
			{
				cNextState = SYS_DL_FAIL;
				bRePost = TRUE;
			}
		}
		break;

	case SYS_DL_END:
		//release EEPROM resource
		sSYSMState = SYSM_DOWNLOAD_DONE;
		if(!haveMissing())
			cNextState = SYS_GETDONE;
		else 
			cNextState = SYS_DL_FAIL;
		
		bRePost = TRUE;	
		break;
		
	case SYS_DL_FAIL:
		//release EEPROM resource if required
		cNextState = SYS_DL_FAIL_SIGNAL;
		if( bEEWriteEnabled )
          		call EEPROMWrite.endWrite();  //EEWriteEndDone will invoke statemachine
		bRePost = TRUE;
		break;

	case SYS_DL_FAIL_SIGNAL:
		sSYSMState = SYSM_IDLE;
		wCapsuleNo = 0; //reset current Capsule#
		bGotTermDownload = FALSE;
		bRequestDL = FALSE;
		bTOSMsgBusy = FALSE;
		
		//Tell client download has been aborted
//		signal Mnp.downloadAborted(wProgramID);
		cNextState = SYS_IDLE;		
		bRePost = TRUE;	
		break;

	case SYS_IDLE:
		break;

	case SYS_GETDONE:
		call EEPROMWrite.endWrite();
		sSYSMState = SYSM_DOWNLOAD_DONE;
		cNextState = SYS_GETDONE_SIGNAL;
		bRePost = TRUE;
		break;
		
	case SYS_GETDONE_SIGNAL:
		sSYSMState = SYSM_UPDATE_DONE;
		bNmbSegRvd++;
		started = FALSE;
		bAdvSeg = bNmbSegRvd;
		ReStartCount = 0;
		
		for(i=0; i<(MISSINDICATOR_SIZE); i++)
		{
			MissPacketsIndicator[i] = 0xFF;
		}
		
		if(bNmbSegRvd == bNmbSegTotal)
		{
			signal Mnp.downloadDone(wProgramID);
		}

		if(!IsBase(TOS_LOCAL_ADDRESS))
		{
			printTime(timeBuf, 128);
			dbg(DBG_USR1, "get Seg %i at %s\n", bNmbSegRvd, timeBuf);

			if(bNmbSegRvd > 0)
			{
				bAdvSeg = bNmbSegRvd;
				cNextState = SYS_ADVERTISE_START;
			}
			else
			{
				bRequestDL = FALSE;
				sSYSMState = SYSM_IDLE;
				cNextState = SYS_IDLE;
			}
		}
		else
		{
			bRequestDL = FALSE;
			sSYSMState = SYSM_IDLE;
			cNextState = SYS_IDLE;
		}
		
  		bRePost	= TRUE;
  		break;

	case SYS_ADVERTISE_START:
		if(bSleep)
			bSleep = FALSE;
		
		for(i=0; i<(MISSINDICATOR_SIZE); i++)
			ForwardPacketsIndicator[i] = 0x00;

		bNofReceivers = 0;
		sSYSMState = SYSM_ADVERTISE;
		AdRetry = ADVERTISE_RETRY;
		if(bWaitSig == SIG_BS_START)
		{
			AdInterval = (call Random.rand())& 0x1F;
			bWaitSig = 0;
		}
		else
			AdInterval = MIN_AD_INTERVAL+(call Random.rand())& 0x1FF;
		bAdvTries = 0;
		cNextState = SYS_ADINTERVAL;
		bRePost = TRUE;
		break;
			
	case SYS_ADINTERVAL:
		atomic{
			if(bAdvTries >= ADV_TRIES)
			{
				bRequestDL = FALSE;
			}
		}
		
		if( !bRequestDL )
		{
			bAdvTries = 0;
			
			if( AdInterval <= 0 )
			{		
				if( AdRetry>0 )
				{
					cNextState = SYS_WAIT_FOR_CHANNEL;
					bRePost = TRUE;
				}
				else
				{
					if( bNofReceivers <= 0 ) 
					{
						if(bAdvSeg < bNmbSegRvd)
						{
							bAdvSeg = bNmbSegRvd;
							ReStartCount = 0;
							cNextState = SYS_ADVERTISE_START;
						}
						else
						{
							if(ReStartCount < MAX_RESTART)
								ReStartCount++;
							NextAdvTime = (MIN_AD_RESTART_INTERVAL)<<ReStartCount;
							if(bNmbSegRvd == bNmbSegTotal)
							{
								bSleep = TRUE;
								if(NextAdvTime >= ADVSLEEP_DURATION)
								{
									TransmitTime = ADVSLEEP_DURATION;
									NextAdvTime -= TransmitTime;
								}
								else
								{
									TransmitTime = NextAdvTime;
									NextAdvTime = 0;
								}
								percent = (double)(TransmitTime)/(double)(SLEEP_DURATION);
								bNofReceivers = 0;
								cNextState = SYS_SLEEP;
								
								printTime(timeBuf, 128);
								bSleepType = ADV_NOREQ;
								dbg(DBG_USR2, "NoReq sleep begin at %s\n", timeBuf);
							}
							else if((bNmbSegRvd < bNmbSegTotal) && (!started))
							{
								bSleep = TRUE;
								if(NextAdvTime >= INITSLEEP_DURATION)
								{
									TransmitTime = INITSLEEP_DURATION;
									NextAdvTime -= TransmitTime;
								}
								else
								{
									TransmitTime = NextAdvTime;
									NextAdvTime = 0;
								}
								percent = (double)(TransmitTime)/(double)(SLEEP_DURATION);
								bNofReceivers = 0;
								cNextState = SYS_SLEEP;
								
								printTime(timeBuf, 128);
								bSleepType = ADV_NOREQ;
								dbg(DBG_USR2, "NoReq sleep begin at %s\n", timeBuf);
							}
							else
							{
								ListenTime = NextAdvTime;
								NextAdvTime = 0;
								smallAdvCtr = 0;
								ReqCtr = 0;
								cNextState = SYS_WAKEUP_LISTEN;
								bSleepType = ADV_NOREQ;
							}
						}

						bRePost = TRUE;
					}
					else
					{
						ReStartCount = 0;
						cNextState = SYS_FORWARD_START;
						bRePost = TRUE;
					}
				}
			}
			else if( AdInterval > 1000 )
			{
				bWaitSig = SIG_ADINTERVAL;
				call Timer.start(TIMER_ONE_SHOT, 1000);
				AdInterval -= 1000;
			}
			else
			{
				bWaitSig = SIG_ADINTERVAL;
				call Timer.start(TIMER_ONE_SHOT, AdInterval);
				AdInterval = 0;
			}
		}
		else
		{
			atomic bAdvTries++;
			bWaitSig = SIG_ADVTRIES;
			call Timer.start(TIMER_ONE_SHOT, FAIL_RETRY_INTERVAL);
		}
		break;
		
	case SYS_BCAST_AD:
		fSendAdvertise();
		if(bNofReceivers > 0)
			ReStartCount = 0;
		AdInterval = MIN_AD_INTERVAL+(call Random.rand())& 0x1FF; 	
		AdRetry--;
		bAdvTries = 0;
		cNextState = SYS_ADINTERVAL;
		bRePost = TRUE;
		break;	
			
	case SYS_FORWARD_START:
		sSYSMState = SYSM_FORWARD;
		if(bAdvSeg == bNmbSegTotal)
			wNofCapsules = wLastSegSize;
		else
			wNofCapsules = MNP_CAPSULE_PER_SEGMENT;	
		bForwardInit = FALSE;
		bFWStartRetry = FORWARD_START_RETRY;
		bWaitSig = SIG_FORWARD_START;
		call Timer.start(TIMER_ONE_SHOT, START_FORWARD_RATE);
		break;
			
	case SYS_FORWARD_START_RESUME:
		fSendStartForward();
		bWaitSig = SIG_FORWARD_START;
		call Timer.start(TIMER_ONE_SHOT, START_FORWARD_RATE);
		break;
			
	case SYS_START_FORWARDING:
		fStartForward();
		cNextState = sSYSState;
		bRePost = TRUE;
		break;		
		
	case SYS_FORWARDING:
		if(!(call EEPROMRead.read(wEE_LineR, (uint8_t*)&ELBuff)))
		{
			bTOSMsgBusy = FALSE;
			cNextState = SYS_FORWARD_END;
			bRePost = TRUE;
		}
		break;
		
	case SYS_FORWARD_RESUME:	
		if(!(call EEPROMRead.read(wEE_LineR, (uint8_t*)&ELBuff)))
		{
			bTOSMsgBusy = FALSE;
			cNextState = SYS_FORWARD_END;
			bRePost = TRUE;
		}
		break;
			
	case SYS_FORWARD_RESUME_DONE_PRE:
		// copy the saved first part to ptrmsg
		for(i=0; i<resumePos; i++)
			ptrmsg->data[i] = sptrmsg->data[i];
		cNextState = SYS_FORWARD_RESUME_DONE;
		bRePost = TRUE;
		break;		
	
	case SYS_FORWARD_RESUME_DONE:
		wptr = (uint16_t*)&(ptrmsg->data[TS_CAPSULEID]);
		wTemp = *wptr;

		bSendSig = SIG_FORWARD_RESUME_DONE;	
		if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
		{
//			dbg(DBG_USR1, "FORWARD FAIL\n");
			bTOSMsgBusy = FALSE;
			cNextState = SYS_SEND_FAIL;
			bRePost = TRUE;
		}
		else
		{
			bTOSMsgBusy = TRUE;
			MarkForward(wTemp);
			dbg(DBG_USR1, "FORWARD %d of Seg %d\n", wTemp, bAdvSeg);
			bWaitSig = SIG_FORWARD_RESUME_DONE;
			call Timer.start(TIMER_ONE_SHOT, WAIT_FORWARD_RATE);
		}

		break;

	case SYS_FORWARD_CONTINUE:
		wCapsuleNo = FindAnyForward();
		if(wCapsuleNo == 0)
		{
			cNextState = SYS_FORWARD_END;
			bRePost = TRUE;
		}
		else
		{
			wTemp2 = ((bAdvSeg-1)*(MNP_CAPSULE_PER_SEGMENT))+wCapsuleNo;
			wEE_LineR = wEEProgStart+(wTemp2<<1);
			cNextState = SYS_WAIT_FOR_CHANNEL;
			bRePost = TRUE;
		}
		break;

	case SYS_FORWARD_END:
		sSYSMState = SYSM_FORWARD_DONE;
		bFWTermRetry = FORWARD_TERMINATE_RETRY;
		bWaitSig = SIG_FORWARD_END;
		call Timer.start(TIMER_ONE_SHOT, START_FORWARD_RATE);
		break;
	
	case SYS_TERMINATE_FORWARD:
		fTerminateForward();
		bWaitSig = SIG_FORWARD_END;
		call Timer.start(TIMER_ONE_SHOT, START_FORWARD_RATE);
		break;
		
	case SYS_QRY_DONE:
		ReStartCount = 0;	
		if(bNmbSegRvd > 0)
		{
			cNextState = SYS_ADVERTISE_START;
		}
		else
		{
			sSYSMState = SYSM_IDLE;
			cNextState = SYS_IDLE;
		}
		bRePost = TRUE;
		break;
				
	case SYS_WAIT_FOR_CHANNEL:
		atomic{
		if( bChannelTries >= CHANNEL_TRIES ) 
		{
			bTOSMsgBusy = FALSE;
		}
		lTOSMsgBusy = bTOSMsgBusy;
		}
		
		if( !lTOSMsgBusy )
		{
			atomic{
			bChannelTries = 0;
			bTOSMsgBusy = TRUE;
			}
			
			if( bRequestDL && ((sSYSMState == SYSM_ADVERTISE) || (sSYSMState == SYSM_IDLE)))
				cNextState = SYS_DL_REQUESTING;
			else if(sSYSMState == SYSM_ADVERTISE)
				cNextState = SYS_BCAST_AD;
			else if( sSYSMState == SYSM_UPDATE )
				cNextState = SYS_SEND_REQUEST;
			else if( sSYSMState == SYSM_FORWARD )
			{
				if( !bForwardInit )
					cNextState = SYS_FORWARD_START_RESUME;
				else
					cNextState = SYS_FORWARDING;
			}
			else if( sSYSMState == SYSM_FORWARD_DONE )
			{
				cNextState = SYS_TERMINATE_FORWARD;
			}
			bRePost = TRUE;
		}
		else
		{
			atomic bChannelTries++;
			bWaitSig = SIG_CHANNEL;
			call Timer.start(TIMER_ONE_SHOT, FAIL_RETRY_INTERVAL);
		}				
		break;
			
	case SYS_SLEEP:
		if( TransmitTime <= 0 )
		{
			bSleep = FALSE;
			
			printTime(timeBuf, 128);
			dbg(DBG_USR2, "sleep end at %s\n", timeBuf);
			
			bRequestDL = FALSE;
			if(bNmbSegRvd > 0)
			{
				bAdvSeg = bNmbSegRvd;
				sSYSMState = SYSM_ADVERTISE;
			}
			else 
				sSYSMState = SYSM_IDLE;

			ListenTime = WAKEUP_LISTEN_PERIOD;
			if(NextAdvTime > ListenTime)
				NextAdvTime -= ListenTime;
			else
				NextAdvTime = 0;
			smallAdvCtr = 0;
			ReqCtr = 0;
			
			cNextState = SYS_WAKEUP_LISTEN;

			bRePost = TRUE;			
		}	
		else if( TransmitTime > 1000 )
		{
			bWaitSig = SIG_SLEEP;
			call Timer.start(TIMER_ONE_SHOT, 1000);
			TransmitTime -= 1000;
		}
		else
		{
			bWaitSig = SIG_SLEEP;
			call Timer.start(TIMER_ONE_SHOT, (uint16_t)TransmitTime);
			TransmitTime = 0;
		}
		break;
			
	case SYS_SEND_FAIL:
		bSendSig = 0;
		bTOSMsgBusy = FALSE;
		bRequestDL = FALSE;
		ReStartCount = 0;
		if(bNmbSegRvd > 0)
		{
			bAdvSeg = bNmbSegRvd;
			cNextState = SYS_ADVERTISE_START;
		}
		else
		{
			cNextState = SYS_IDLE;
			sSYSMState = SYSM_IDLE;
		}
		bRePost = TRUE;
		break;
		
	case SYS_WAKEUP_LISTEN:
		if(ListenTime <= 0)
		{
			if(bSleepType == SENDER_SELECTION)
			{
				ReStartCount = 0;
				if((NextAdvTime > 0) && ((bNmbSegRvd < bNmbSegTotal) && (!started)))
				{
					bSleep = TRUE;
					if(NextAdvTime >= INITSLEEP_DURATION)
					{
						TransmitTime = INITSLEEP_DURATION;
						NextAdvTime -= TransmitTime;
					}
					else
					{
						TransmitTime = NextAdvTime;
						NextAdvTime = 0;
					}
					percent = (double)(TransmitTime)/(double)(SLEEP_DURATION);
					bNofReceivers = 0;
					cNextState = SYS_SLEEP;
					
					printTime(timeBuf, 128);
					bSleepType = SENDER_SELECTION;
					dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);							
				}
				else
				{
					if(bNmbSegRvd > 0)
						cNextState = SYS_ADVERTISE_START;
					else
						cNextState = SYS_IDLE;
				}
			}
			else if(bSleepType == ADV_NOREQ)
			{
				if((smallAdvCtr > 0) || (ReqCtr > 0))
				{
					ReStartCount = 0;
					cNextState = SYS_ADVERTISE_START;
					NextAdvTime = 0;
				}
				else if((NextAdvTime > 0) && (bNmbSegRvd == bNmbSegTotal))
				{
					bSleep = TRUE;
					if(NextAdvTime >= ADVSLEEP_DURATION)
					{
						TransmitTime = ADVSLEEP_DURATION;
						NextAdvTime -= TransmitTime;
					}
					else
					{
						TransmitTime = NextAdvTime;
						NextAdvTime = 0;
					}
					percent = (double)(TransmitTime)/(double)(SLEEP_DURATION);
					bNofReceivers = 0;
					cNextState = SYS_SLEEP;
					
					printTime(timeBuf, 128);
					bSleepType = ADV_NOREQ;
					dbg(DBG_USR2, "NoReq sleep begin at %s\n", timeBuf);							
				}
				else if((NextAdvTime > 0) && ((bNmbSegRvd < bNmbSegTotal) && (!started)))
				{
					bSleep = TRUE;
					if(NextAdvTime >= INITSLEEP_DURATION)
					{
						TransmitTime = INITSLEEP_DURATION;
						NextAdvTime -= TransmitTime;
					}
					else
					{
						TransmitTime = NextAdvTime;
						NextAdvTime = 0;
					}
					percent = (double)(TransmitTime)/(double)(SLEEP_DURATION);
					bNofReceivers = 0;
					cNextState = SYS_SLEEP;
					
					printTime(timeBuf, 128);
					bSleepType = ADV_NOREQ;
					dbg(DBG_USR2, "NoReq sleep begin at %s\n", timeBuf);							
				}
				else
				{
					cNextState = SYS_ADVERTISE_START;
					NextAdvTime = 0;
				}
			}
			else if(bSleepType == INIT_SLEEP)
			{
				if(!started)
				{
					bSleep = TRUE;
					TransmitTime = INITSLEEP_DURATION;	
					percent = (double)(TransmitTime) / (double)(SLEEP_DURATION);
					bNofReceivers = 0;
					ReStartCount = 0;
					cNextState = SYS_SLEEP;
					
					printTime(timeBuf, 128);
					bSleepType = INIT_SLEEP;
					dbg(DBG_USR2, "Init sleep begin at %s\n", timeBuf);
				}	
				else
					cNextState = SYS_IDLE;
			}
			bRePost = TRUE;
		}
		else if( ListenTime > 1000 )
		{
			bWaitSig = SIG_WAKEUP_LISTEN;
			call Timer.start(TIMER_ONE_SHOT, 1000);
			ListenTime -= 1000;
		}
		else
		{
			bWaitSig = SIG_WAKEUP_LISTEN;
			call Timer.start(TIMER_ONE_SHOT, (uint16_t)ListenTime);
			ListenTime = 0;
		}

		break;
		
	default:
		 break;
	}	//switch
// update state
	sSYSState = cNextState; 
	if( bRePost )
		post STATEMACHINE(); //try again
return;
}//TASK Statemachine	

/*****************************************************************************
 receive()
 - message from newtork
******************************************************************************/
event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr msgptr) {
  uint16_t *wptr;
  uint8_t *bptr;
  uint8_t cNextState;
  uint16_t wPID, wSourceID, wCID, wDestID;
  uint8_t cCommand, subcommand;
  uint8_t bRepeat, bNofReq;
  uint16_t i;
  uint8_t bRePost, bSegID;
  uint16_t wTemp;

  if(bSleep)
	return msgptr;
		
  if((sSYSMState == SYSM_FORWARD) || (sSYSMState == SYSM_FORWARD_DONE) || (sSYSMState == SYSM_DOWNLOAD_DONE))
  	return msgptr;
  		
  cNextState = sSYSState; //statemachine updates
  
  bRePost = FALSE;
  
// -------LOCAL COMMANDS addressed to this specific node
  if( (msgptr->addr == TOS_LOCAL_ADDRESS) )
	{
	cCommand = msgptr->data[TS_CMD]; //save the netprog command ID
	subcommand = msgptr->data[TS_SUBCMD]; //save the subcommand ID
	
	switch (cCommand)	     //was [4]
	{
		case CMD_REQ_CIDMISSING:
			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t *)&(msgptr->data[TS_PID]);
			wPID = *wptr;	
			if( (wPID!=0) && (wPID == wProgramID) && (bSegID == bAdvSeg) && (sSYSMState == SYSM_QUERY) )
			{
				wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
				wReqCIDMissing = *wptr+1;

				bRetransmit = TRUE;
				cNextState = SYS_WAIT_FOR_CHANNEL;
				bRePost = TRUE;
			}                                       
			break;
		
		default:
			break; //invalid command
	}//switch command
	if( bRePost )
	{
		sSYSState = cNextState;
		post STATEMACHINE(); //try again
	}
	return msgptr;	//TOS LOCAL COmmand exit  - return original buffer??
   } // if TOS_LOCAL_ADDRESS

// -------BROADCAST COMMANDS
  else if( (msgptr->addr == TOS_BCAST_ADDR) )
  {
	cCommand = msgptr->data[TS_CMD]; //save the  command ID
	subcommand = msgptr->data[TS_SUBCMD]; //save the subcommand ID
	
	switch (cCommand)	     //was [4]
	{
		case CMD_ADVERTISE:
  			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t*)&(msgptr->data[TS_PID]);
			wPID = *wptr;
			wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
			wSourceID = *wptr;
			bptr = (uint8_t*)&(msgptr->data[TS_REQCNT]);
			bNofReq = *bptr;
			wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
			wTemp = *wptr;
			
			if((bSegID > bNmbSegRvd) && (!started))
  				started = TRUE;

			if( (sSYSMState == SYSM_IDLE) && (!bRequestDL) )	// new program comes
			{
				if( (!IsBase(TOS_LOCAL_ADDRESS)) && (bSegID > bNmbSegRvd) && ((wProgramID == 0) || (wPID == wProgramID)))
				{
					bRequestDL = TRUE;
	
					wExpectPID = wPID;
					bExpectSegID = bNmbSegRvd+1;
					wExpectSourceID = wSourceID;
					
					if(bSegID == bExpectSegID)
						bNofRequest = bNofReq;
					else
						bNofRequest = 0;
								
					cNextState = SYS_DL_REQUEST;
					bRePost = TRUE;
				}
			}
			else if( (sSYSMState == SYSM_ADVERTISE) && (!bRequestDL) ) // other motes is sending the same advertisements
			{
				if( (!IsBase(TOS_LOCAL_ADDRESS)) && (bSegID > bNmbSegRvd) && ((wProgramID == 0) || (wPID == wProgramID)) ) 
				{
					bRequestDL = TRUE;
				
					wExpectPID = wPID;
					bExpectSegID = bNmbSegRvd+1;
					wExpectSourceID = wSourceID;
					
					if(bSegID == bExpectSegID)
						bNofRequest = bNofReq;
					else
						bNofRequest = 0;
								
					sSYSMState = SYSM_IDLE;
					cNextState = SYS_DL_REQUEST;
					bRePost = TRUE;
				}
				else if( ( wPID == wProgramID ) && (!bSleep) )
				{
					if(bSegID < bNmbSegRvd)
						smallAdvCtr++;
					if(bNofReq > 0) 
					{
						if((bSegID < bAdvSeg) || 
						((bSegID == bAdvSeg) && ((bNofReq > bNofReceivers) || ((bNofReq == bNofReceivers) && (wSourceID > TOS_LOCAL_ADDRESS)) )) )
						{
							percent = (double)(wTemp+25) / (double)(MNP_CAPSULE_PER_SEGMENT);
							if(percent > 1)
								percent = 1;
							if(percent >= 0.01)
							{
								if( (bSegID>0) && (bSegID<=bNmbSegRvd) )
									bAdvSeg = bSegID;
								else
									bAdvSeg = bNmbSegRvd;
								
								NextAdvTime = (SLEEP_DURATION)*percent;
								if(bNmbSegRvd == bNmbSegTotal)
								{
									bSleep = TRUE;
									TransmitTime = NextAdvTime;
									NextAdvTime = 0;
									percent = (double)TransmitTime / (double)(SLEEP_DURATION);
									bNofReceivers = 0;
									cNextState = SYS_SLEEP;
									
									printTime(timeBuf, 128);
									bSleepType = SENDER_SELECTION;
									dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
								}
								else if((bNmbSegRvd < bNmbSegTotal) && (!started))
								{
									bSleep = TRUE;
									if(NextAdvTime >= INITSLEEP_DURATION)
									{
										TransmitTime = INITSLEEP_DURATION;
										NextAdvTime -= TransmitTime;
									}
									else
									{
										TransmitTime = NextAdvTime;
										NextAdvTime = 0;
									}
									percent = (double)TransmitTime / (double)(SLEEP_DURATION);
									bNofReceivers = 0;
									cNextState = SYS_SLEEP;
									
									printTime(timeBuf, 128);
									bSleepType = SENDER_SELECTION;
									dbg(DBG_USR2, "Contention sleep begin at %s, %f\n", timeBuf);																	
								}
								else
								{
									ListenTime = NextAdvTime;
									NextAdvTime = 0;
									cNextState = SYS_WAKEUP_LISTEN;
									bSleepType = SENDER_SELECTION;
								}
								bRePost = TRUE;
							}
						}
					}
				}
			}
			break;
		
		case CMD_DL_REQUEST:
			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t*)&(msgptr->data[TS_PID]);
			wPID = *wptr;
			wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
			wSourceID = *wptr;
			wptr = (uint16_t *)&(msgptr->data[TS_DESTID]);
			wDestID = *wptr;
			wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
			wTemp = *wptr;
			if((bSegID > bNmbSegRvd) && (!started))
  				started = TRUE;
			if( (sSYSMState == SYSM_ADVERTISE) && (wPID == wProgramID) ) 
			{
					if( bSegID <= bAdvSeg )
					{
						if(bSegID < bAdvSeg)
						{
							bAdvSeg = bSegID;
							bNofReceivers = 0;
							for(i=0; i<(MISSINDICATOR_SIZE); i++)
								ForwardPacketsIndicator[i] = 0;
						}
						
						ReqCtr++;
						
						for(i=0; i<(MISSINDICATOR_SIZE); i++)
							ForwardPacketsIndicator[i] |= msgptr->data[TS_MISS_PACKET+i];
							
						if(wDestID == TOS_LOCAL_ADDRESS)	// this request is for me. 
						{
							bRepeat = FALSE;
							for(i=0; i<bNofReceivers; i++)
							{
								if(ReceiverArray[i]==(wSourceID & 0xff))
								{
									bRepeat = TRUE;
									break;
								}
							}
							if(!bRepeat)
							{
								if(bNofReceivers<REV_ARRAY_SIZE)
								{
									ReceiverArray[bNofReceivers]=wSourceID;
									bNofReceivers++;
								}
							}
						}
						else if(!bSleep)
						{
							bptr = (uint8_t*)&(msgptr->data[TS_REQCNT]);
							bNofReq = *bptr;
							if( (bNofReq > 0) && ((bNofReq > bNofReceivers) || ((bNofReq == bNofReceivers) && (wSourceID > TOS_LOCAL_ADDRESS)) ) )
							{
								percent = (double)(wTemp+25) / (double)(MNP_CAPSULE_PER_SEGMENT);
								if(percent > 1)
									percent = 1;
								if(percent >= 0.01)
								{
									if( (bSegID>0) && (bSegID<=bNmbSegRvd) )
										bAdvSeg = bSegID;
									else
										bAdvSeg = bNmbSegRvd;

									NextAdvTime = (SLEEP_DURATION)*percent;									
									if(bNmbSegRvd == bNmbSegTotal)
									{
										bSleep = TRUE;
										TransmitTime = NextAdvTime;
										NextAdvTime = 0;
										percent = (double)TransmitTime / (double)(SLEEP_DURATION);
										bNofReceivers = 0;
										cNextState = SYS_SLEEP;
										
										printTime(timeBuf, 128);
										bSleepType = SENDER_SELECTION;
										dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
									}
									else if((bNmbSegRvd < bNmbSegTotal) && (!started))
									{
										bSleep = TRUE;
										if(NextAdvTime >= INITSLEEP_DURATION)
										{
											TransmitTime = INITSLEEP_DURATION;
											NextAdvTime -= TransmitTime;
										}
										else
										{
											TransmitTime = NextAdvTime;
											NextAdvTime = 0;
										}
										percent = (double)TransmitTime / (double)(SLEEP_DURATION);
										bNofReceivers = 0;
										cNextState = SYS_SLEEP;
										
										printTime(timeBuf, 128);
										bSleepType = SENDER_SELECTION;
										dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
									}
									else
									{
										ListenTime = NextAdvTime;
										NextAdvTime = 0;
										cNextState = SYS_WAKEUP_LISTEN;
										bSleepType = SENDER_SELECTION;
									}
									bRePost = TRUE;
								}
							}
						}
					}
			}
			break;
			
		case CMD_START_DOWNLOAD: //Header info for a code download
			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
			wSourceID = *wptr;
			wptr = (uint16_t*)&(msgptr->data[TS_PID]);
			wPID = *wptr;
			wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
			wTemp = *wptr;
			if((bSegID > bNmbSegRvd) && (!started))
  				started = TRUE;
			if(sSYSMState == SYSM_IDLE)
			{
				if( (!IsBase(TOS_LOCAL_ADDRESS)) && (bSegID == bNmbSegRvd+1) && ((wProgramID == 0) || (wPID == wProgramID)) )
				{
					if(wProgramID == 0) 
						wProgramID = wPID;
					wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
					wParentID = *wptr;
					wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
					wNofCapsules = *wptr;
					for(i=wNofCapsules+1; i<=MNP_CAPSULE_PER_SEGMENT; i++)
					{
						MarkReceive(i);		
					}				
					if(bNmbSegTotal == 0)
					{
						bptr = (uint8_t*)&(msgptr->data[TS_TOTAL_SEGMENT]);
						bNmbSegTotal = *bptr;
					}
					if(bSegID == bNmbSegTotal)
						wLastSegSize = wNofCapsules;
					cNextState = SYS_DL_START;
					bRePost = TRUE;
				}
			}
			else if(sSYSMState == SYSM_ADVERTISE)   
			{
				if( (!IsBase(TOS_LOCAL_ADDRESS)) && (bSegID == bNmbSegRvd+1) && ((wProgramID == 0) || (wPID == wProgramID)) )
				{
					if(wProgramID == 0)
						wProgramID = wPID;
					wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
					wParentID = *wptr;
					wptr = (uint16_t*)&(msgptr->data[TS_CAPSULEID]);
					wNofCapsules = *wptr;
					for(i=wNofCapsules+1; i<=MNP_CAPSULE_PER_SEGMENT; i++)
					{
						MarkReceive(i);			
					}
					if(bNmbSegTotal == 0)
					{
						bptr = (uint8_t*)&(msgptr->data[TS_TOTAL_SEGMENT]);
						bNmbSegTotal = *bptr;
					}
					if(bSegID == bNmbSegTotal)
						wLastSegSize = wNofCapsules;
					cNextState = SYS_DL_START;
					bRePost = TRUE;
				}
				else if(!bSleep)
				{
					percent = (double)(wTemp+10) / (double)(MNP_CAPSULE_PER_SEGMENT);
					if(percent > 1)
						percent = 1;
					if(percent >= 0.01)
					{
						if( (bSegID>0) && (bSegID<=bNmbSegRvd) )
							bAdvSeg = bSegID;
						else
							bAdvSeg = bNmbSegRvd;

						NextAdvTime = (SLEEP_DURATION)*percent;
						if(bNmbSegRvd == bNmbSegTotal)
						{
							bSleep = TRUE;
							TransmitTime = NextAdvTime;
							NextAdvTime = 0;
							percent = (double)TransmitTime / (double)(SLEEP_DURATION);
							bNofReceivers = 0;
							cNextState = SYS_SLEEP;
							
							printTime(timeBuf, 128);
							bSleepType = SENDER_SELECTION;
							dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
						}
						else if((bNmbSegRvd < bNmbSegTotal) && (!started))
						{
							bSleep = TRUE;
							if(NextAdvTime >= INITSLEEP_DURATION)
							{
								TransmitTime = INITSLEEP_DURATION;
								NextAdvTime -= TransmitTime;
							}
							else
							{
								TransmitTime = NextAdvTime;
								NextAdvTime = 0;
							}
							percent = (double)TransmitTime / (double)(SLEEP_DURATION);
							bNofReceivers = 0;
							cNextState = SYS_SLEEP;
							
							printTime(timeBuf, 128);
							bSleepType = SENDER_SELECTION;
							dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
						}
						else
						{
							ListenTime = NextAdvTime;
							NextAdvTime = 0;
							cNextState = SYS_WAKEUP_LISTEN;
							bSleepType = SENDER_SELECTION;
						}						
						bRePost = TRUE;
					}
				}
			}
							
			break;

		case CMD_DOWNLOADING:
			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t *)&(msgptr->data[TS_PID]);
			wPID = *wptr;	
			wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
			wSourceID = *wptr;
			wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
			wCID = *wptr;
			if((bSegID > bNmbSegRvd) && (!started))
  				started = TRUE;
			if( (!IsBase(TOS_LOCAL_ADDRESS)) && (sSYSMState == SYSM_DOWNLOAD) && (bSegID == bNmbSegRvd+1) && (wPID == wProgramID) )
			{
				if(checkMissing(wCID))
				{
					atomic{
					for(i=0; i<DATA_LENGTH; i++)
						pNETTOSMsg->data[i] = msgptr->data[i];
					}
					cNextState = SYS_DL_SRECWRITE;
				}
				else
				{
					iNextCapsuleTiming = NEXTCAPSULE_TIMING;
					cNextState = SYS_WAIT_FOR_NEXT_CAPSULE;
				}
				bRePost = TRUE;
			}
			else if( (!IsBase(TOS_LOCAL_ADDRESS)) && (sSYSMState == SYSM_UPDATE) && (bSegID == bNmbSegRvd+1) && (wPID == wProgramID) )
			{
				if(!haveMissing())
				{
					cNextState = SYS_GETDONE;
				}
				else
				{
					if(checkMissing(wCID))
					{
						atomic{
						for(i=0; i<DATA_LENGTH; i++)
							pNETTOSMsg->data[i] = msgptr->data[i];
						}
						cNextState = SYS_UP_SRECWRITE;
					}
					else
					{
						cNextState = SYS_GET_CIDMISSING;
					}
				}
				bRePost = TRUE;
			}
			else if((sSYSMState == SYSM_ADVERTISE) && (!bSleep))  
			{
				if((bSegID == bNmbSegRvd+1)  && ((wProgramID == 0) || (wPID == wProgramID)) )
				{
					if(wProgramID == 0)
						wProgramID = wPID;
					wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
					wParentID = *wptr;
					wptr = (uint16_t*)&(msgptr->data[TS_TOTAL_CAPSULE]);
					wNofCapsules = *wptr;
					for(i=wNofCapsules+1; i<=MNP_CAPSULE_PER_SEGMENT; i++)
					{
						MarkReceive(i);			
					}
					bptr = (uint8_t*)&(msgptr->data[TS_TOTAL_SEGMENT]);
					bNmbSegTotal = *bptr;
					if(bSegID == bNmbSegTotal)
						wLastSegSize = wNofCapsules;
					cNextState = SYS_DL_START;
					bRePost = TRUE;

					if(checkMissing(wCID))
					{
						atomic{
						for(i=0; i<DATA_LENGTH; i++)
							pNETTOSMsg->data[i] = msgptr->data[i];
						}
						bReceiveData = TRUE;
					}
				}
				else
				{
					percent = (double)(MNP_CAPSULE_PER_SEGMENT -wCID) / (double)(MNP_CAPSULE_PER_SEGMENT);
					if(percent >= 0.01)
					{
						if( (bSegID>0) && (bSegID<=bNmbSegRvd) )
							bAdvSeg = bSegID;
						else
							bAdvSeg = bNmbSegRvd;

						NextAdvTime = (SLEEP_DURATION)*percent;
						if(bNmbSegRvd == bNmbSegTotal)
						{
							bSleep = TRUE;
							TransmitTime = NextAdvTime;
							NextAdvTime = 0;
							percent = (double)TransmitTime / (double)(SLEEP_DURATION);
							bNofReceivers = 0;
							cNextState = SYS_SLEEP;
							
							printTime(timeBuf, 128);
							bSleepType = SENDER_SELECTION;
							dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
						}
						else if((bNmbSegRvd < bNmbSegTotal) && (!started))
						{
							bSleep = TRUE;
							if(NextAdvTime >= INITSLEEP_DURATION)
							{
								TransmitTime = INITSLEEP_DURATION;
								NextAdvTime -= TransmitTime;
							}
							else
							{
								TransmitTime = NextAdvTime;
								NextAdvTime = 0;
							}
							percent = (double)TransmitTime / (double)(SLEEP_DURATION);
							bNofReceivers = 0;
							cNextState = SYS_SLEEP;
							
							printTime(timeBuf, 128);
							bSleepType = SENDER_SELECTION;
							dbg(DBG_USR2, "Contention sleep begin at %s\n", timeBuf);																	
						}
						else
						{
							ListenTime = NextAdvTime;
							NextAdvTime = 0;
							cNextState = SYS_WAKEUP_LISTEN;
							bSleepType = SENDER_SELECTION;
						}
						bRePost = TRUE;
					}
				}
			}
			else if( (sSYSMState == SYSM_IDLE) && (!bSleep) )  
			{
				if((bSegID == bNmbSegRvd+1)  && ((wProgramID == 0) || (wPID == wProgramID)) )
				{
					if(wProgramID == 0)
						wProgramID = wPID;
					wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
					wParentID = *wptr;
					wptr = (uint16_t*)&(msgptr->data[TS_TOTAL_CAPSULE]);
					wNofCapsules = *wptr;
					for(i=wNofCapsules+1; i<=MNP_CAPSULE_PER_SEGMENT; i++)
					{
						MarkReceive(i);			
					}
					bptr = (uint8_t*)&(msgptr->data[TS_TOTAL_SEGMENT]);
					bNmbSegTotal = *bptr;
					if(bSegID == bNmbSegTotal)
						wLastSegSize = wNofCapsules;
					cNextState = SYS_DL_START;
					bRePost = TRUE;

					if(checkMissing(wCID))
					{
						atomic{
						for(i=0; i<DATA_LENGTH; i++)
							pNETTOSMsg->data[i] = msgptr->data[i];
						}
						bReceiveData = TRUE;
					}
				}
			}
			break;

		case CMD_DOWNLOAD_COMPLETE:
			bptr = (uint8_t*)&(msgptr->data[TS_SUBCMD]);
			bSegID = *bptr;
			wptr = (uint16_t *)&(msgptr->data[TS_SOURCEID]);
			wSourceID = *wptr;
			wptr = (uint16_t *)&(msgptr->data[TS_PID]);
			wPID = *wptr;	
			if((bSegID > bNmbSegRvd) && (!started))
  				started = TRUE;
			if( (!IsBase(TOS_LOCAL_ADDRESS)) && (wParentID == wSourceID) && (sSYSMState == SYSM_DOWNLOAD) && (!bGotTermDownload) && (wPID == wProgramID) )
			{
				bGotTermDownload = TRUE;
				cNextState = SYS_DL_END;
				bRePost = TRUE;
			}
			break;

	default:
            break; //invalid command
	}//switch command
	if( bRePost )
	{
		sSYSState = cNextState;
		post STATEMACHINE(); //try again
	}
	return msgptr;	//TOS broadcast COmmand exit  - return original buffer??
   } // if TOS_BCAST
  return msgptr;
}//event receivermsg

/*****************************************************************************
SendDone
TOS Message Sent
*****************************************************************************/
event result_t SendMsg.sendDone(TOS_MsgPtr msg_rcv, bool success) {
    
    ptrmsg = msg_rcv;               //hold onto the buffer for next message
    bTOSMsgBusy = FALSE;            //broadcast message complete
	if((sSYSMState == SYSM_FORWARD) && (bSendSig == SIG_FORWARD_RESUME_DONE))
	{
		sSYSState = SYS_FORWARD_CONTINUE;
		post STATEMACHINE();
	}
	bSendSig = 0;
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
	uint16_t *wptr;
	uint8_t cRet;
	if(bEELine1 )	{  //write 2nd line out-still busy
		bEELine1 = FALSE;
	    cRet = call EEPROMWrite.write(wEE_LineW, (uint8_t*)&ELBuff[ELBUFF_SIZE/2]);
        //wEE_LineW++;	 //EELine now maintained by SREC Parser
		return( TRUE );
    }  
	bEEPROMBusy=0;
	wptr = (uint16_t*)&(ELBuff[POS_CID]);
	wCapsuleNo = (*wptr)-(bNmbSegRvd*(MNP_CAPSULE_PER_SEGMENT));
	post STATEMACHINE(); //execute the Statemachine for next state
    return(TRUE); 
}

/*****************************************************************************
 endWriteDone()
 -  finished use of eeprom for writing - release resource
*****************************************************************************/
event result_t EEPROMWrite.endWriteDone(result_t success){
	bEEWriteContinuous = FALSE;
	bEEWriteEnabled = 0;          //disable writing
	return(success);	 //1=success
}
/******************************************************************************
* setIDs
* -Check to see if Mote_Id and Group_Id are in Atmega eeprom. 
* -If values returned <>0xff then assume the Mote_Id and Group_Id were 
*  stored in eeprom during net reprogramming.
* -This function shoule be called by client application when it is initiated.
 ******************************************************************************/
command result_t Mnp.setIDs(){
/*  uint8_t  cTemp;
  uint16_t wTemp;
    if((cTemp=eeprom_read_byte ((uint8_t *)AVREEPROM_GROUPID_ADDR)) != 0xFF )
    	TOS_AM_GROUP = cTemp;

    if((wTemp=eeprom_read_word ((uint16_t *)AVREEPROM_LOCALID_ADDR)) != 0xFFFF )
    	TOS_LOCAL_ADDRESS = wTemp;*/
  return SUCCESS;
}

/*************************************************************************
fStartDownload
Signal client application for Request
*************************************************************************/
void fStartDownload()  {
		//Initialize EEPROM writing
		wEEProgStart = DEF_PROG_START<<4;      //reset eeprom write count

		wCapsuleNo = 0; 
		bRequestDL = FALSE;
		bDownloadEnd = FALSE;
		
		bForwardInit = FALSE;
		bSleep = FALSE;
		bChannelTries = 0;
		bGotQry = FALSE;
		
		signal Mnp.downloadRequest(wProgramID);

		//now wait for client to respond. If doesnt should have a timeout and goto idle?
	return;
}//fStartDownload

/******************************************************************************
 requestGranted
 Acknowledge from Client to proceed/cancel reprogramming
******************************************************************************/
command result_t Mnp.requestGranted(uint16_t progID, bool grant_or_deny)
{
	if(!grant_or_deny)
	{
		// Clinet does not allow download
		sSYSState = SYS_DL_FAIL;	// download aborted
	}
	else
	{
		// Client allows download
		sSYSState = SYS_DL_START1;	// start download
	}	
	post STATEMACHINE();
	return (FALSE);
}

/*************************************************************************
fSRECStore
Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.
*************************************************************************/
void fSRECStore(TOS_MsgPtr msgptr)  {
	unsigned short wTemp, wTemp2;
	uint8_t bSRecValid;
	uint16_t *wptr;
	
	if( sSYSMState != SYSM_DOWNLOAD ) {
			sSYSState = SYS_DL_FAIL;
			post STATEMACHINE();
			return;	//back to statemachine
			}

	//Get and check capsule #
	wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
	wTemp = *wptr;	
	if(!checkMissing(wTemp))
	{
		iNextCapsuleTiming = NEXTCAPSULE_TIMING;
		sSYSState = SYS_WAIT_FOR_NEXT_CAPSULE;
		post STATEMACHINE();
		return;	
	}	

	bSRecValid = fSRECParse( msgptr );		//parse the srec
	if(!bSRecValid) {
		iNextCapsuleTiming = NEXTCAPSULE_TIMING;
		sSYSState = SYS_WAIT_FOR_NEXT_CAPSULE;
	   	post STATEMACHINE();
		return;	 //back to statemachine  
	}//!srecvalid

	wCapsuleNo = wTemp;
	
	MarkReceive(wCapsuleNo);
	//if srec parsed then save to external flash   -Capsule starts at 1
	wTemp2 = (bNmbSegRvd*(MNP_CAPSULE_PER_SEGMENT))+wCapsuleNo;
	wEE_LineW = wEEProgStart + (wTemp2<<1);	 //2 lines per srec
	bEELineWritePending = TRUE;	//main state machine handles posting task and busy retries
	sSYSState = SYS_EEFLASH_WRITEDONE;
   	post STATEMACHINE();//store srec to eeprom
   	
return;
} //fsrecstore

/*************************************************************************
fSRECUpdate
Got an update code capsule containing 1 srec from radio
Replaces a missing or bad srec in EEFLASH 

Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.

*************************************************************************/
void fSRECUpdate(TOS_MsgPtr msgptr)  {
	uint8_t bRet;
	unsigned short wTemp, wTemp2;
	uint8_t bSRecValid;
	uint16_t *wptr;
	
	if( sSYSMState != SYSM_UPDATE ) {
			sSYSState = SYS_DL_FAIL;
		   	post STATEMACHINE();
			return;
			}

	//Get and check capsule #
	wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
	wTemp = *wptr;	
	if(!checkMissing(wTemp))
	{
		sSYSState = SYS_GET_CIDMISSING;
		post STATEMACHINE();
		return;	
	}	

	bSRecValid = fSRECParse( msgptr );		//parse the srec
	if(!bSRecValid) 
	{
		sSYSState = SYS_GET_CIDMISSING;
	   	post STATEMACHINE();
		return;	 //back to statemachine  
	}//!srecvalid

	wCapsuleNo = wTemp;
	
	//if srec parsed then save to external flash   -Capsule starts at 1
	wTemp2 = (bNmbSegRvd*(MNP_CAPSULE_PER_SEGMENT))+wTemp;
	wEE_LineW = wEEProgStart + (wTemp2<<1);	 //2 lines per srec

	bEELineWritePending = TRUE;	//main state machine handles posting task and busy retries
    	if( !bEEWriteEnabled ) { //here if doing random SREC writes so must Writeenable the EEFLASH
    	bRet = call EEPROMWrite.startWrite();
	    if( !bRet )	{	  //eeprom not available
			sSYSState = SYS_GET_CIDMISSING;
		   	post STATEMACHINE();
			return;
			}
		}//!beeLocked
	bEEWriteEnabled = 1;        // eeprom writing enabled flag
	bEEWriteContinuous = FALSE; //MUST release EEFLASH WriteEnable to do future reads on EEFLASH

	sSYSState = SYS_EEFLASH_WRITEDONE;
   	post STATEMACHINE();//store srec to eeprom
	
return;
} //fsrecupdate

/*************************************************************************
EEPROM_READ_DONE
EEPROM read record completed.
Handle per current state
*************************************************************************/

event result_t EEPROMRead.readDone(uint8_t *pEEB, result_t result){

uint8_t i, j;
//uint16_t* pW;
//uint16_t	wCID,wPID, wTemp;
//uint8_t cSRecType;
uint8_t cLen;
uint8_t cCurrentState;

cCurrentState = sSYSState;

switch (cCurrentState)
{
case SYS_FORWARDING:
		ptrmsg->data[TS_CMD] = CMD_DOWNLOADING;
		ptrmsg->data[TS_SUBCMD] = bAdvSeg;
		ptrmsg->data[TS_PID] = wProgramID;
		ptrmsg->data[TS_PID+1] = wProgramID>>8;
		ptrmsg->data[TS_CAPSULEID] = wCapsuleNo;
		ptrmsg->data[TS_CAPSULEID+1] = wCapsuleNo>>8;
		ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
		ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
		ptrmsg->data[TS_TOTAL_CAPSULE] = wNofCapsules;
		ptrmsg->data[TS_TOTAL_CAPSULE+1] = wNofCapsules>>8;
		ptrmsg->data[TS_TOTAL_SEGMENT] = bNmbSegTotal;

		if( (wCapsuleNo == wNofCapsules) && (bAdvSeg == bNmbSegTotal) )
		{
			ptrmsg->data[TS_TYPE] = SREC_S9;
			ptrmsg->data[TS_LEN] = cLen = 3;
			ptrmsg->data[TS1_ADDR_LSB] = 0;
			ptrmsg->data[TS1_ADDR_LSB+1] = 0;
			ptrmsg->data[TS1_ADDR_LSB+2] = 0xFC;		

			bSendSig = SIG_FORWARD_RESUME_DONE;
			if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
			{
//				dbg(DBG_USR1, "FORWARD FAIL\n");
				bTOSMsgBusy = FALSE;
				sSYSState = SYS_SEND_FAIL;
				post STATEMACHINE();
				return (1);
			}
			else
			{
				bTOSMsgBusy = TRUE;
				MarkForward(wCapsuleNo);
				dbg(DBG_USR1, "FORWARD S9 %d\n", wCapsuleNo);			
				bWaitSig = SIG_FORWARD_RESUME_DONE;
				call Timer.start(TIMER_ONE_SHOT, WAIT_FORWARD_RATE);
			}
		}
		else
		{
			ptrmsg->data[TS_TYPE] = SREC_S1;
			ptrmsg->data[TS_LEN] = cLen = 19;

			for (i=0, j=TS1_ADDR_LSB; i<cLen; i++, j++)
			{
				ptrmsg->data[j] = i;
			}

			wEE_LineR++;
			sSYSState = SYS_FORWARD_RESUME;
			post STATEMACHINE();
			return (1);
		}

/*	pW = (uint16_t*)&(pEEB[POS_PID]);
	wPID = *pW;
	pW = (uint16_t*)&(pEEB[POS_CID]);
	wCID = *pW;
	wCID -= ((bAdvSeg-1)*(MNP_CAPSULE_PER_SEGMENT));

	if( wPID != wProgramID )
	{
	// something is wrong
		if(((bAdvSeg-1)>=0) && ((bAdvSeg-1)<bNmbSegRvd))
			bNmbSegRvd = bAdvSeg -1;
		else
			bNmbSegRvd = 0;
		for(i=0; i<(MISSINDICATOR_SIZE); i++)
		{
			MissPacketsIndicator[i] = 0xFF;
		}
		sSYSState = SYS_DL_FAIL;
		post STATEMACHINE();
		return (1);
	}
		
	cSRecType = pEEB[POS_STYPE];
	
	atomic{
	ptrmsg->data[TS_CMD] = CMD_DOWNLOADING;
	ptrmsg->data[TS_SUBCMD] = bAdvSeg;
	ptrmsg->data[TS_PID] = wPID;
	ptrmsg->data[TS_PID+1] = wPID>>8;
	ptrmsg->data[TS_CAPSULEID] = wCID;
	ptrmsg->data[TS_CAPSULEID+1] = wCID>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
		
	// When SYS_FORWARD_RESUME uses the same buffer ptrmsg, it clears up the whole buffer. So, we have to have a backup here
	sptrmsg->data[TS_CMD] = CMD_DOWNLOADING;
	sptrmsg->data[TS_SUBCMD] = bAdvSeg;
	sptrmsg->data[TS_PID] = wPID;
	sptrmsg->data[TS_PID+1] = wPID>>8;
	sptrmsg->data[TS_CAPSULEID] = wCID;
	sptrmsg->data[TS_CAPSULEID+1] = wCID>>8;
	sptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	sptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
	}

	switch ( cSRecType ) {
	case SREC_S1: 
		atomic{
		ptrmsg->data[TS_TYPE] = SREC_S1;
		ptrmsg->data[TS_LEN] = cLen = pEEB[POS_SNOFB];
		ptrmsg->data[TS1_ADDR_LSB] = pEEB[POS_S1_ADDR];
		ptrmsg->data[TS1_ADDR_MSB] = pEEB[POS_S1_ADDR+1];
		
		sptrmsg->data[TS_TYPE] = SREC_S1;
		sptrmsg->data[TS_LEN] = cLen = pEEB[POS_SNOFB];
		sptrmsg->data[TS1_ADDR_LSB] = pEEB[POS_S1_ADDR];
		sptrmsg->data[TS1_ADDR_MSB] = pEEB[POS_S1_ADDR+1];
		}
		cLen = cLen - 2;	
		atomic{
		for (i=POS_S1_I0, j=TS_INSTR0_MSB; (i<(ELBUFF_SIZE/2)) && (i < (POS_S1_I0+cLen)); i++, j++)
		{
			ptrmsg->data[j] = pEEB[i];
			sptrmsg->data[j] = pEEB[i];
		}
		}
		resumePos = j;
		remainLen = cLen - ((ELBUFF_SIZE/2) - (POS_S1_I0));
			
		if( remainLen > 0 )
		{
			wEE_LineR++;
			sSYSState = SYS_FORWARD_RESUME;
			post STATEMACHINE();
			return (1);
		}
		else
		{
			pW = (uint16_t*)&(ptrmsg->data[TS_CAPSULEID]);
			wTemp = *pW;
			MarkForward(wTemp);
				
			bSendSig = SIG_FORWARD_RESUME_DONE;
			if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
			{
				bTOSMsgBusy = FALSE;
//				sSYSState = SYS_SEND_FAIL;
//				post STATEMACHINE();
				return (1);
			}
			else
			{
				bTOSMsgBusy = TRUE;					
			}
		}
		break;
		
	case SREC_S9:
		atomic{
		ptrmsg->data[TS_TYPE] = SREC_S9;
		ptrmsg->data[TS_LEN] = cLen = pEEB[POS_SNOFB];
		ptrmsg->data[TS1_ADDR_LSB] = pEEB[POS_S1_ADDR];
		ptrmsg->data[TS1_ADDR_MSB] = pEEB[POS_S1_ADDR+1];
		}
		pW = (uint16_t*)&(ptrmsg->data[TS_CAPSULEID]);
		wTemp = *pW;
		MarkForward(wTemp);
			
		bSendSig = SIG_FORWARD_RESUME_DONE;
		if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
		{
			bTOSMsgBusy = FALSE;
//			sSYSState = SYS_SEND_FAIL;
//			post STATEMACHINE();
			return (1);
		}
		else
		{
			bTOSMsgBusy = TRUE;
		}			
		break;
	
	default: 
		bTOSMsgBusy = FALSE;
		return (1);
	}*/
	break;
	
case SYS_FORWARD_RESUME:
/*	atomic{
		for(i=0, j=resumePos; i<remainLen; i++, j++)
			ptrmsg->data[j] = pEEB[i];
	}
	
	sSYSState = SYS_FORWARD_RESUME_DONE_PRE;*/
	sSYSState = SYS_FORWARD_RESUME_DONE;	
	post STATEMACHINE();
	break;
	
default:
	break;
} //switch
return( 1 );
}

/*************************************************************************
fSendStatus
Build a Status TOS message and Send it to Generic Com if RF not busy
*************************************************************************/
void fSendStatus()
{
  ptrmsg->data[TS_CMD]    =  20;             
  ptrmsg->data[TS_SUBCMD]    =  TOS_LOCAL_ADDRESS;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wProgramID;	   
  ptrmsg->data[TS_PID+1]    =  wProgramID>>8;  

	ptrmsg->data[TS_SOURCEID] = wParentID;
	ptrmsg->data[TS_SOURCEID+1] = wParentID>>8;
	
	ptrmsg->data[TS_MSGDATA+2] = sSYSMState;
	ptrmsg->data[TS_MSGDATA+3] = sSYSState;
	ptrmsg->data[TS_MSGDATA+4] = bRequestDL;
	ptrmsg->data[TS_MSGDATA+5] = bTOSMsgBusy;
	ptrmsg->data[TS_MSGDATA+6] = bEEPROMBusy;
	
	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH,ptrmsg)))
		bTOSMsgBusy = FALSE;
	else
		bTOSMsgBusy = TRUE;

  return;		
}  //fSendStatus

/*************************************************************************
fReqMissingCapsule
Request a missing capsule
*************************************************************************/
void fReqMissingCapsule(uint16_t wlPID, uint16_t wlCIDMissing)
{
  uint8_t i;

  wlCIDMissing--; 	//Network wants CID 0 based on return but 1 on xmit
  ptrmsg->data[TS_CMD]    =  CMD_REQ_CIDMISSING;             
  ptrmsg->data[TS_SUBCMD]    =  bNmbSegRvd+1;   // lsbye of moteid
  ptrmsg->data[TS_PID]    =  wlPID;	   
  ptrmsg->data[TS_PID+1]    =  wlPID>>8;  
  ptrmsg->data[TS_CAPSULEID]    =  wlCIDMissing;				   
  ptrmsg->data[TS_CAPSULEID+1]    =  wlCIDMissing>>8;				   
  ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
  ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
  for (i=8;i<20;i++ )
 	 ptrmsg->data[i]  = i;  //fill

  wlCIDMissing++; //restore to 1 based
	
	if(!(call SendMsg.send(wParentID, DATA_LENGTH,ptrmsg)))
		bTOSMsgBusy = FALSE;
	else
	{
		bTOSMsgBusy = TRUE;
	}	

  return;		
}  //fmissingcid

/*************************************************************************
fSRECParse

Computes destination EEFlash address based on SREC address and stores in
EEFlash. Does NOT respond to Host - this used during Broadcast downloads.

Accepts non-contiguous srecs.

If bEEPROMBusy we abort because EEBuf is not available

NOTE
1. Changes sSYSState if last/S9 record

Copies into a local buffer for passing to EEFLASH driver. The source buffer
(TOSMsg) is not available after function returns because TOS reuses it.
*************************************************************************/
uint8_t fSRECParse(TOS_MsgPtr msgptr)  {
	uint8_t i,j;
	uint8_t cLen;
	uint8_t cSRecType;
	uint8_t bSRecValid;
	uint16_t* wptr;
	uint16_t wCID;

	if( bEEPROMBusy )
		return(FALSE);	   //busy so ignore

	wptr = (uint16_t *)&(msgptr->data[TS_PID]);
	if(*wptr != wProgramID)
		return FALSE;

	wptr = (uint16_t *)&(msgptr->data[TS_CAPSULEID]);
	wCID = *wptr;
	wCID = (*wptr)+(bNmbSegRvd*(MNP_CAPSULE_PER_SEGMENT));

	bSRecValid = TRUE;	//assume we can parse the sREC
	cSRecType = msgptr->data[TS_TYPE];
	switch ( cSRecType ) {

	case SREC_S1:
/*---------------------------------------------------------------------------
Build	S1 in binary format-2byte address field
S11300700C9463000C9463000C9463000C94630070
S11300800C9463000C9463000C94630011241FBE51
S1130090CFEFD0E1DEBFCDBF11E0A0E0B1E0EAEEEA
----------------------------------------------------------------------------*/
		ELBuff[POS_PID] = wProgramID;	   
		ELBuff[POS_PID+1] = wProgramID>>8;	   
		ELBuff[POS_CID] = wCID;	   
		ELBuff[POS_CID+1] = wCID>>8;	   
		//Build an SREC Format
		ELBuff[POS_STYPE] = SREC_S1;
		ELBuff[POS_SNOFB] = cLen = msgptr->data[TS_LEN];		//get nof bytes in srec
		ELBuff[POS_S1_ADDR] = msgptr->data[TS1_ADDR_LSB];	   //lsbyte of address
		ELBuff[POS_S1_ADDR+1] = msgptr->data[TS1_ADDR_MSB];  //mostbyte of address

		//fill the buffer with data section of the SRec	w/ lsbyte first
		cLen = (cLen - 3); //nof Instructions (bytes)
		for (i=POS_S1_I0,j=TS_INSTR0_MSB;i<POS_S1_I0+cLen;i++,j++ ) {		 //inc by instructions not bytes
			ELBuff[i] = msgptr->data[j];	 //get lsbyte
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
		ELBuff[POS_CID] = wCID;	   
		ELBuff[POS_CID+1] = wCID>>8;	   
		//Build an SREC Format
		ELBuff[POS_STYPE] = SREC_S9;
		//srec9 only has 2byte address
		ELBuff[POS_SNOFB] = cLen = msgptr->data[TS_LEN];		//get nof bytes in srec
		
		ELBuff[POS_S1_ADDR] = msgptr->data[TS1_ADDR_LSB];	   //lsbyte of address
		ELBuff[POS_S1_ADDR+1] = msgptr->data[TS1_ADDR_MSB];  //midsbyte of address
		break;
		
	default:
		bSRecValid = FALSE;	//unrecognized sREC
		break;	//unknown SRec type

	}//switch srectype

return(bSRecValid);
}//fSRECParse

/*************************************************************************
fSysVarInit
Init all VARS to defaults
*************************************************************************/
void fSysVarInit()  {
	uint16_t i;
	
	sSYSState = SYS_IDLE;
	wCapsuleNo = 0; //code capsule number
	wNofCapsules = 0;	//expected number of capsules
	bEEWriteEnabled = 0;          //no EEFLASH after init
	wEEProgStart = DEF_PROG_START<<4;
	bNmbSegRvd = 0;
	bAdvSeg = 0;
	bNmbSegTotal = 0;
	bEEPROMBusy = 0;     //EPROM available to write
	bEELineWritePending = FALSE;
	bELBuffAWE = TRUE;	//BufferA or B selected for write enable
	bELBuffFull = FALSE; //EEPROM buffer is full and should be flushed
	cLineinPage = 0; //reset the line count	

	//Init message parameters
	ptrmsg = &msg;    //init pointer to buffer
	bTOSMsgBusy = FALSE;       //no message pending
	
	pNETTOSMsg = &revMsg;
	sSYSMState = SYSM_IDLE;
	bLost = FALSE;
	bRequestDL = FALSE;
	wProgramID = 0;
	wCIDMissing = 0;
	wCIDMissingPrevious = 0;
	wExpectPID = 0;
	wExpectSourceID = 0;
	bNofRequest = 0;
	
	bGotTermDownload = FALSE;
	bForwardInit = FALSE;
	bSleep = FALSE;
	bSleepType = 0;
	bDownloadEnd = FALSE;
	bChannelTries = 0;
	sptrmsg = &smsg;
	AdRetry = 0;
	wReqCIDMissing = 0;
	wNofLostInSection = 0;
	bUpRead = TRUE;
	
	wParentID = 0;
	bGotQry = FALSE;
	
	channel_rate = FORWARD_RATE;
	bNofReceivers = 0;

	bExpectSegID = 0;
	ReStartCount = 0;
	
	for(i=0; i<(MISSINDICATOR_SIZE); i++)
	{
		MissPacketsIndicator[i] = 0xFF;
	}		
	for(i=0; i<(MISSINDICATOR_SIZE); i++)
		ForwardPacketsIndicator[i] = 0x00;

	bSendSig = 0;
	bReceiveData = FALSE;
	
	started = FALSE;
	percent = 0.0;
	
	bWaitSig = 0;
	
	return;
}//fSysVarInit	   

void fSendStartForward()
{
	ptrmsg->data[TS_CMD] = CMD_START_DOWNLOAD;
	ptrmsg->data[TS_SUBCMD] = bAdvSeg;
	ptrmsg->data[TS_PID] = wProgramID;
	ptrmsg->data[TS_PID+1] = wProgramID>>8;
	ptrmsg->data[TS_CAPSULEID] = wNofCapsules;
	ptrmsg->data[TS_CAPSULEID+1] = wNofCapsules>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
	ptrmsg->data[TS_TOTAL_CAPSULE] = wNofCapsules;
	ptrmsg->data[TS_TOTAL_CAPSULE+1] = wNofCapsules>>8;
	ptrmsg->data[TS_TOTAL_SEGMENT] = bNmbSegTotal;

	dbg(DBG_USR1, "Send start forward of Seg %d\n", bAdvSeg);
	bSendSig = SIG_FORWARD_START;
	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
	{
		bTOSMsgBusy = FALSE;
//		sSYSState = SYS_SEND_FAIL;		
//		post STATEMACHINE();
	}
	else
	{
		bTOSMsgBusy = TRUE;
	}	
}

void fStartForward()
{
	uint16_t wTemp;
	
	if( bEEWriteEnabled )
		call EEPROMWrite.endWrite(); 
	wEEProgStart = DEF_PROG_START<<4;	// the starting point in EEFlash
	bForwardInit = TRUE;
	wCapsuleNo = FindAnyForward();
	if(wCapsuleNo == 0)
	{
		sSYSState = SYS_FORWARD_END;
	}
	else
	{
		wTemp = (bAdvSeg-1)*(MNP_CAPSULE_PER_SEGMENT)+wCapsuleNo;
		wEE_LineR = wEEProgStart + (wTemp<<1);	//2 lines per srec
		sSYSState = SYS_WAIT_FOR_CHANNEL;
	}
}

void fTerminateForward()
{
	ptrmsg->data[TS_CMD] = CMD_DOWNLOAD_COMPLETE;
	ptrmsg->data[TS_SUBCMD] = bAdvSeg;
	ptrmsg->data[TS_PID] = wProgramID;
	ptrmsg->data[TS_PID+1] = wProgramID>>8;
	ptrmsg->data[TS_CAPSULEID] = wNofCapsules;
	ptrmsg->data[TS_CAPSULEID+1] = wNofCapsules>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
	ptrmsg->data[TS_TOTAL_CAPSULE] = wNofCapsules;
	ptrmsg->data[TS_TOTAL_CAPSULE+1] = wNofCapsules>>8;

	dbg(DBG_USR1, "Terminate forward of Seg %d\n", bAdvSeg);
	bSendSig = SIG_FORWARD_END;
	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
	{
		bTOSMsgBusy = FALSE;
//		sSYSState = SYS_SEND_FAIL;
//		post STATEMACHINE();
	}	
	else
	{
		bTOSMsgBusy = TRUE;
	}
}

void fSendQryMessage()
{
	ptrmsg->data[TS_CMD] = CMD_GET_CIDMISSING;
	ptrmsg->data[TS_SUBCMD] = bAdvSeg;
	ptrmsg->data[TS_PID] = wProgramID;
	ptrmsg->data[TS_PID+1] = wProgramID>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;

	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
		bTOSMsgBusy = FALSE;
	else
	{
		bTOSMsgBusy = TRUE;
	}
}

void fSendDLRequest()
{
	uint16_t i;
	
	ptrmsg->data[TS_CMD] = CMD_DL_REQUEST;
	ptrmsg->data[TS_SUBCMD] = bExpectSegID;
	ptrmsg->data[TS_PID] = wExpectPID;
	ptrmsg->data[TS_PID+1] = wExpectPID>>8;
	ptrmsg->data[TS_DESTID] = wExpectSourceID;
	ptrmsg->data[TS_DESTID+1] = wExpectSourceID>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
	ptrmsg->data[TS_REQCNT] = bNofRequest;
	for(i=0; i<(MISSINDICATOR_SIZE); i++)
		ptrmsg->data[TS_MISS_PACKET+i] = MissPacketsIndicator[i];
	
	bSendSig = SIG_DL_REQUEST;
	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
	{
		bTOSMsgBusy = FALSE;
//		sSYSState = SYS_SEND_FAIL;
//		post STATEMACHINE();
	}
	else
	{
		bTOSMsgBusy = TRUE;
		dbg(DBG_USR1, "SendReq Seg %d to %d\n", bExpectSegID, wExpectSourceID);
	}
}

void fSendAdvertise()
{
	if(bAdvSeg == bNmbSegTotal)
		wNofCapsules = wLastSegSize;
	else
		wNofCapsules = MNP_CAPSULE_PER_SEGMENT;	
				
	ptrmsg->data[TS_CMD] = CMD_ADVERTISE;
	ptrmsg->data[TS_SUBCMD] = bAdvSeg;
	ptrmsg->data[TS_PID] = wProgramID;
	ptrmsg->data[TS_PID+1] = wProgramID>>8;
	ptrmsg->data[TS_CAPSULEID] = wNofCapsules;
	ptrmsg->data[TS_CAPSULEID+1]= wNofCapsules>>8;
	ptrmsg->data[TS_SOURCEID] = TOS_LOCAL_ADDRESS;
	ptrmsg->data[TS_SOURCEID+1] = TOS_LOCAL_ADDRESS>>8;
	ptrmsg->data[TS_REQCNT] = bNofReceivers;

	bSendSig = SIG_ADINTERVAL;
	if(!(call SendMsg.send(TOS_BCAST_ADDR, DATA_LENGTH, ptrmsg)))
	{
		bTOSMsgBusy = FALSE;
//		sSYSState = SYS_SEND_FAIL;
//		post STATEMACHINE();
	}
	else
	{
		bTOSMsgBusy = TRUE;
		printTime(timeBuf, 128);
		dbg(DBG_USR1, "time %s\n", timeBuf);
		dbg(DBG_USR1, "SendAdv Seg %d\n", bAdvSeg);
	}
}

void fRetransmit()
{
	uint16_t wTemp;
	
	wTemp = (bAdvSeg-1)*(MNP_CAPSULE_PER_SEGMENT)+wReqCIDMissing;
	wEE_LineR = wEEProgStart+(wTemp<<1);	//2 lines per srec
	call EEPROMRead.read(wEE_LineR, (uint8_t*)&ELBuff);
}

event result_t Timer.fired()
{		
	if( bWaitSig == SIG_REQUEST )
	{
		sSYSState = SYS_WAIT_FOR_REQUEST;
	}
	else if( bWaitSig == SIG_CHANNEL )
	{
		sSYSState = SYS_WAIT_FOR_CHANNEL;
	}
	else if( bWaitSig == SIG_RETRANSMIT )
	{
		sSYSState = SYS_WAIT_FOR_RETRANSMIT;
	}
	else if( bWaitSig == SIG_FORWARD )
	{
		sSYSState = SYS_FORWARD_START;
	}
	else if( bWaitSig == SIG_FORWARD_START )
	{
		if( bFWStartRetry>0 )
		{
			bFWStartRetry--;
			sSYSState = SYS_WAIT_FOR_CHANNEL;
		}
		else
			sSYSState = SYS_START_FORWARDING;
	}
	else if( bWaitSig == SIG_SLEEP )
	{
		if(sSYSState == SYS_SLEEP)
			sSYSState = SYS_SLEEP;
	}
	else if( bWaitSig == SIG_ADINTERVAL )
	{
		bAdvTries = 0;
		sSYSState = SYS_ADINTERVAL;
	}
	else if( bWaitSig == SIG_ADVTRIES )
	{
		sSYSState = SYS_ADINTERVAL;
	}
	else if( bWaitSig == SIG_ADVERTISE_START )
	{
		ReStartCount = 0;
		sSYSState = SYS_ADVERTISE_START;
	}
	else if( bWaitSig == SIG_NEXTCAPSULE )
	{
		if( sSYSState == SYS_WAIT_FOR_NEXT_CAPSULE )
			sSYSState = SYS_WAIT_FOR_NEXT_CAPSULE;
	}
	else if( bWaitSig == SIG_BS_START )
	{
		ReStartCount = 0;
		sSYSState = SYS_ADVERTISE_START;
	}
	else if( bWaitSig == SIG_NONBS_START )
	{
		bSleepType = INIT_SLEEP;
		sSYSState = SYS_WAKEUP_LISTEN;
		sSYSMState = SYSM_IDLE;
	}
	else if(bWaitSig == SIG_WAKEUP_LISTEN)
	{
		if(sSYSState == SYS_WAKEUP_LISTEN)
			sSYSState = SYS_WAKEUP_LISTEN;
	}
	else if( bWaitSig == SIG_REQUESTING )
	{
  		wCIDMissing = FindAnyMissing();
		sSYSState = SYS_WAIT_FOR_CHANNEL;
	}
	else if( bWaitSig == SIG_DL_REQUEST )
	{
		sSYSState = SYS_WAIT_FOR_CHANNEL;
	}
	else if( bWaitSig == SIG_FORWARD_RESUME_DONE )
	{
//		dbg(DBG_USR1, "senddone miss, break\n");
		bTOSMsgBusy = FALSE;
		sSYSState = SYS_FORWARD_CONTINUE;
		bSendSig = 0;
	}
	else if(bWaitSig == SIG_FORWARD_CONTINUE)
	{
		sSYSState = SYS_FORWARD_CONTINUE;
	}
	else if( bWaitSig == SIG_FORWARD_END )
	{
		if( bFWTermRetry>0 )
		{
			bFWTermRetry--;
			sSYSState = SYS_WAIT_FOR_CHANNEL;
		}
		else
			sSYSState = SYS_QRY_DONE;
	}
	
	post STATEMACHINE();
	
	return SUCCESS;
}

uint8_t checkMissing(uint16_t wCID)
{
	uint8_t whichByte, whichBit, ret1;
	whichByte = (wCID-1)/8;
	whichBit = (wCID-1)%8;
	ret1 = (MissPacketsIndicator[whichByte] >> whichBit) & 0x01;
	if(ret1)
		return 1;
	else
		return 0;
}

uint8_t haveMissing()
{
	uint16_t i;
	for(i=0; i<(MISSINDICATOR_SIZE); i++)
	{
		if(MissPacketsIndicator[i]!=0)
			return 1;
	}
	return 0;
}

uint8_t manyMissing()
{
	uint16_t i, sum, whichByte, whichBit;
	sum = 0;
	for(i=0; i<wNofCapsules; i++)
	{
		whichByte = i/8;
		whichBit = i%8;
		sum += (MissPacketsIndicator[whichByte] >> whichBit) & 0x01;
	}
	if(sum < (wNofCapsules*LOSS_LIMIT_PERCENT))
		return 0;
	else
		return 1;
}

uint8_t checkForward(uint16_t wCID)
{
	uint16_t whichByte, whichBit, ret;
	whichByte = (wCID-1)/8;
	whichBit = (wCID-1)%8;
	ret = (ForwardPacketsIndicator[whichByte] >> whichBit) & 0x01;
	return ret;
}

void MarkMissing(uint16_t wCID)
{
	uint16_t whichByte, whichBit;
	whichByte = (wCID-1)/8;
	whichBit = (wCID-1)%8;
	MissPacketsIndicator[whichByte] |= (1<<whichBit);
	return;
}

void MarkReceive(uint16_t wCID)
{
	uint16_t whichByte, whichBit;
	whichByte = (wCID-1)/8;
	whichBit = (wCID-1)%8;
	MissPacketsIndicator[whichByte] &= ~(1<<whichBit);
	return;
}

uint16_t FindAnyMissing()
{
	uint16_t i; 
	uint16_t ret;
	ret = 0;	// if return 0, no missing capsules
	for(i=1; i<=wNofCapsules; i++)
	{
		if(checkMissing(i))
		{
			ret = i;
			return ret;
		}
	}
	return ret;		
}

uint16_t FindAnyForward()
{
	uint16_t i; 
	uint16_t ret;
	ret = 0;	// if return 0, no packet needs to be forwarded
	for(i=1; i<=wNofCapsules; i++)
	{
		if(checkForward(i))
		{
			ret = i;
			return ret;
		}
	}
	return ret;		
}

void MarkForward(uint16_t wCID)
{
	uint16_t whichByte, whichBit;
	whichByte = (wCID-1)/8;
	whichBit = (wCID-1)%8;
	ForwardPacketsIndicator[whichByte] &= ~(1<<whichBit);
	return;
}

bool IsBase(uint16_t addr)
{
	if(addr == BASE_ADDR)
		return TRUE;
	else
		return FALSE;
}

} //end implementation
/*****************************************************************************/
/*ENDOFFILE******************************************************************/
