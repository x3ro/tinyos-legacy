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
 * @author Miklos Maroti, miklos.maroti@vanderbilt.edu
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @author Peter Volgyesi, peter.volgyesi@vanderbilt.edu
 * @modified 04/11/05
 */
/*
   RSSI Engine with multihop sync
   Modified by Peter Volgyesi
 */
 

includes Reset;
includes SysTime;
includes SysAlarm;
includes AM;
includes RSSIEngine;

module RSSIEngineM
{
    provides interface RSSIEngine;

    uses
    {
        interface RSSIDriver;
        interface SysTime;
        interface SysAlarm;
        interface TimeStamping;
        interface ReceiveMsg as ReceiveMsgMH;
        interface SendMsg as SendMsgMH;
        interface ADC;
        interface Leds;
    }
}

implementation
{

    norace uint32_t time;

    norace TOS_Msg syncMsg;
#define tsHeader ((struct TSHeader *)(&syncMsg.data[tail]))

    enum
    {
        STATE_NONE = 0,

        STATE_WAIT = 5,
        STATE_TRANSMIT_BLOCK = 10,
        STATE_SUSPEND_BLOCK = 20,
        STATE_RSSI_BLOCK = 30,
        STATE_RECORD_BLOCK = 40,
        STATE_RIPS_BLOCK = 60,

        STATE_ACQUIRE = 200,
        STATE_RESTORE = 210,
        STATE_CALIBRATE_TRANSMIT = 220,
        STATE_CALIBRATE_RECEIVE = 230,
        STATE_ERROR = 240,
    };
    
    norace uint8_t radioState = STATE_NONE;

    norace uint16_t sampleCount;
    norace uint8_t sampleState = STATE_NONE;
    task void taskStep();

#define CHECK_TASK(XXX) { if( !(XXX) ) { call Leds.set(1); radioState = STATE_ERROR; signal RSSIEngine.done(CRASHED);} }
#define CHECK(XXX) { \
        if( !(XXX) ){ \
          radioState = STATE_ERROR; \
          CHECK_TASK(post taskStep()); \
          return; \
        } \
    }

    //MULTI HOP SYNCHRO

    norace uint8_t TSnumHops = 0;
    task void sendSyncMH()
    {
        // WHY IS THIS TASK NECESSARY? receive() is not using it any more
        int8_t tail = syncMsg.length;
        atomic time = call SysTime.getTime32() + RSSIENGINE_SYNC_MH_TIME;

        tsHeader->deadlineTS = time;                         // Timesync deadline (in sender's local time)
        tsHeader->timeStamp = 0;
        tsHeader->sender = (uint8_t)TOS_LOCAL_ADDRESS;
        atomic{
            if (TSnumHops>0)
                tsHeader->hopsToDo = --TSnumHops;
        }
        if( call SendMsgMH.send(TOS_BCAST_ADDR, SYNC_MH_MSG_HEADER+tail, &syncMsg))
            call TimeStamping.addStamp2(&syncMsg, tail+4);
        else{
            signal RSSIEngine.done(FAIL);
            return;
        }
        
        call RSSIEngine.wait(0);
    }
    async command void RSSIEngine.sendSyncMH(void *data, uint8_t length, uint8_t numHops)
    {
        CHECK(radioState == STATE_NONE);
        CHECK( length + SYNC_MH_MSG_HEADER <= DATA_LENGTH );

        memcpy( syncMsg.data, data, length);
        syncMsg.length = length;
        TSnumHops = numHops;
        
        CHECK_TASK(post sendSyncMH());
    }
    event result_t SendMsgMH.sendDone(TOS_MsgPtr p, result_t success)
    {
        return SUCCESS;
    }
    event TOS_MsgPtr ReceiveMsgMH.receive(TOS_MsgPtr msg)
    {
        int8_t tail = msg->length - SYNC_MH_MSG_HEADER;
        struct TSHeader *msgTSHeader = ((struct TSHeader *)(&msg->data[tail]));
        uint32_t delta = msgTSHeader->deadlineTS - msgTSHeader->timeStamp;
        uint8_t numHops = msgTSHeader->hopsToDo;
                
        if (!signal RSSIEngine.receiveSync(msgTSHeader->sender,&msg->data[0], tail))
            return msg;

        // if state is wrong, or timestamping didn't update the timestamp, or the timestamp is messed up, then this is a faulty msg
        if (radioState != STATE_NONE || msgTSHeader->timeStamp == 0 || RSSIENGINE_SYNC_MH_TIME < delta)
            return msg;
            
        memcpy( syncMsg.data, msg->data, msg->length);
        syncMsg.length = msg->length;

        // WHAT IF MULTIPLE msgs come? is wait(0) handling this correctly? --> they WON"T come, wait(0) changes radioState to STATE_WAIT
        atomic time = call TimeStamping.getStamp2(msg) + delta;
        call RSSIEngine.wait(0);

        if (delta > RSSIENGINE_SYNC_MH_SILENCE_TIME  && numHops > 0){
   
            atomic tsHeader->deadlineTS = time;                         // Timesync deadline (in sender's local time)
            tsHeader->timeStamp = 0;            // Sender timestamp 
            tsHeader->sender = (uint8_t)TOS_LOCAL_ADDRESS;
            tsHeader->hopsToDo = numHops-1;
    
            if( call SendMsgMH.send(TOS_BCAST_ADDR, SYNC_MH_MSG_HEADER+tail, &syncMsg) )
                call TimeStamping.addStamp2(&syncMsg, tail+4);
            else
                return msg;
        }
        
        return msg;
    }
    
    inline async command int32_t RSSIEngine.getElapsedTime()
    {
        uint32_t ret = 0;
        atomic ret = call SysTime.getTime32() - time;
        return ret;
    }

    inline async command void RSSIEngine.resetElapsedTime()
    {
        atomic time = call SysTime.getTime32();
    }

    norace int8_t radioChannel;
    norace uint8_t transmitStrength;
    norace int16_t transmitTuning;

    norace uint8_t *sampleBuffer;
