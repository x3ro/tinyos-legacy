/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Test TDA5250 component
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module TestTDA5250M {
    provides {
        interface StdControl;
    }
    uses {
        interface TDA5250Config;
        interface TDA5250Modes;
        interface PacketRx;
        interface PacketTx;
        interface ByteComm;

        interface LedsNumbered as Leds;
        interface Random;
        interface RawDump;

        interface TimerMilli as TxModeTimer;
        interface TimerMilli as RxModeTimer;
        interface TimerMilli as CCAModeTimer;
        interface TimerMilli as SleepModeTimer;
        interface TimerMilli as TimerModeTimer;
        interface TimerMilli as SelfPollingModeTimer;
        interface TimerMilli as CommandTimer;         
    }
}
implementation
{
    typedef enum  {
        EMPTY_CMD,
        TDA5250MODES_SETTIMERMODE,
        TDA5250MODES_RESETTIMERMODE,
        TDA5250MODES_SETSELFPOLLINGMODE,
        TDA5250MODES_RESETSELFPOLLINGMODE,

        TDA5250MODES_RXMODE,   
        TDA5250MODES_SLEEPMODE,
        TDA5250MODES_CCAMODE,

        TDA5250CONFIG_RESET,
        TDA5250CONFIG_SETRFPOWER,
        TDA5250CONFIG_USELOWTXPOWER,
        TDA5250CONFIG_USEHIGHTXPOWER,
        TDA5250CONFIG_LOWLNAGAIN,
        TDA5250CONFIG_HIGHLNAGAIN,

        PACKETTX_START,
        PACKETTX_STOP,
        
        PACKETRX_RESET,
        PACKETRX_WAITINGFORSFD,
        BYTECOMM_TXBYTE,
    } radioCommands_t;

    typedef enum  {
        EMPTY_EVENT,

        TDA5250CONFIG_READY,

        TDA5250MODES_READY,
        TDA5250MODES_RXMODEDONE,
        TDA5250MODES_SLEEPMODEDONE,
        TDA5250MODES_CCAMODEDONE,
        TDA5250MODES_INTERRUPT,

        PACKETTX_DONE,
        PACKETRX_DETECTED,

        BYTECOMM_TXBYTEREADY,
        BYTECOMM_RXBYTEREADY,
        BYTECOMM_TXDONE,

        TXMODE_TIMER,
        RXMODE_TIMER,
        CCAMODE_TIMER,
        SLEEPMODE_TIMER,
        TIMERMODE_TIMER,
        SELFPOLLINGMODE_TIMER,
        COMMAND_TIMER,
    } radioEvents_t;

    typedef enum  {
        EMPTY_STATE,
        INIT,
        SW_RX,
        RX,
        SW_CCA,
        CCA,
        SW_TX,
        TX,
        SW_SLEEP,
        SLEEP,
        TIMER,
        SELF_POLLING
    } radioState_t;

    typedef struct {
        unsigned cnt;
        radioState_t radioState;
        radioCommands_t cmd;
        result_t res;
        radioEvents_t ev;
    } historyItem_t;

#define MAX_MODE_TIME 300
#define MAX_HISTORY_ENTRIES 100

    historyItem_t history[MAX_HISTORY_ENTRIES];
    unsigned historyIndex;
    radioCommands_t nextCmd;
    radioState_t radioState;
    uint8_t txByte;
    unsigned rxByteCnt;
    unsigned iCnt;
    bool isSetSp;
    bool isSetTimer;
    bool packetDetected;
    
/******** helper functions ***************/
    void addHistoryEntry(radioState_t rs, radioCommands_t cmd, result_t res, radioEvents_t ev) {
        bool dump = TRUE;
        if(res == SUCCESS) {
            atomic {
                if(historyIndex < MAX_HISTORY_ENTRIES) {
                    history[historyIndex].radioState = rs;
                    history[historyIndex].cmd = cmd;
                    history[historyIndex].res = res;
                    history[historyIndex].ev = ev;
                    ++historyIndex;
                } else {
                    dump = FALSE;
                }
            }
            if(dump) {
                if(call RawDump.dumpByte(0xFF) == FAIL) return;
                if(call RawDump.dumpByte(rs) == FAIL) return;
                if(call RawDump.dumpByte(cmd) == FAIL) return;
                if(call RawDump.dumpByte(res) == FAIL) return;
                if(call RawDump.dumpByte(ev) == FAIL) return;
            }
        }
    }

    void setLed() {
        radioState_t rs;
        call Leds.led0Off();
        call Leds.led1Off();
        call Leds.led2Off();
        call Leds.led3Off();
        atomic rs = radioState;
        switch(rs) {
            case RX:
            case CCA:
                // call Leds.led0On();
                break;
            case TX:
                // call Leds.led1On();
                break;
            case SLEEP:
            case TIMER:
                call Leds.led2On();
                break;
            case SELF_POLLING:
                call Leds.led3On();
                break;
            default: break;
        }
    }

    void executeRandomCommand(radioEvents_t re);
    
    /***************** stdcontrol ********************/
    command result_t StdControl.init()  {
        unsigned i;
        call Random.init();
        atomic {
            historyIndex = 0;
            nextCmd = EMPTY_CMD;
            radioState = EMPTY_STATE;
            txByte = 0;
            rxByteCnt = 0;
            iCnt = 0;
            isSetSp = FALSE;
            isSetTimer = FALSE;
            packetDetected = FALSE;
            for(i = 0; i < MAX_HISTORY_ENTRIES; i++) {
                history[i].cnt = i;
                history[i].radioState = EMPTY_STATE;
                history[i].cmd = EMPTY_CMD;
                history[i].res = SUCCESS;
                history[i].ev = EMPTY_EVENT;
            }
        }
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call TxModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call RxModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call CCAModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call SleepModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call TimerModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call SelfPollingModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        call CommandTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
        return call RawDump.init(0,TRUE);
    }
    
    command result_t StdControl.stop() {
        call TxModeTimer.stop();
        call RxModeTimer.stop();
        call CCAModeTimer.stop();
        call SleepModeTimer.stop();
        call TimerModeTimer.stop();
        call SelfPollingModeTimer.stop();
        call CommandTimer.stop();
        return SUCCESS;
    }

   /******************* PacketTx **********************/
   // async command result_t PacketTx.start(uint16_t numPreambles);
   // async command result_t PacketTx.stop();
    async event result_t PacketTx.done() {
        radioState_t rs;
        atomic {
            rs = radioState;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, PACKETTX_DONE);
        return SUCCESS;
    }

   /******************* PacketRx *********************/
    // async command result_t PacketRx.reset();
    // async command bool PacketRx.waitingForSFD();
    async event void PacketRx.detected() {
        radioState_t rs;
        atomic {
            rs = radioState;
            packetDetected = TRUE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, PACKETRX_DETECTED);
    }

    /***************** ByteComm **********************/
    // async command result_t ByteComm.txByte(uint8_t data);
    async event result_t ByteComm.txByteReady(bool success) {
        radioState_t rs;
        result_t res;
        uint8_t nB;
        atomic {
            rs = radioState;
            radioState = TX;
            nB = txByte;
            packetDetected = FALSE;
        }
        if(nB >= 9) {
            atomic txByte = 0;
            res = call PacketTx.stop();
            addHistoryEntry(rs, PACKETTX_STOP, res, BYTECOMM_TXBYTEREADY);
        } else {
            atomic {
                nB = txByte;
                 ++txByte;
            }
            res = call ByteComm.txByte(nB);
            if(nB == 0) {
                addHistoryEntry(rs, BYTECOMM_TXBYTE, res, BYTECOMM_TXBYTEREADY);
            } else {
                executeRandomCommand(BYTECOMM_TXBYTEREADY);
            }
        }
        call Leds.led1Toggle();
        return SUCCESS;
    }
    
    async event result_t ByteComm.rxByteReady(uint8_t data, bool error, uint16_t strength) {
        radioState_t rs;
        int cnt;
        atomic {
            historyIndex = 0;
            rs = radioState;
            cnt = rxByteCnt++;
            if(packetDetected == FALSE) for(;;) { ;}
        }
        if(cnt < 2) {
            addHistoryEntry(rs, EMPTY_CMD, SUCCESS, BYTECOMM_RXBYTEREADY);
        } else {
            executeRandomCommand(BYTECOMM_RXBYTEREADY);
        }
        call Leds.led0Toggle();
        return SUCCESS;
    }
    
    async event result_t ByteComm.txDone() {
        radioState_t rs;
        atomic {
            rs = radioState;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, BYTECOMM_TXDONE);
        return SUCCESS;
    }

    /***************** TDAModes commands + events */
    event result_t TDA5250Modes.ready() {
        radioState_t rs;
        atomic {
            rs = radioState;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250MODES_READY);
        atomic radioState = INIT;
        return SUCCESS;
    }

    // async command result_t TDA5250Modes.SetTimerMode(float on_time, float off_time);
    // async command result_t TDA5250Modes.ResetTimerMode();
    // async command result_t TDA5250Modes.SetSelfPollingMode(float on_time, float off_time);
    // async command result_t TDA5250Modes.ResetSelfPollingMode();
    
    // async command result_t TDA5250Modes.RxMode();
    // async command result_t TDA5250Modes.SleepMode(); 
    // async command result_t TDA5250Modes.CCAMode();  
    
    event result_t TDA5250Modes.RxModeDone() {
        radioState_t rs;
        atomic {
            rs = radioState;
            radioState = RX;
            rxByteCnt = 0;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250MODES_RXMODEDONE);
        return SUCCESS;
    }
    
    event result_t TDA5250Modes.SleepModeDone() {
        radioState_t rs;
        atomic {
            rs = radioState;
            radioState = SLEEP;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250MODES_SLEEPMODEDONE);
        setLed();
        return SUCCESS;
    }
    
    event result_t TDA5250Modes.CCAModeDone() {
        radioState_t rs;
        atomic {
            rs = radioState;
            radioState = CCA;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250MODES_CCAMODEDONE);
        setLed();
        return SUCCESS;
    }
    
    async event void TDA5250Modes.interrupt() {
        radioState_t rs;
        int c;
        atomic {
            rs = radioState;
            c = iCnt++;
            packetDetected = FALSE;
        }
        if(c == 0) {
            addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250MODES_INTERRUPT);
        } else {
            executeRandomCommand(TDA5250MODES_INTERRUPT);
        }
    }

    /**************** TDAConfig commands +  events *****************/
    // command result_t TDA5250Config.reset();   
    // command result_t TDA5250Config.SetRFPower(uint8_t value);   
    // command result_t TDA5250Config.UseLowTxPower();
    // command result_t TDA5250Config.UseHighTxPower();
    // command result_t TDA5250Config.LowLNAGain();
    // command result_t TDA5250Config.HighLNAGain();    

    event result_t TDA5250Config.ready() {
        radioState_t rs;
        atomic {
            rs = radioState;
            packetDetected = FALSE;
        }
        addHistoryEntry(rs, EMPTY_CMD, SUCCESS, TDA5250CONFIG_READY);
        atomic radioState = INIT;
        return SUCCESS;
    }
    
    /**************** Timers *************************************/
    event result_t TxModeTimer.fired() {
        radioState_t rs;
        result_t res;
        atomic rs = radioState;
        res = call PacketTx.start(50);
        addHistoryEntry(rs, PACKETTX_START, res, TXMODE_TIMER);
        if(res == SUCCESS) atomic radioState = SW_TX;
        return call TxModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }

    event result_t RxModeTimer.fired()  {
        radioState_t rs;
        result_t res;
        atomic rs = radioState;
        res = call TDA5250Modes.RxMode();        
        addHistoryEntry(rs, TDA5250MODES_RXMODE, res, RXMODE_TIMER);
        if(res == SUCCESS) atomic radioState = SW_RX;
        return call RxModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }

    event result_t CCAModeTimer.fired() {
        radioState_t rs;
        result_t res;
        atomic rs = radioState;
        res = call TDA5250Modes.CCAMode();        
        addHistoryEntry(rs, TDA5250MODES_CCAMODE, res, CCAMODE_TIMER);
        if(res == SUCCESS) atomic radioState = SW_CCA;
        return call CCAModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }
    
    event result_t SleepModeTimer.fired() {
        radioState_t rs;
        result_t res;
        atomic rs = radioState;
        res = call TDA5250Modes.SleepMode();        
        addHistoryEntry(rs, TDA5250MODES_SLEEPMODE, res, SLEEPMODE_TIMER);
        if(res == SUCCESS) atomic radioState = SW_SLEEP;
        return call SleepModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }
    
    event result_t TimerModeTimer.fired() {
        radioState_t rs;
        result_t res;
        bool init;
        atomic {
            rs = radioState;
            init = isSetTimer;
        }
        if(init) {
            res = call TDA5250Modes.ResetTimerMode();
            addHistoryEntry(rs, TDA5250MODES_RESETTIMERMODE, res, TIMERMODE_TIMER);
        } else {
            res = call TDA5250Modes.SetTimerMode(10.0, 8.0);
            addHistoryEntry(rs, TDA5250MODES_SETTIMERMODE, res, TIMERMODE_TIMER);
            atomic isSetTimer = TRUE;
        }
        if(res == SUCCESS) atomic {
            radioState = TIMER;
            iCnt = 0;
        }
        setLed();
        return call TimerModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }
    
    event result_t SelfPollingModeTimer.fired() {
        radioState_t rs;
        result_t res;
        bool init;
        atomic {
            rs = radioState;
            init = isSetSp;
        }
        if(init) {
            res = call TDA5250Modes.ResetSelfPollingMode();
            addHistoryEntry(rs, TDA5250MODES_RESETSELFPOLLINGMODE, res, SELFPOLLINGMODE_TIMER);
        } else {
            res = call TDA5250Modes.SetSelfPollingMode(10.0, 8.0);
            addHistoryEntry(rs, TDA5250MODES_SETSELFPOLLINGMODE, res, SELFPOLLINGMODE_TIMER);
            atomic isSetSp = TRUE;
        }
        if(res == SUCCESS) atomic {
            radioState = SELF_POLLING;
            iCnt = 0;
        }
        setLed();
        return call SelfPollingModeTimer.setOneShot(call Random.rand() % MAX_MODE_TIME);
    }
    
    event result_t CommandTimer.fired() {
        call CommandTimer.setOneShot(call Random.rand() % 100);
        executeRandomCommand(COMMAND_TIMER);
        return SUCCESS;
    }

    void executeRandomCommand(radioEvents_t re) {
        result_t res;
        bool sp;
        bool ti;
        radioState_t rs;
        unsigned c = (call Random.rand() >> 8) & 0x0F;
        atomic {
            rs = radioState;
            sp = isSetSp;
            ti = isSetTimer;
        }
        switch(c) {
             case 0:
                 res = call PacketRx.reset();
                 addHistoryEntry(rs, PACKETRX_RESET, res, re);
                 break;
            case 1:
                res = call TDA5250Config.UseLowTxPower();
                addHistoryEntry(rs, TDA5250CONFIG_USELOWTXPOWER, res, re);
                break;
            case 2:
                res = call TDA5250Config.UseHighTxPower();
                addHistoryEntry(rs, TDA5250CONFIG_USEHIGHTXPOWER, res, re);
                break;
            case 3:
                if(sp) {
                    res = call TDA5250Modes.ResetSelfPollingMode();
                    addHistoryEntry(rs, TDA5250MODES_RESETSELFPOLLINGMODE, res, re);
                    if(res == SUCCESS) atomic {
                        radioState = SELF_POLLING;
                        iCnt = 0;
                    }
                    setLed();
                }
                break;
            case 4:
                res = call TDA5250Config.SetRFPower(c<<4);
                addHistoryEntry(rs, TDA5250CONFIG_SETRFPOWER, res, re);
                break;
            case 5:
                if(ti) {
                    res = call TDA5250Modes.ResetTimerMode();
                    addHistoryEntry(rs, TDA5250MODES_RESETTIMERMODE, res, re);
                    if(res == SUCCESS) atomic {
                        radioState = TIMER;
                        iCnt = 0;
                    }
                    setLed();
                }
                break;
            case 6:
                res = call TDA5250Modes.RxMode();        
                addHistoryEntry(rs, TDA5250MODES_RXMODE, res, re);
                if(res == SUCCESS) atomic radioState = SW_RX;
                break;
            case 7:
                res = call PacketTx.start(50);
                addHistoryEntry(rs, PACKETTX_START, res, re);
                if(res == SUCCESS) atomic radioState = SW_TX;
                break;
            case 8:
                res = call TDA5250Modes.CCAMode();        
                addHistoryEntry(rs, TDA5250MODES_CCAMODE, res, re);
                if(res == SUCCESS) atomic radioState = SW_CCA;
                break;
            case 9:
                res = call TDA5250Modes.SleepMode();        
                addHistoryEntry(rs, TDA5250MODES_SLEEPMODE, res, re);
                if(res == SUCCESS) atomic radioState = SW_SLEEP;
                break;
            case 10:
                addHistoryEntry(rs, EMPTY_CMD, SUCCESS, re);
                break;
            default:
                break;
        }
    }
}
