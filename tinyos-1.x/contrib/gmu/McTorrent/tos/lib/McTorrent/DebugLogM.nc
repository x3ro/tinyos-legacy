/**
 * Copyright (c) 2006 - George Mason University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL GEORGE MASON UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF GEORGE MASON
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *      
 * GEORGE MASON UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND GEORGE MASON UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 **/

/**
 * @author Leijun Huang <lhuang2@gmu.edu>
 **/

module DebugLogM {
    provides interface DebugLog;
    uses { 
        interface SystemTime;
        interface SendMsg as SendDebugMsg;
    }
}

implementation {
    typedef struct {
        uint32_t timestamp;
        uint8_t  dir;   // TX or RX
        uint8_t  type;  // Message type: ADV, REQ, CHANNEL or DATA
        uint16_t addr;  // Destination if TX, or source if RX
        uint8_t  channel;
        uint8_t  page;  // Complete pages if ADV, the page if other messages.
        uint8_t  packet;
    } DebugMsg;

    TOS_Msg _msg;

    command result_t DebugLog.writeLog(uint8_t dir,
                            uint8_t type,
                            uint16_t addr,
                            uint8_t channel,
                            uint8_t page,
                            uint8_t packet) {
        DebugMsg * pDebugMsg = (DebugMsg *)(_msg.data);
        pDebugMsg->timestamp = call SystemTime.getCurrentTimeMillis();
        pDebugMsg->dir = dir;
        pDebugMsg->type = type;
        pDebugMsg->addr = addr;
        pDebugMsg->channel = channel;
        pDebugMsg->page = page;
        pDebugMsg->packet = packet;

        call SendDebugMsg.send(TOS_UART_ADDR, sizeof(DebugMsg), &_msg);
        return SUCCESS;
    }

    event result_t SendDebugMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        return SUCCESS;
    }

} 
