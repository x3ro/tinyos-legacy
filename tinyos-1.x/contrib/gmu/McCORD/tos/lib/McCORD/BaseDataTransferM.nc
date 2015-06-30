/**
 * Copyright (c) 2008 - George Mason University
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

module BaseDataTransferM {
    provides interface DataTransfer;
    uses {
        interface DataManagement;
        interface MsgBuf;
        interface ReceiveMsg as ReceiveMetaMsg;
        interface SendMsg as SendMetaMsg;
        interface ReceiveMsg as ReceiveDataMsg;
        interface SendMsg as SendDataMsg;
        interface Leds;
    }
}

implementation {
    enum {
        S_DISABLED,
        S_ENABLED,
    };

    uint8_t _state = S_DISABLED;

    command result_t DataTransfer.start() {
        _state = S_ENABLED;
        return SUCCESS;
    }

    event void DataManagement.initDone(result_t success) {}

    event void DataManagement.setObjMetadataDone() {
        TOS_MsgPtr msgBuf;
        UARTMetaMsg * pUARTMetaMsg;

        msgBuf = call MsgBuf.getMsgBuf();
        if (msgBuf != NULL) {
            pUARTMetaMsg = (UARTMetaMsg *)(msgBuf->data);
            call DataManagement.getObjMetadata(&(pUARTMetaMsg->metadata));
            if (call SendMetaMsg.send(TOS_UART_ADDR, 
                sizeof(UARTMetaMsg), msgBuf) == FAIL) {
                call MsgBuf.putMsgBuf(msgBuf);
            }
        }     
    }

    event void DataManagement.readPktDone(result_t success) {}

    event void DataManagement.newObjComplete() {
        if (_state == S_DISABLED) return;

        // Base received complete new object.
        __receiveAll(TRUE);

        _state = S_DISABLED;
        signal DataTransfer.done(SUCCESS);
    }

    event TOS_MsgPtr ReceiveMetaMsg.receive(TOS_MsgPtr pMsg) {
        UARTMetaMsg * pUARTMetaMsg = (UARTMetaMsg *)(pMsg->data);

        if (_state == S_DISABLED) return pMsg;

        call DataManagement.setObjMetadata(&(pUARTMetaMsg->metadata));

        return pMsg;
    }

    event TOS_MsgPtr ReceiveDataMsg.receive(TOS_MsgPtr pMsg) {
        UARTDataMsg * pUARTDataMsg = (UARTDataMsg *)(pMsg->data);
        TOS_MsgPtr msgBuf;

        if (_state == S_DISABLED) return pMsg;

        if (call DataManagement.writePkt(
            pUARTDataMsg->page, pUARTDataMsg->packet, pUARTDataMsg->data)
            == SUCCESS) {
            // Respond only after successfully written.
            msgBuf = call MsgBuf.getMsgBuf();
            if (msgBuf != NULL) {
                memcpy(msgBuf->data, pMsg->data, sizeof(UARTDataMsg));
                if (call SendDataMsg.send(TOS_UART_ADDR,
                    sizeof(UARTDataMsg), msgBuf) == FAIL) {
                    call MsgBuf.putMsgBuf(msgBuf);
                }
            }
        }
        return pMsg;
    }

    event result_t SendMetaMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }
    
    event result_t SendDataMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        call MsgBuf.putMsgBuf(pMsg);
        return SUCCESS;
    }
}