//    norace uint16_t sampleCount;
//    norace uint8_t sampleState = STATE_NONE;

    norace uint16_t movingAvgA;     // with 3/4 decay
    norace uint16_t movingAvgB;     // with 15/16 decay
    norace int8_t movingSign;
    norace uint8_t prevCrossing;
    norace uint8_t minPeriod;
    norace uint8_t maxPeriod;
    norace uint8_t crossingCount;
    norace uint8_t periodSum;       // assuming that SAMPLE_COUNT <= 256
    norace uint16_t indexSum;
    
//<------------------------------------------ RIPS_MARKER_BEGIN

    enum 
    {
        MAX_PEAK_NUM    =   48,
        RIPS_LEN      = 24,
        MOVA_LEN            = 5,
        LOW_THRESH      = 102,                      // Low threshold = LOW_THRESH/256
        HIGH_THRESH     = 102,                      // High threshold = HIGH_THRESH/256
        PERIOD_THRESH   = 1,                        // Period threshold(alpha) = 1/2^PERIOD_THRESH
        SAMPLING_FREQ   = 8903,                 // Sampling frequency in Hertz
        SCALED_HALF_POINT    = 0x7fff,
    };
    norace uint16_t peakBuffer[MAX_PEAK_NUM];
    norace uint8_t peakIdx;
    norace uint16_t movaBuffer[MOVA_LEN];
    norace uint8_t movaIdx;
    norace uint16_t peakBegin;
    norace uint8_t foundHigh;
    norace uint8_t foundLow;
    norace uint16_t minSample;
    norace uint16_t maxSample;
