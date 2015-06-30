/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2006/03/22 11:56:31 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
includes crc;

module MarshallerM {
    provides {
        interface StdControl;
        interface MarshallerControl;
        interface GenericMsgComm;
        interface PacketRx as UpPacketRx;
    }
    uses {
        interface ByteComm;
        interface PacketTx;
        interface PacketRx as DownPacketRx;
        interface TimerJiffy as PacketTimer;
        interface LocalTime;
    }
}
implementation
{
    /**************** Module Definitions  *****************/
    typedef enum {
        FRAME_IDLE,
        TX_DATA,
        TX_CRC1,
        TX_CRC2,
        TX_DONE,
        RX_HEADER,
        RX_DATA,
        RX_CRC1,
        RX_CRC2
    } frameState_t;

#define MARGIN_BYTES 2 // 2 CRC
// #define MARSHALLER_DEBUG     

    /**************** Module Global Variables  *****************/
    uint8_t *msgBufPtr;  // pointer to message buffer
    frameState_t frameState;
    uint8_t byteCnt;
    uint8_t msgLength;
    uint16_t crc;           //CRC value of either the current incoming or outgoing packet
    bool timerDirty;
    
    /*************** settable constants ***********************/
    uint8_t maxLength;      //Maximum allowable length of a packet
    uint8_t header_size;    //Size of the header for the message to be sent
    uint8_t length_offset;  //Offset of the length field in the tx and Rx buffers
    uint16_t numPreambles;  //Number of preambles to send before the packet
    uint16_t byteDuration;   // duration of one byte on the channel in jiffies

    uint16_t time_us_offset; // in TOS_Msg
    bool packetInit;
   
    /**************** Local Function Declarations  *****************/
    void transmitByte();
    void receiveByte(uint8_t data);

    void signalFailure() {
#ifdef MARSHALLER_DEBUG
        atomic {
            for(;;) { ;}
        }
#endif
    }

    /**************** tasks  *****************/
    void recvFailed() {
        uint8_t *b;
        b = msgBufPtr;
        msgBufPtr = NULL;
        frameState = FRAME_IDLE;
        signal GenericMsgComm.recvDone(b, FALSE);
    }

    task void ClearDirtyTask() {
        atomic timerDirty = FALSE;
    }

    task void StopPacketTimerTask() { 
        call PacketTimer.stop();
        post ClearDirtyTask();
    }
    
    void stopPacketTimer() {
        timerDirty = TRUE;
        post StopPacketTimerTask();
    }
    
    task void StartPacketTimerTask() {
        int32_t timeOut = 0;
        frameState_t f;
        uint8_t length;
        uint16_t bD;
        
        atomic {
            f = frameState;
            bD = byteDuration;
        }
        if(f == RX_DATA) {
            atomic length = msgLength - byteCnt + MARGIN_BYTES;
            timeOut = bD * length;
        }
        else if(f > RX_DATA) {
            timeOut = bD * MARGIN_BYTES;
        }
        if(timeOut) call PacketTimer.setOneShot(timeOut);
    }
    
    /**************** Radio Init  *****************/
    command result_t StdControl.init(){
        atomic {
            frameState = FRAME_IDLE;
            msgBufPtr = NULL;
            byteCnt = 0;
            msgLength = 0;
            crc = 0;
            timerDirty = FALSE;
            length_offset = 0; //Offset of the length field in a TinyOS message
            maxLength = 29;    //Maximum length of a TinyOS message
            numPreambles = 2;  
            header_size = 8;
            byteDuration =17; // assuming 19200 bits/s and 32768 tics/sec
            time_us_offset = offsetof(TOS_Msg, time_us);
            packetInit = FALSE;
        }     
        return SUCCESS;
    }

    /**************** Radio Start  *****************/
    command result_t StdControl.start(){
        return SUCCESS;
    }

    /**************** Radio Stop  *****************/
    command result_t StdControl.stop(){
        return SUCCESS;
    } 
   
    command void MarshallerControl.setProperties(uint8_t hs,
                                                 uint8_t lo,
                                                 uint16_t nP,
                                                 uint8_t ml,
                                                 uint8_t bD) {
        atomic {
            header_size = hs;
            length_offset = lo;
            numPreambles = nP;      
            maxLength = ml;
            byteDuration = bD;
        }
    }
   
    command void MarshallerControl.setHeaderSize(uint8_t hs) {
        atomic header_size = hs;     
    }   
   
    command void MarshallerControl.setNumPreambles(uint16_t nP) {
        atomic numPreambles = nP;     
    }
   
    command void MarshallerControl.setLengthOffset(uint8_t lo) {
        atomic length_offset = lo;
    }
   
    command void MarshallerControl.setMaxLength(uint8_t ml) {
        atomic maxLength = ml;
    }   
   
    command void MarshallerControl.setByteDuration(uint8_t bD) {
        atomic byteDuration = bD;
    }

    /**************** Radio Send ****************/
    async command result_t GenericMsgComm.sendNext(uint8_t *msgPtr) {
        result_t res = FAIL;
        atomic {
            if((frameState == FRAME_IDLE) && (msgBufPtr == NULL)) {
                frameState = TX_DATA;
                msgBufPtr = msgPtr;
                packetInit = TRUE;
                crc = 0;
                byteCnt = 0;
                msgLength = msgPtr[length_offset] + header_size;
                res = call PacketTx.start(numPreambles);
                if(res == FAIL) {
                    frameState = FRAME_IDLE;
                    msgBufPtr = NULL;
                }
            } else {
                signalFailure();
            }
        }
        return res;
    }

    /**************** Radio Recv ****************/
    async command result_t GenericMsgComm.recvNext(uint8_t* msgPtr) {
        result_t res = FAIL;
        atomic {
            if((frameState == FRAME_IDLE) && (msgBufPtr == NULL)) {
                frameState = RX_HEADER;
                msgBufPtr = msgPtr;
                packetInit = TRUE;
                crc = 0;
                byteCnt = 0;
                msgPtr[length_offset] = 0;
                msgLength = header_size;
            }
            res = SUCCESS;
        }
        return res;
    }

    /**************** Tx Done ****************/
    async event result_t ByteComm.txByteReady(bool success) {
        transmitByte();
        return SUCCESS;
    }
   
    /**************** Rx Done ****************/
    async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
        receiveByte(data);
        return SUCCESS;
    }
   
    /**************** Rx Done ****************/
    async event result_t ByteComm.txDone() {
        return SUCCESS;
    }   
  
    /**************** TX/RX  *****************/
    /******** PacketRX ***********************/
    async event void DownPacketRx.detected() {
        signal UpPacketRx.detected();
    }

    async command result_t UpPacketRx.reset() {
        stopPacketTimer();
        atomic {
            if((frameState >= RX_HEADER) && (msgBufPtr != NULL)) {
                frameState = FRAME_IDLE;
                msgBufPtr = 0;
            }
#ifdef MARSHALLER_DEBUG     
            else if((frameState == FRAME_IDLE) && (msgBufPtr == NULL)) {
                
            } else {
                signalFailure();
            }
#endif
        }
        return call DownPacketRx.reset();
    }
    
    async event result_t PacketTx.done() {
        uint8_t* buf;
        atomic buf = msgBufPtr;
        signal GenericMsgComm.sendDone(buf, SUCCESS);
        atomic {
            frameState = FRAME_IDLE;
            msgBufPtr = NULL;
            crc = 0;
        }
        return SUCCESS;
    }

    /* Receive the next Byte from the USART */
    void receiveByte(uint8_t data) {
        uint8_t *b;
        atomic {
            if((frameState > FRAME_IDLE) && (frameState < RX_HEADER)) signalFailure();
            if((frameState != FRAME_IDLE) && (msgBufPtr == NULL)) signalFailure();
            
            switch(frameState) {
                case RX_DATA:
                    if (packetInit){
                      msgBufPtr[time_us_offset] = call LocalTime.read();
                      packetInit = FALSE;
                    }
                    crc = crcByte(crc, data);
                    if(byteCnt == (msgLength-1)) {
                        frameState = RX_CRC1;
                    }
                    msgBufPtr[byteCnt++] = data;
                    break;
                case RX_HEADER:
                    crc = crcByte(crc, data);
                    if((byteCnt == length_offset) && (data <= maxLength))
                    {
                        post StartPacketTimerTask();
                        if(data > 0) {
                            frameState = RX_DATA;
                        } else {
                            frameState = RX_CRC1;
                        }
                        msgLength += data;
                        msgBufPtr[byteCnt++] = data;    
                    } else {
                        recvFailed();
                    }
                    break;
                case RX_CRC1:
                    if (data == (uint8_t)(crc >> 8)) {
                        frameState = RX_CRC2;
                    } else {
                        stopPacketTimer();
                        recvFailed();
                    }
                    break;
                case RX_CRC2:
                    frameState = FRAME_IDLE;
                    stopPacketTimer();
                    if(data == (uint8_t)(crc)) {
                        b = msgBufPtr;
                        msgBufPtr = NULL;
                        signal GenericMsgComm.recvDone(b, TRUE);
                    } else {
                        recvFailed();
                    }
                    break;
                case FRAME_IDLE:
                    break;
                default:
                    signalFailure();
                    break;
            }
        }
    }

    void transmitByte() {
        int action = 0;
        uint8_t nextTxByte = 0;      // Next byte to be transmitted
        atomic {
            if(frameState == FRAME_IDLE) signalFailure();
            if(frameState >= RX_HEADER) signalFailure();
            if(msgBufPtr == NULL) signalFailure();

            switch(frameState) {
                case TX_DATA:
                    if (byteCnt == msgLength - 1) {
                        frameState = TX_CRC1;
                    }
                    nextTxByte = msgBufPtr[byteCnt++];
                    crc = crcByte(crc, nextTxByte);
                    action = 1;
                    break;
                case TX_CRC1:
                    nextTxByte = (uint8_t)(crc >> 8);
                    frameState = TX_CRC2;
                    action = 1;
                    break;
                case TX_CRC2:
                    nextTxByte = (uint8_t)(crc);
                    frameState = TX_DONE;
                    action = 1;
                    break;
                case TX_DONE:
                    frameState = FRAME_IDLE;
                    action = 2;
                    break;
                default:
                    break;
            }
        }
        if(action == 1) {
           if (packetInit){
             msgBufPtr[time_us_offset] = call LocalTime.read();
             packetInit = FALSE;
           }
           call ByteComm.txByte(nextTxByte);
        } else if(action == 2) {
            if(call PacketTx.stop() == FAIL) signalFailure();
        }
    }

    /***************** timer events *******************/
    event result_t PacketTimer.fired()  {
        atomic {
            if(timerDirty == TRUE) {
                timerDirty = FALSE;
            } else if(frameState > RX_HEADER) {
                recvFailed();
            }
        }
        return SUCCESS;
    }
}
