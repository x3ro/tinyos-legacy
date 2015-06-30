/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:		Su Ping <sping@intel-research.net>
 * Date last modified:  
 *
 */

/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Modify by Tian He 
 */
 
//!! Config 41 { uint8_t UVA_GridX = DEFAULT_GridX; }
//!! Config 42 { uint8_t UVA_GridY = DEFAULT_GridY; }
//!! Config 43 { uint8_t UVA_SenseCntThreshold = DEFAULT_SENSE_CNT_THRESHOLD ; }
//!! Config 44 { uint8_t UVA_SendCntThreshold = DEFAULT_SEND_CNT_THRESHOLD; }
//!! Config 45 { uint8_t UVA_Magthreshold = DEFAULT_MagThreshold; }
//!! Config 46 { uint8_t UVA_RecruitThreshold = DEFAULT_RECRUIT_THRESHOLD; }
//!! Config 47 { uint8_t UVA_EventsBeforeSending = DEFAULT_EVENTS_BEFORE_SENDING; }
//!! Config 48 { uint8_t UVA_BeaconIncluded = DEFAULT_BEACON_INCLUDED; }
//!! Config 49 { uint8_t UVA_SensorDistance = DEFAULT_SENSOR_DISTANCE; }

includes SysSync;

module SysSyncM {
    provides {
        interface SysSync;
        interface StdControl;
    }
    uses {
/*
        interface Time;
		interface TimeSet;
        interface TimeUtil;
*/
        interface TimedLeds;
//		interface StdControl as TimeControl;
		interface SendMsg as SendSyncMsg;
 	    interface ReceiveMsg as SysSyncReceive;
		interface StdControl as CommControl;
   		interface Timer as ReBroadcastTimer;
   		interface Random;
//   		interface Timer as ReSynCTimer;
 
	interface Config_UVA_GridX;
	interface Config_UVA_GridY;
	interface Config_UVA_SenseCntThreshold;
	interface Config_UVA_SendCntThreshold;
	interface Config_UVA_Magthreshold;
	interface Config_UVA_RecruitThreshold;
	interface Config_UVA_EventsBeforeSending;
	interface Config_UVA_BeaconIncluded;
	interface Config_UVA_SensorDistance;
    }
}
implementation
{
    bool forwardFlag;
    uint8_t state; 
    uint8_t numSend; 

    TOS_Msg TxBuffer;
    bool sendPending;

    uint32_t delay; 
       
    task void sendSyncTask();


    void MasterInitParameters();


       
    event result_t ReBroadcastTimer.fired() {        
        post sendSyncTask();
        //dbg(DBG_USR1, "TimerSyn fired\n"); 
        return SUCCESS ;
    }
    
    
    event result_t SendSyncMsg.sendDone(TOS_MsgPtr msg, result_t success) {                    
        sendPending = FALSE;
        return SUCCESS;
    } 
    /**
     * send a time sync message
     **/
    command result_t SysSync.sendSync() {
    

        TOS_MsgPtr pmsg = &TxBuffer;

        struct SysSyncMsg * pdata = (struct SysSyncMsg *) pmsg->data;
		     
        pdata->source_addr = TOS_LOCAL_ADDRESS;
        
        sendPending = call SendSyncMsg.send(TOS_BCAST_ADDR, sizeof(struct SysSyncMsg), pmsg);


      	if (!sendPending) {      	
  			dbg(DBG_USR1, "SysSync.sendSync ReStart\n");
			call ReBroadcastTimer.start(TIMER_ONE_SHOT, 20);
			return SUCCESS;
      	}else{
      		
       		 call TimedLeds.redOn(200); 
       		 numSend++;
       		 if( numSend <= 2 ){
       		 	call ReBroadcastTimer.start(TIMER_ONE_SHOT, 20);
       		 }
       		 
		     if(state == SYS_MASTER && numSend > 2 )
		     {
		     	signal SysSync.ready(TRUE,0,&pdata->Settings); //tian           		  
		     }
      	}
   	

 		return SUCCESS;
    }  

    task void sendSyncTask() {
        call SysSync.sendSync();
    }


    /**
     * Initialize system time
     * Initialize communication leyer
     **/
    command result_t StdControl.init() {
        sendPending = FALSE;

        if (TOS_LOCAL_ADDRESS==BASE_LEADER) {
            state=SYS_MASTER;
            MasterInitParameters();                                                
        } else {
            state = SYS_SLAVE_UNSYNCED;
        }
        numSend = 0;
        forwardFlag = FALSE;
        call CommControl.init();

        return SUCCESS;
    }

    command result_t StdControl.start() {

        call CommControl.start();
        if(state == SYS_MASTER){
         call ReBroadcastTimer.start(TIMER_ONE_SHOT,20);                
        }
        return SUCCESS;
    }


    /** 
     *  @return Always return <code>SUCCESS</code>
     **/
    command result_t StdControl.stop() {
        //call TimeControl.stop();
        if (state!=SYS_MASTER) {
            state = SYS_SLAVE_UNSYNCED;
        }
        return call CommControl.stop() ;
        return SUCCESS;
    }


    /**
     * Receive a time sync message 
     * check the type field. if type is SysSync_REQUEST
     * call SysSync.SysSync
     * else if type is TIME REQUEST, send our current time back  
     * 
     **/

    event TOS_MsgPtr SysSyncReceive.receive(TOS_MsgPtr msg) {
        
       
     	struct SysSyncMsg * RxMsg = (struct SysSyncMsg *) msg->data;
     	SystemParameters * RxSettingPrt = &RxMsg->Settings; 
     	struct SysSyncMsg * TxMsg = (struct SysSyncMsg *) TxBuffer.data;
     	SystemParameters * TxSettingPrt = & TxMsg -> Settings; 
	     	    
	   	if(TOS_LOCAL_ADDRESS==BASE_LEADER || state == SYS_SLAVE_SYNCED)
	   		return msg;
	   		
		TxMsg->source_addr = RxMsg->source_addr;
	     		     	    	          
	     	TxSettingPrt->SEND_CNT_THRESHOLD = RxSettingPrt->SEND_CNT_THRESHOLD;
	     	TxSettingPrt->SENSE_CNT_THRESHOLD = RxSettingPrt->SENSE_CNT_THRESHOLD;	  
	     	TxSettingPrt->RECRUIT_THRESHOLD = RxSettingPrt->RECRUIT_THRESHOLD;		     		     	   	
	     	TxSettingPrt->GridX = RxSettingPrt->GridX;	     	
	     	TxSettingPrt->GridY = RxSettingPrt->GridY;
	     	TxSettingPrt->MagThreshold = RxSettingPrt->MagThreshold; 
	     	TxSettingPrt->EVENTS_BEFORE_SENDING = RxSettingPrt->EVENTS_BEFORE_SENDING; 	 
	     	TxSettingPrt->BEACON_INCLUDED = RxSettingPrt->BEACON_INCLUDED;
	     	TxSettingPrt->SENSOR_DISTANCE = RxSettingPrt->SENSOR_DISTANCE;

        
        
        state=SYS_SLAVE_SYNCED;
        
 
        delay = 0;
	    while(delay == 0) delay = call Random.rand() & 0xf;		
   	    delay = delay * 25+50; 
   	      						            
            call ReBroadcastTimer.start(TIMER_ONE_SHOT,delay);
            call TimedLeds.greenOn(200);                     
            
        signal SysSync.ready(TRUE,TxMsg->source_addr,&TxMsg->Settings);       

        return msg; // keep msg and return the other buffer
    } 
   
    void MasterInitParameters(){               
    
     	struct SysSyncMsg * TxMsg = (struct SysSyncMsg *) TxBuffer.data;
     	SystemParameters * SettingPrt = &TxMsg->Settings; 
	     	
	     if(TOS_LOCAL_ADDRESS==BASE_LEADER)
	     {
	     	SettingPrt->GridX = G_Config.UVA_GridX;
	     	SettingPrt->GridY = G_Config.UVA_GridY;
	     	SettingPrt->SENSE_CNT_THRESHOLD = G_Config.UVA_SenseCntThreshold;
	     	SettingPrt->SEND_CNT_THRESHOLD = G_Config.UVA_SendCntThreshold;
	     	SettingPrt->MagThreshold = G_Config.UVA_Magthreshold;
	     	SettingPrt->RECRUIT_THRESHOLD = G_Config.UVA_RecruitThreshold;
	     	SettingPrt->EVENTS_BEFORE_SENDING = G_Config.UVA_EventsBeforeSending;
	     	SettingPrt->BEACON_INCLUDED = G_Config.UVA_BeaconIncluded;
	     	SettingPrt->SENSOR_DISTANCE = G_Config.UVA_SensorDistance;
	     }
    }

    task void configSettingsUpdated()
    {
      MasterInitParameters();
      if( state == SYS_MASTER ){
        call ReBroadcastTimer.start( TIMER_ONE_SHOT, 20 );
      }
    }
    
    event void Config_UVA_GridX.updated() { post configSettingsUpdated(); }
    event void Config_UVA_GridY.updated() { post configSettingsUpdated(); }
    event void Config_UVA_SenseCntThreshold.updated() { post configSettingsUpdated(); }
    event void Config_UVA_SendCntThreshold.updated() { post configSettingsUpdated(); }
    event void Config_UVA_Magthreshold.updated() { post configSettingsUpdated(); }
    event void Config_UVA_RecruitThreshold.updated() { post configSettingsUpdated(); }
    event void Config_UVA_EventsBeforeSending.updated() { post configSettingsUpdated(); }
    event void Config_UVA_BeaconIncluded.updated() { post configSettingsUpdated(); }
    event void Config_UVA_SensorDistance.updated() { post configSettingsUpdated(); }
}

