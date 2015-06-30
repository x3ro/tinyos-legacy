/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */
includes RSSIEngine;
includes RipsDataCollection;
includes RipsDataStore;

module RipsDataCollectionM
{
    provides
    {
        interface RipsDataCollection;
	    interface StdControl;
    }
    uses
    {
        interface RSSIEngine;
        interface Leds;
        interface SendMsg as SendDBGMsg;
        interface RipsDataStore;
	}
}

implementation
{
    enum{
        STATE_STOPPED = 0,
        STATE_READY = 1,
        STATE_RUNNING_SENDER = 10,
        STATE_RUNNING_RECEIVER = 20,
    };
    
	norace uint8_t state;
	norace uint16_t line;
#define NEXT_STATE(STATE) { state = (STATE); line = __LINE__; }

    norace int8_t channel;
    norace int16_t tuning;
    norace uint8_t power;
    
    norace int16_t masterTuneOffset;

    norace float tuningSkew;
    norace int16_t tuningAtChanA;

    //GLOBAL DATA STORE VARIABLES
    norace int8_t *channels;
    norace struct DataCollectionParams *params;
    norace struct SyncPacket *syncPacket;
    norace uint8_t currentHop;

    command void RipsDataCollection.calibrationParamsSet(float calibSkew, int16_t calibOffset)
    {
        tuningAtChanA = calibOffset;
        tuningSkew = calibSkew;
    }
    
    int16_t getTuning(int8_t chan){
        float freqDifference = tuningAtChanA  + (chan - params->channelA) * tuningSkew
                                - params->interferenceFreq * ARITHM_BASE;
        if (freqDifference>0)
            return (int16_t)(freqDifference/TUNE_STEP/ARITHM_BASE+.5);
        else
            return (int16_t)(freqDifference/TUNE_STEP/ARITHM_BASE-.5);
    }
    
    norace void* dataBuffer;
    norace uint8_t numRcvs;
    command	result_t RipsDataCollection.startCollection(uint8_t seqNum, uint16_t assistant, uint8_t collectionType)
    {
        uint8_t tmpNumHops = 0, tmpHopType = (params->algorithmType&0xF0);
        numRcvs = 0xFF;
        if (assistant == TOS_LOCAL_ADDRESS || state != STATE_READY)
            return FAIL;
        
        switch(collectionType&0x0F)
        {
            case NO_HOP:
                channel = params->channelA;
                tuning = params->initialTuning;
                tmpNumHops = 0;

                break;
            case TUNE_2_VEE_HOPA:
            case TUNE_VEE_HOP:
                channel = params->channelA;
                tuning = params->initialTuning;
                tmpHopType = RIPS_DATA;
                tmpNumHops = params->numTuneHops;
                break;
            case FREQ_HOP:
                channel = params->initialChannel;
                tuning = getTuning(channel);
                tmpNumHops = params->numChanHops;
                break;
            case EXACT_FREQS:
                if(params->numChanHops >= CHANNELS_NUM){
                    call Leds.set(7);
                    return FAIL;
                }
                channel = channels[0];
                tuning = getTuning(channel);
                tmpNumHops = params->numChanHops;
                break;
            default:
                return FAIL;
        }

        power = params->masterPwr;
        masterTuneOffset = 0;
        currentHop = 0;

        syncPacket->channelA = channel;
        //syncPacket->channelB = params->channelB;
        syncPacket->assistPwr = params->assistPwr;
        syncPacket->hopType = tmpHopType+(collectionType&0x0F);
        syncPacket->numHops = tmpNumHops;

        dataBuffer = 0;
        
    	NEXT_STATE(STATE_RUNNING_SENDER);
		signal RSSIEngine.done(SUCCESS);

		return SUCCESS;
    }

    event result_t RSSIEngine.receiveSync(uint8_t sender, void	*data, uint8_t length)
    {
        struct SyncPacket* inPacket = data;
                
        // very important -> Engine may signal receiveSync multiple times
        if (state != STATE_READY)
            return FAIL;

        if (inPacket->masterID != TOS_LOCAL_ADDRESS && inPacket->assistID != TOS_LOCAL_ADDRESS && inPacket->rcvID[0]!=ALL_RCVS_TYPE){
            //only certain receivers reply, if exact receivers are specified in syncMsg
            uint8_t i = 0, isReceiver = 0;
            for (i=0; i<NUM_RECEIVERS; i++){
                if (inPacket->rcvID[i] == (uint8_t)TOS_LOCAL_ADDRESS){
                    isReceiver = 1;
                    break;
                }
            }
            if (!isReceiver)
                return FAIL;
        }

        //syncPacket is shared across multiple components; and the measurementSetup is identical to syncPacket's first bytes
        //master sets measurementSetup when starting, all the others set it here
        memcpy(syncPacket, data, sizeof(struct SyncPacket));
        currentHop = 0;
        
		if (syncPacket->assistID == TOS_LOCAL_ADDRESS){
		    NEXT_STATE(STATE_RUNNING_SENDER+1);
    	}
        else{
			NEXT_STATE(STATE_RUNNING_RECEIVER);
		}

        channel = syncPacket->channelA;
        tuning = 0;
        power = syncPacket->assistPwr;
        
        dataBuffer = signal RipsDataCollection.collectionStarted(syncPacket->seqNum, syncPacket->masterID, syncPacket->assistID, syncPacket->hopType);
		
		return SUCCESS;
    }
    
    result_t updateParams()
    {
        if( ++currentHop > syncPacket->numHops ){
            if ((syncPacket->hopType&0x0F) == TUNE_2_VEE_HOPA){
                syncPacket->hopType = (syncPacket->hopType&0xF0)+TUNE_2_VEE_HOPB;
                currentHop = 0;
                //channel = syncPacket->channelB;
                channel = - syncPacket->channelA;
                if (syncPacket->masterID == TOS_LOCAL_ADDRESS)
                    tuning = params->initialTuning;
                return TRUE;
            }
            
            return FALSE;
        }
        else if ( (syncPacket->hopType&0x0F) == TUNE_2_VEE_HOPA || (syncPacket->hopType&0x0F) == TUNE_2_VEE_HOPB 
                ||(syncPacket->hopType&0x0F) == TUNE_VEE_HOP){
            if (syncPacket->masterID == TOS_LOCAL_ADDRESS)
                tuning += params->tuningOffset;
        }
        else if ( (syncPacket->hopType&0x0F) == FREQ_HOP){
            channel += params->channelOffset;
            if (syncPacket->masterID == TOS_LOCAL_ADDRESS)
                tuning = getTuning(channel);
        }
        else if ( (syncPacket->hopType&0x0F) == EXACT_FREQS){
            channel = channels[currentHop];
            if (syncPacket->masterID == TOS_LOCAL_ADDRESS)
                tuning = getTuning(channel);
        }
        else 
            return FALSE;
            
        return TRUE;
    }


	TOS_Msg msg;
	task void reportError()
	{
		*(uint16_t*)(&msg.data[0]) = TOS_LOCAL_ADDRESS;
		*(uint16_t*)(&msg.data[2]) = line;
		*(uint16_t*)(&msg.data[4]) = state;
        call SendDBGMsg.send(TOS_BCAST_ADDR, 5, &msg);
	    NEXT_STATE(STATE_READY);
	    signal RipsDataCollection.collectionEnded(FAIL);
	}
	event result_t SendDBGMsg.sendDone(TOS_MsgPtr p, result_t success)
	{  
	    call Leds.set(6);
	    NEXT_STATE(STATE_READY);
	    signal RipsDataCollection.collectionEnded(FAIL);
	    return SUCCESS;
	}


    async event void RSSIEngine.done(result_t success)
	{
        if (state == STATE_STOPPED){
            call RSSIEngine.restore();
            return;
        }
            
        if( success == FAIL){
            if (!post reportError()){
                call Leds.set(3);
                state = STATE_STOPPED;
                return;
            }
		    signal RipsDataCollection.collectionEnded(FAIL);
		    return;
		}
		else if (success == CRASHED){
		    state = STATE_STOPPED;
		}
		
		switch( state )
		{
		case STATE_RUNNING_SENDER:
			NEXT_STATE(STATE_RUNNING_SENDER+1);
		    call RSSIEngine.sendSyncMH(syncPacket, sizeof(struct SyncPacket),params->tsNumHops);
			break;

		case STATE_RUNNING_SENDER+1:
			NEXT_STATE(STATE_RUNNING_SENDER+2);
			call RSSIEngine.acquire();
			break;

		case STATE_RUNNING_SENDER+2:
			NEXT_STATE(STATE_RUNNING_SENDER+3);
			call RSSIEngine.calibrateTransmit(channel);
			break;

		case STATE_RUNNING_SENDER+3:
			NEXT_STATE(STATE_RUNNING_SENDER+4);
			call RSSIEngine.wait(0);
			break;

		case STATE_RUNNING_SENDER+4:

			NEXT_STATE(STATE_RUNNING_SENDER+5);
			call RSSIEngine.transmitBlock(power, tuning);
			break;

		case STATE_RUNNING_SENDER+5:
		    if ( (syncPacket->hopType&0x0F) == NO_HOP || ! updateParams()){
    			NEXT_STATE(STATE_RUNNING_SENDER+6);
	    		call RSSIEngine.restore();
		    }
            else if ( (syncPacket->hopType&0x0F) == FREQ_HOP || (syncPacket->hopType&0x0F) == EXACT_FREQS){
        		NEXT_STATE(STATE_RUNNING_SENDER+7);
        		call RSSIEngine.calibrateTransmit(channel);
        	}
        	else if ( (syncPacket->hopType&0x0F) == TUNE_2_VEE_HOPB && currentHop == 0 ){
        		NEXT_STATE(STATE_RUNNING_SENDER+7);
        		call RSSIEngine.calibrateTransmit(channel);
        	}
            else{
                NEXT_STATE(STATE_RUNNING_SENDER+4);
                call RSSIEngine.wait(HOP_DELAY_TIME);
            }
            break;

		case STATE_RUNNING_SENDER+6:
	        NEXT_STATE(STATE_READY);
            signal RipsDataCollection.collectionEnded(SUCCESS);
			break;
		
		case STATE_RUNNING_SENDER+7:
			NEXT_STATE(STATE_RUNNING_SENDER+4);
			call RSSIEngine.wait(HOP_DELAY_TIME);
			break;
		
		
		case STATE_RUNNING_RECEIVER:
   			NEXT_STATE(STATE_RUNNING_RECEIVER+1);
			call RSSIEngine.acquire();
			break;
		
		case STATE_RUNNING_RECEIVER+1:
   			NEXT_STATE(STATE_RUNNING_RECEIVER+2);
			call RSSIEngine.calibrateReceive(channel);
			break;
		
		case STATE_RUNNING_RECEIVER+2:
   			NEXT_STATE(STATE_RUNNING_RECEIVER+3);
			call RSSIEngine.wait(0);
			break;

		case STATE_RUNNING_RECEIVER+3:

   			NEXT_STATE(STATE_RUNNING_RECEIVER+4);
   			if ( dataBuffer == 0){
   			    call RSSIEngine.suspendBlock();
   			}
			else 
			{
			    uint8_t algType = syncPacket->hopType&0xF0;
			    switch (algType)
			    {
			    case RAW_DATA:
			        call RSSIEngine.recordBlock(dataBuffer);
    			    break;
			    case RSSI_DATA:
        	        call RSSIEngine.rssiBlock(dataBuffer);
    			    break;
			    case RIPS_DATA:
        	        call RSSIEngine.ripsBlock(dataBuffer);
    			    break;
                default:
                    *((uint8_t*)dataBuffer) = NOT_VALID;    //here we need better error handling -> collectionEnded(FAIL)
    	            call RSSIEngine.suspendBlock();
    	        }
    	    }
			break;

		case STATE_RUNNING_RECEIVER+4:
		    signal RipsDataCollection.reportData(dataBuffer);
		        
		    if ( (syncPacket->hopType&0x0F) == NO_HOP || ! updateParams()){
       			NEXT_STATE(STATE_RUNNING_RECEIVER+5);
	    		call RSSIEngine.restore();
	    	}
            else if ( (syncPacket->hopType&0x0F) == FREQ_HOP || (syncPacket->hopType&0x0F) == EXACT_FREQS){
       			NEXT_STATE(STATE_RUNNING_RECEIVER+6);
	    		call RSSIEngine.calibrateReceive(channel);
        	}
        	else if ( (syncPacket->hopType&0x0F) == TUNE_2_VEE_HOPB && currentHop == 0 ){
       			NEXT_STATE(STATE_RUNNING_RECEIVER+6);
	    		call RSSIEngine.calibrateReceive(channel);
        	}
            else{
                NEXT_STATE(STATE_RUNNING_RECEIVER+3);
                call RSSIEngine.wait(HOP_DELAY_TIME);
            }
            break;

		case STATE_RUNNING_RECEIVER+5:
	        NEXT_STATE(STATE_READY);
            signal RipsDataCollection.collectionEnded(SUCCESS);
			break;

		case STATE_RUNNING_RECEIVER+6:
   			NEXT_STATE(STATE_RUNNING_RECEIVER+3);
			call RSSIEngine.wait(HOP_DELAY_TIME);
			break;
		}
	}

	command result_t StdControl.init()
	{
	    channels = call RipsDataStore.getChannels();
	    params = call RipsDataStore.getParams();
	    syncPacket = call RipsDataStore.getSyncPacket();
		return SUCCESS;
	}

	command result_t StdControl.start()
	{
	    NEXT_STATE(STATE_READY);

		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
	    NEXT_STATE(STATE_STOPPED);
		return SUCCESS;
	}

}

