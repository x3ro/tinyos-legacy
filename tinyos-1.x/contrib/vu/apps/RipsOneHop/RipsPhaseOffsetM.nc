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
 * @author Miklos Maroti, miklos.maroti@vanderbilt.edu
 * @modified 11/21/05
 */
includes RipsDataCollection;
includes RipsDataStore;
module RipsPhaseOffsetM
{
    provides
    {
        interface RipsPhaseOffset;
        interface StdControl;
    }
    uses
    {
        interface RSSILogger;
        interface RipsDataCollection;
        interface RipsDataStore;
        interface Leds;
        interface Timer;
        interface ReceiveMsg;
        interface SendMsg;
        interface StdControl    as SubControl;
        interface SendMsg       as LogQuerySend; 
        interface ReceiveMsg    as LogQueryRcv;
    }
}

implementation
{
    enum{
        STATE_STOPPED = 0,
        STATE_INIT_ROUTING = 1,
        STATE_TUNING1 = 2,
        STATE_TUNING2 = 3,
        STATE_TUNING_DATA1 = 4,
        STATE_TUNING_DATA2 = 5,
        STATE_MEASUREMENT = 7,
        STATE_MEASUREMENT_DATA = 8,

        STATE_VEE2 = 10,
        STATE_VEE1 = 20,
        
        STATE_DATA_SENDING = 50,
        STATE_READY = 100,
    };
    norace uint8_t state;
    
    norace struct MeasurementSetup *measurementSetup;
    
    /**************             MASTER                ******************/
    void task masterCalculateRadioParams(){
        float calculatedTuningSkew;
        int16_t offsetAtChanA;
        int16_t vee1, vee2;
        uint8_t *bufferStart = call RSSILogger.getBufferStart();
        struct DataCollectionParams *params = (struct DataCollectionParams*)(call RipsDataStore.getParams());
        
        //from Vee1, Vee2, params stored through RSSILogger
        //check if vee1,vee2 are ok, if not go to the ready state
        if (call RSSILogger.getLength() == 0){
            //no data rcvd
            signal RipsPhaseOffset.measurementEnded(FAIL);
            state = STATE_READY;
            return;
        }
        
        vee1 = params->initialTuning*ARITHM_BASE + *((int16_t *)bufferStart);// *params->tuningOffset;
        offsetAtChanA = vee1*TUNE_STEP;
        vee2 = params->initialTuning*ARITHM_BASE + *((int16_t *)(bufferStart+2));// *params->tuningOffset;
        if (state == STATE_TUNING_DATA1)
            calculatedTuningSkew = .0012244l*(float)offsetAtChanA;// .0012244 = 526.629 / 430105.543 = channel_sep / channel_0
        else{
            if (params->channelA == params->channelB)
                calculatedTuningSkew = 0;
            else
                calculatedTuningSkew = (float)(vee2 - vee1)*TUNE_STEP / (params->channelB - params->channelA);
        }
        
        state = STATE_MEASUREMENT;

        call RipsDataCollection.calibrationParamsSet(calculatedTuningSkew,offsetAtChanA);
        if (!call RipsDataCollection.startCollection(measurementSetup->seqNumber, measurementSetup->assistantID, params->algorithmType&0x0F))
            signal RipsPhaseOffset.measurementEnded(FAIL);
    };

 
    event result_t Timer.fired()
    {
        post masterCalculateRadioParams();

        return FAIL;
    }
    
    command result_t RipsPhaseOffset.startRanging(uint8_t seqNumber, uint16_t assistant)
    {
        uint8_t tuningType, tuningState;
        struct DataCollectionParams *params = (struct DataCollectionParams*)(call RipsDataStore.getParams());
        if (params->numVees == 1){
            tuningState = STATE_TUNING1;
            tuningType = TUNE_VEE_HOP;
        }
        else{
            tuningState = STATE_TUNING2;
            tuningType = TUNE_2_VEE_HOPA;
        }

        if (assistant == TOS_LOCAL_ADDRESS || state < STATE_DATA_SENDING)
            return FAIL;

        measurementSetup->seqNumber = seqNumber;
        measurementSetup->masterID = TOS_LOCAL_ADDRESS;
        measurementSetup->assistantID = assistant;
        
        //slaves can be in STATE_DATA_SENDING and need to reset the logger
        call RSSILogger.reset();

        if ( (params->algorithmType&0xF0) != RIPS_DATA){
            //no tuning in this case, collection type is entirely up to the user - however only NO_HOP, FREQ_HOP make sense
            if (!call RipsDataCollection.startCollection(seqNumber, assistant, params->algorithmType))
                return FAIL;
            state = STATE_MEASUREMENT;
            return SUCCESS;            
        }
                    
        if (call RipsDataCollection.startCollection(seqNumber, assistant, tuningType)){
            state = tuningState;
            return SUCCESS;
        }
        
        return FAIL;
    }

    void task masterCollEnded(){
        switch (state)
        {
            case STATE_TUNING1:
                state = STATE_TUNING_DATA1;
                call Timer.start(TIMER_ONE_SHOT, 1000);
                break;
            case STATE_TUNING2:
                state = STATE_TUNING_DATA2;
                call Timer.start(TIMER_ONE_SHOT, 1500);
                break;
            case STATE_MEASUREMENT:
                state = STATE_MEASUREMENT_DATA;
                signal RipsPhaseOffset.measurementEnded(SUCCESS);
                state = STATE_READY;
                break;
        }
    }
    
    /**************             SLAVE                 ******************/
    inline float abs(float a){
        return (a<0)?-a:a;
    }

    void task slaveFindVee();
    uint8_t supportTmp;
    //vee's, maxIdx are int16 because they are in tuning indexing, searchIdx and maxAmpIdx are int8 because they are hop indexes
    int16_t v_finder(struct RipsPacket* data, uint8_t dataLength, int8_t searchIdx){
        struct DataCollectionParams *params = (struct DataCollectionParams *)(call RipsDataStore.getParams());
        uint8_t MAX_ERROR = 5;
        int8_t AMPLIT_WIDTH =  15/params->tuningOffset; //solution is +-1.3kHz from the max amp
        int8_t SEARCH_WIDTH = 25/params->tuningOffset; //supporters are +-1.6kHz from the current idx
        uint8_t maxSupportingData = 0;
        float maxAccumulatedError = 10000.0;   
        int16_t maxAmpIdx = -1;
        int16_t maxIdx = 0;
        float idx;

        if (searchIdx == 0){
            uint8_t maxAmp = 0, i;
            for (i=0; i<dataLength; i++){
                if (maxAmp < (data+i)->amplitude){
                    maxAmp = (data+i)->amplitude;
                    maxAmpIdx = i;
                }
            }
        }
        else
            maxAmpIdx = searchIdx;
                            
        idx = maxAmpIdx - AMPLIT_WIDTH;

        while (idx <= maxAmpIdx + AMPLIT_WIDTH){
            uint8_t supportingData;
            float accumulatedError;
            int8_t minI, maxI, i;
            
            supportingData = 0;
            accumulatedError = 0.0;
            minI = idx-SEARCH_WIDTH;
            if (minI < 0)
                minI = 0;
            maxI = idx+SEARCH_WIDTH;
            if (maxI > dataLength-1 )
                maxI = dataLength-1;

            for (i=minI; i<=maxI; i++){
                float error,freq;
                freq = 0.0625*(data+i)->period; //convert period to Hz
                if (idx != i && freq<1600){     //freqs above 1.6kHz are unreliable
                    error = abs( freq/(params->tuningOffset*abs(i - idx)) - 64.5);//64.5Hz is the tuning step
                    if (error < MAX_ERROR){
                        supportingData += 1;
                        accumulatedError += error;
                    }
                }
            }
            if (supportingData > maxSupportingData || (supportingData == maxSupportingData && accumulatedError < maxAccumulatedError)){
                maxSupportingData = supportingData;
                maxAccumulatedError = accumulatedError;
                maxIdx = idx*params->tuningOffset*ARITHM_BASE;
            }
        
            idx += 0.17; //decreasing this number increases precision of calibration but takes more time
        }
        supportTmp = maxSupportingData;
        return maxIdx;
    }

    #define SUPPORT_LIMIT 4//number of data points to support the vee, necessary to accept this calibration result
    uint8_t veeSent;
    TOS_Msg tuneDataMsg;
    
    void task slaveFindVee(){
        int16_t vee1 = 0;
        struct DataCollectionParams *params = (struct DataCollectionParams *)(call RipsDataStore.getParams());
        uint8_t dataLength = call RSSILogger.getLength();

        call Leds.greenToggle();
        if (state == STATE_VEE2)
            vee1 = v_finder((struct RipsPacket*)(call RSSILogger.getBufferStart()),dataLength/2/sizeof(struct RipsPacket),0);
        else
            vee1 = v_finder((struct RipsPacket*)(call RSSILogger.getBufferStart()),dataLength/sizeof(struct RipsPacket), 0 );

        if (veeSent){// || supportTmp<SUPPORT_LIMIT){// to save energy, actually supportTmp needs to go over limit both times
            state = STATE_READY;
            return;
        }

        ((struct TuneDataMsg*)(tuneDataMsg.data))->id = TOS_LOCAL_ADDRESS;        
        ((struct TuneDataMsg*)(tuneDataMsg.data))->vee1 = vee1;
        ((struct TuneDataMsg*)(tuneDataMsg.data))->sup1 = supportTmp;
        if (state == STATE_VEE2){
            ((struct TuneDataMsg*)(tuneDataMsg.data))->vee2 = v_finder(  (struct RipsPacket*)((call RSSILogger.getBufferStart())+dataLength/2),
                                                                     dataLength/2/sizeof(struct RipsPacket),
                                                                     vee1/params->tuningOffset/ARITHM_BASE       );
            ((struct TuneDataMsg*)(tuneDataMsg.data))->sup2 = supportTmp;
            //if (supportTmp<SUPPORT_LIMIT)
            //    state = STATE_READY;
        }
        else{
            ((struct TuneDataMsg*)(tuneDataMsg.data))->vee2 = 0;
            ((struct TuneDataMsg*)(tuneDataMsg.data))->sup2 = 0;
        }
        
        
        if (!veeSent && (state == STATE_VEE2 || state == STATE_VEE1))
            call SendMsg.send(TOS_BCAST_ADDR, sizeof(struct TuneDataMsg), &tuneDataMsg);

        state = STATE_READY;
    };

    event result_t SendMsg.sendDone(TOS_MsgPtr p, result_t success)
    {
        return SUCCESS;
    }

    norace uint8_t collectionType;
    uint8_t packetBuffer[MAX_PACKET_LENGTH];

    event void *RipsDataCollection.collectionStarted(uint8_t seqNumber, uint16_t master, uint16_t assistant, uint8_t type)
    {
        if (state == STATE_VEE2 || state == STATE_VEE1)
            state = STATE_READY;

        if (state < STATE_DATA_SENDING)
            return 0;
        collectionType = type;
                    
        signal RipsPhaseOffset.measurementStarted(seqNumber, master, assistant);
        call RSSILogger.reset();

        if (assistant == TOS_LOCAL_ADDRESS)
            return 0;
        else{
            if ((type&0xF0) == RAW_DATA)
                return call RSSILogger.recordBuffer(MAX_BUFFER_LENGTH);
            else
                return packetBuffer;
        }
    }

    async event void RipsDataCollection.reportData(void* tempBuffer)
    {
        switch (collectionType & 0xF0)
        {
            case RAW_DATA:
                //don't do anything, would take too much memory
                //the last buffer reported will be available through RSSILogger
                break;
            case RSSI_DATA:
                call RSSILogger.record16(((struct RSSIPacket*)tempBuffer)->avgSample);
                break;
            case RIPS_DATA:
                memcpy(call RSSILogger.recordBuffer(sizeof(struct RipsPacket)),tempBuffer,sizeof(struct RipsPacket));
                break;
        }
    }
        
    void task slaveCollEnded(){
        switch (collectionType&0x0F)
        {
            case TUNE_2_VEE_HOPA:
            case TUNE_2_VEE_HOPB:
                state = STATE_VEE2;
                veeSent = 0;
                post slaveFindVee();
                break;
            case TUNE_VEE_HOP:
                state = STATE_VEE1;
                veeSent = 0;
                post slaveFindVee();
                break;
            case FREQ_HOP:
            case EXACT_FREQS:
                state = STATE_DATA_SENDING;
                signal RipsPhaseOffset.reportPhaseOffsets(call RSSILogger.getBufferStart(), call RSSILogger.getLength());
                break;
        }
    }

    event void RSSILogger.reportDone()
    {
        state = STATE_READY;
    }

    struct LogMsg{
        uint16_t nodeID;
    };  
    TOS_Msg msg;
    
    void task assistLogGoRequest(){
        ((struct LogMsg *)(msg.data))->nodeID = TOS_LOCAL_ADDRESS;
        if (!call LogQuerySend.send(TOS_BCAST_ADDR, sizeof(struct LogMsg), &msg))
            call Leds.yellowToggle();
    }

    event result_t LogQuerySend.sendDone(TOS_MsgPtr p, result_t success){
        if (p != &msg)
            return SUCCESS;
        call Leds.greenToggle();

        return SUCCESS;
    }

    event TOS_MsgPtr LogQueryRcv.receive(TOS_MsgPtr msgp){
        uint16_t nodeID = ((struct LogMsg *)(msgp->data))->nodeID;
        call Leds.redToggle();
        if (state >= STATE_DATA_SENDING  && nodeID == TOS_LOCAL_ADDRESS){
            state = STATE_DATA_SENDING-1;
            call RSSILogger.report();
        }
        
        if (nodeID == 0){
            //DBG - ping msg
            if (!post assistLogGoRequest()){
                state = STATE_READY;
                call RSSILogger.reset();
            }
        }

        return msgp;
    }       

    /**************             MASTER & SLAVE          ******************/
    task void restartTimer(){
        if(!call Timer.start(TIMER_ONE_SHOT, 50))
            signal RipsPhaseOffset.measurementEnded(FAIL);
    }
    
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr pmsg)
    {
        struct TuneDataMsg *tuneData = (struct TuneDataMsg*)(pmsg->data);
        //remove the last logger check, if you want to store more vees in the buffer and take e.g. median as the tuning value
        if ( (state == STATE_TUNING_DATA1 || state == STATE_TUNING_DATA2)
             && (tuneData->sup1>=SUPPORT_LIMIT) && (tuneData->sup2>=SUPPORT_LIMIT)
             && measurementSetup->masterID == TOS_LOCAL_ADDRESS 
             && call RSSILogger.getLength() == 0){
            call RSSILogger.record16(tuneData->vee1);
            call RSSILogger.record16(tuneData->vee2);
            call Timer.stop();
            if (!post restartTimer())
                signal RipsPhaseOffset.measurementEnded(FAIL);
        }
        else
        //the receivers shouldn't send messages, if one was already sent...
            veeSent = 1;

        return pmsg;
    }

    async event void RipsDataCollection.collectionEnded(result_t success)
    {
        if (success == FAIL){
            call RSSILogger.reset();
            if (measurementSetup->masterID == TOS_LOCAL_ADDRESS)
                signal RipsPhaseOffset.measurementEnded(FAIL);
            state = STATE_READY;
            return;
        }

        if (measurementSetup->masterID == TOS_LOCAL_ADDRESS){
            if (!post masterCollEnded()){
                signal RipsPhaseOffset.measurementEnded(FAIL);
                state = STATE_READY;
            }
        }
        else if (measurementSetup->assistantID != TOS_LOCAL_ADDRESS)
            post slaveCollEnded();
    }

    command result_t StdControl.init()
    {
        call SubControl.init();
        measurementSetup = call RipsDataStore.getMeasurementSetup();
        return SUCCESS;
    }

    command result_t StdControl.start()
    {
        call SubControl.start();
        state = STATE_READY;
        
        return SUCCESS;
    }

    command result_t StdControl.stop()
    {
        call SubControl.stop();
        call RSSILogger.reset();
        state = STATE_STOPPED;

        return SUCCESS;
    }
}