//<------------------------------------------ RIPS_MARKER_END

    task void taskStep()
    {
        switch( radioState )
        {
        case STATE_NONE:
            break;

        case STATE_ACQUIRE:
            CHECK( call RSSIDriver.acquire() );
            time += RSSIENGINE_ACQUIRE_TIME;
            radioState = STATE_NONE;

            break;

        case STATE_RESTORE:
            CHECK( call RSSIDriver.restore() );
            time += RSSIENGINE_RESTORE_TIME;
            radioState = STATE_NONE;
            break;
        
        case STATE_CALIBRATE_TRANSMIT:
            CHECK( call RSSIDriver.calibrateTransmit(radioChannel) );
            time += RSSIENGINE_CALIBRATE_TIME;
            radioState = STATE_NONE;
            break;

        case STATE_CALIBRATE_RECEIVE:
            CHECK( call RSSIDriver.calibrateReceive(radioChannel) );
            time += RSSIENGINE_CALIBRATE_TIME;
            radioState = STATE_NONE;
            break;

        case STATE_ERROR:
    		if (!call RSSIDriver.restore()){
        	    //resetMote();
                call Leds.set(2);
                signal RSSIEngine.done(CRASHED);
                return;
            }
            radioState = STATE_NONE;
            sampleState = STATE_NONE;
            
            signal RSSIEngine.done(FAIL);
            
            return;

        default:
            CHECK(FAIL);
        }

        signal RSSIEngine.done(SUCCESS);
    }

    void asyncStep()
    {
        switch( radioState )
        {
        case STATE_NONE:
            break;

        case STATE_WAIT:
            radioState = STATE_NONE;
            break;

        case STATE_TRANSMIT_BLOCK:
            CHECK( call RSSIDriver.transmit(transmitStrength, transmitTuning) );
            time += (uint32_t)RSSIENGINE_LOCK_TIME + (uint32_t)RSSIENGINE_SAMPLE_COUNT*RSSIDRIVER_SAMPLE_TIME + (uint32_t)RSSIENGINE_TAIL_TIME;
            CHECK( call SysAlarm.set(SYSALARM_ABSOLUTE, time) );
            radioState = STATE_NONE;
            return;

        case STATE_SUSPEND_BLOCK:
            CHECK( call RSSIDriver.suspend() );
            time += (uint32_t)RSSIENGINE_LOCK_TIME + (uint32_t)RSSIENGINE_SAMPLE_COUNT*RSSIDRIVER_SAMPLE_TIME + (uint32_t)RSSIENGINE_TAIL_TIME;
            CHECK( call SysAlarm.set(SYSALARM_ABSOLUTE, time) );
            radioState = STATE_NONE;
            return;

        case STATE_RSSI_BLOCK:
            CHECK( sampleState == STATE_NONE );
            *(uint16_t*)sampleBuffer = 0;
        case STATE_RECORD_BLOCK:
        case STATE_RIPS_BLOCK:
            CHECK( sampleState == STATE_NONE );
            
            sampleState = radioState;
            CHECK( call RSSIDriver.receive() );

            time += RSSIENGINE_LOCK_TIME;
            CHECK( call SysAlarm.set(SYSALARM_ABSOLUTE, time) );
            radioState += 1;
            return;
        
        case STATE_RSSI_BLOCK+1:
        case STATE_RECORD_BLOCK+1:
        case STATE_RIPS_BLOCK+1:
            sampleCount = RSSIENGINE_SAMPLE_COUNT;
            time += (uint32_t)RSSIENGINE_SAMPLE_COUNT*RSSIDRIVER_SAMPLE_TIME + (uint32_t)RSSIENGINE_TAIL_TIME;
            CHECK( call ADC.getContinuousData() );
            CHECK( call SysAlarm.set(SYSALARM_ABSOLUTE, time) );
            radioState += 1;
            return;

        case STATE_RSSI_BLOCK+2:
        case STATE_RECORD_BLOCK+2:
        case STATE_RIPS_BLOCK+2:
            CHECK( sampleState == STATE_NONE );
            radioState = STATE_NONE;
            break;

        case STATE_ACQUIRE:
        case STATE_RESTORE:
        case STATE_CALIBRATE_TRANSMIT:
        case STATE_CALIBRATE_RECEIVE:
            CHECK_TASK(post taskStep());
            return;

        default:
            CHECK(FAIL);
        }

        signal RSSIEngine.done(SUCCESS);
    }

    inline async event void SysAlarm.fired()
    {
        asyncStep();
    }

    task void finalizeRips()  
    {
//<------------------------------------------ RIPS_MARKER_BEGIN

        // NOTE: this task should finish within RSSIENGINE_TAIL_TIME
        
        uint8_t i;
        uint16_t periodMin = 65535U;
        uint16_t periodThresh;
        uint16_t prevPeak;
        uint32_t periodAcc = 0;
        uint8_t periodNum = 0;
        uint16_t period;
        int16_t firstPhase = -1;
        int32_t phaseAcc = 0;
        uint8_t phaseNum = 0;
        uint16_t freq = 0;
        int16_t phase = 0;
        
        
        // Optional safety check
        //CHECK(sampleState == STATE_RIPS_BLOCK);
        
        // Calculate min period
        for( i = 1; i < peakIdx; i++ ) {
            uint16_t c_period = peakBuffer[i] - peakBuffer[i-1];
            periodMin = (periodMin < c_period) ? periodMin : c_period;
        }
        
        // Filter periods
        prevPeak = peakBuffer[0];
        periodThresh = (periodMin >> PERIOD_THRESH) + periodMin;
    
        for( i = 1; i < peakIdx; i++ ) {
            uint16_t c_period = peakBuffer[i] - prevPeak;
            prevPeak = peakBuffer[i];
            if( c_period < periodThresh ) {
                periodAcc += c_period;
                periodNum++;
            }
            else {
                // Suspicious peaks - remove them
                peakBuffer[i] = 0;
                peakBuffer[i-1] = 0;
            }
        }
        
        if (periodNum && periodAcc) {
            uint32_t tmp;
            period = periodAcc / periodNum;
            // freq = (SAMPLING_FREQ / period) * 16 * 256;
            tmp = SAMPLING_FREQ;
            tmp <<= 12;
            freq = (tmp / (uint32_t)period);
            
            // Phase calculation
            for( i = 0; i < peakIdx; i++ ) {
                int16_t diff;
                if( peakBuffer[i] == 0) {
                    continue;
                }
                diff = peakBuffer[i] - SCALED_HALF_POINT;
                // Modulo arithmetic for (small) real numbers
                while (diff > 0) {
                    diff -= period;
                }
                while (diff < 0) {
                    diff += period;
                }
                if( firstPhase < 0 ) {
                    firstPhase = diff;
                }
                else {  
                    // Distances from first phase (mod period)          
                    if( diff > firstPhase ) {
                        int16_t p1 = diff - firstPhase;
                        int16_t p2 = period - p1;
                        if( p1 > p2 ) {
                            phaseAcc -= p2;
                        }
                        else {
                            phaseAcc += p1;
                        }
                    }
                    else {
                        int16_t p1 = firstPhase - diff;
                        int16_t p2 = period - p1;
                        if( p1 > p2 ) {
                            phaseAcc += p2;
                        }
                        else {
                            phaseAcc -= p1;
                        }
                    }
                    
                    phaseNum++;
                }
            }
    
            if (!phaseNum) {
                phase = firstPhase;
            }
            else if (firstPhase > 0) {
                phase = (phaseAcc / phaseNum) + firstPhase;
            }
            else {
                phase = 0;
            }
            // Modulo arithmetic
            while (phase > 0) {
                    phase -= period;
            }
            while (phase < 0) {
                    phase += period;
            }
            
            // phase = (phase / period) * 256;
            tmp = phase;
            tmp <<= 8;
            tmp /= period;
            phase = (int16_t)tmp;
        }
        else {
            phase = 0;
            freq = 0;
        }
        
        *(sampleBuffer++) = maxSample - minSample;  // Hope, this fits in 8 bit
        *(sampleBuffer++) = (uint8_t)phase;
        *(uint16_t*)sampleBuffer = freq;
        sampleState = STATE_NONE;
//<------------------------------------------ RIPS_MARKER_END
    }
    
    async event result_t ADC.dataReady(uint16_t data)
    {
        uint16_t filtdsample = 0;
        
        data &= 0x3FF;

        if( sampleState == STATE_NONE || sampleState == STATE_ERROR)
            return FAIL;
            
        if( sampleCount-- == 0 )
        {
            sampleState = STATE_ERROR;
            return FAIL;
        }

        switch( sampleState )
        {
        case STATE_RSSI_BLOCK:
            if( sampleCount == RSSIENGINE_SAMPLE_COUNT - 1 )
                *(uint16_t*)sampleBuffer = data;
            else{
                uint32_t tmp = *(uint16_t*)sampleBuffer+data;
                *(uint16_t*)sampleBuffer = tmp>>1;
            }
            if( sampleCount == 0 )
                sampleState = STATE_NONE;
            break;

        case STATE_RECORD_BLOCK:
            *(sampleBuffer++) = (data >= 256 ? 255 : data);
            if( sampleCount == 0 )
                sampleState = STATE_NONE;
            break;

        case STATE_RIPS_BLOCK:
//<------------------------------------------ RIPS_MARKER_BEGIN
            
            // 0. sample - Initialization
            if( sampleCount == RSSIENGINE_SAMPLE_COUNT-1 )
            {
                maxSample = 0;
                minSample = 0xFFFF;
                movaIdx = 0;
                peakIdx = 0;
                foundHigh = 0;
                foundLow = 0;
                movaBuffer[movaIdx++] = data;
            }
            else
            {
                movaBuffer[movaIdx] = data;
                movaIdx = (movaIdx == MOVA_LEN - 1) ?  0 : movaIdx + 1;
                
                // From MOVA_LEN. sample - calculate averaged signal
                if( sampleCount <= RSSIENGINE_SAMPLE_COUNT-MOVA_LEN )
                {
                    // Moving average calculation
                    uint8_t i;
                    uint16_t sum = 0;//sum of 12-bit variables
                    for( i = 0; i < MOVA_LEN; i++ ) {
                        sum += movaBuffer[i];
                    }
                    filtdsample = sum / MOVA_LEN;
                    
                    // Calculate min/max for the first RIPS_LEN samples
                    if( sampleCount > RSSIENGINE_SAMPLE_COUNT-MOVA_LEN-RIPS_LEN ) {
                        minSample = (minSample < filtdsample) ? minSample : filtdsample;
                        maxSample = (maxSample > filtdsample) ? maxSample : filtdsample;
                    }
                }
                
                // From (MOVA_LEN+RIPS_LEN). sample - calculate thresholds and run peak detector
                if( sampleCount <= RSSIENGINE_SAMPLE_COUNT-MOVA_LEN-RIPS_LEN )
                {
                    // Calculate min and max and thresholds
                    uint16_t lowval;
                    uint16_t highval;
                    uint8_t ampl;
                    
                    ampl = (maxSample - minSample);
                    lowval = ((ampl * LOW_THRESH) >> 8) + minSample;
                    highval = maxSample - ((ampl * HIGH_THRESH) >> 8);
                
                    // Peak detector BEGIN
                    if( filtdsample > highval ) {
                        if ( foundLow ) {
                            peakBegin = RSSIENGINE_SAMPLE_COUNT - sampleCount;
                            foundLow = 0;
                            foundHigh = 1;
                        }
                    }
                    else {
                        if( foundHigh ) {
                            if (peakIdx < MAX_PEAK_NUM) {
                                peakBuffer[peakIdx++] = (((RSSIENGINE_SAMPLE_COUNT - sampleCount - 1 - peakBegin) + (peakBegin << 1)) << 7);
                            }
                        }
                        foundHigh = 0;
                    }
                    
                    if( filtdsample < lowval ) {
                        foundLow = 1;
                    }
                    // Peak detector END
                }
                
                if( sampleCount == 0 )
                {
                    CHECK_TASK(post finalizeRips());
                }
            }
//<------------------------------------------ RIPS_MARKER_END
            break;
        
        default:
            sampleState = STATE_ERROR;
            return FAIL;
        }

        return sampleCount > 0;
    }
    
    
    inline async command void RSSIEngine.wait(uint32_t delay)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_WAIT;
        time += delay;
        CHECK( call SysAlarm.set(SYSALARM_ABSOLUTE, time) );
    }

    inline async command void RSSIEngine.acquire()
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_ACQUIRE;
        CHECK_TASK(post taskStep());
    }

    inline async command void RSSIEngine.restore()
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_RESTORE;
        CHECK_TASK(post taskStep());
    }

    inline async command void RSSIEngine.calibrateTransmit(int8_t channel)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_CALIBRATE_TRANSMIT;
        radioChannel = channel;
        CHECK_TASK(post taskStep());
    }

    inline async command void RSSIEngine.calibrateReceive(int8_t channel)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_CALIBRATE_RECEIVE;
        radioChannel = channel;
        CHECK_TASK(post taskStep());
    }

    inline async command void RSSIEngine.transmitBlock(uint8_t strength, int16_t tuning)
    {
        CHECK( radioState == STATE_NONE );
        transmitStrength = strength;
        transmitTuning = tuning;
        radioState = STATE_TRANSMIT_BLOCK;
        asyncStep();
    }

    inline async command void RSSIEngine.suspendBlock()
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_SUSPEND_BLOCK;
        asyncStep();
    }

    inline async command void RSSIEngine.rssiBlock(uint8_t *sample)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_RSSI_BLOCK;
        sampleBuffer = sample;
        CHECK( sampleBuffer != 0 );
        asyncStep();
    }

    inline async command void RSSIEngine.recordBlock(uint8_t *buffer)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_RECORD_BLOCK;
        sampleBuffer = buffer;
        CHECK( sampleBuffer != 0 );
        asyncStep();
    }

    inline async command void RSSIEngine.ripsBlock(uint8_t *buffer)
    {
        CHECK( radioState == STATE_NONE );
        radioState = STATE_RIPS_BLOCK;
        sampleBuffer = buffer;
        CHECK( sampleBuffer != 0 );
        asyncStep();
    }
}
