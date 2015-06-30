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

module TestAppM {
    provides interface StdControl;
    uses {
        interface ReceiveMsg as ReceiveTimeCalibMsg;
        interface SystemTime;
        interface McCORD;
        interface Leds;
    }
}

implementation {

    typedef struct {
        uint32_t currentTime; // in ticks.
    } __attribute__((packed)) TimeCalibMsg;

    bool _mccordInProgress = FALSE;

    command result_t StdControl.init() {
        return SUCCESS;
    }

    command result_t StdControl.start() {
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        return SUCCESS;
    }

    event TOS_MsgPtr ReceiveTimeCalibMsg.receive(TOS_MsgPtr pMsg) {
        if (_mccordInProgress) {
            return pMsg;
        } else {
            TimeCalibMsg * pTimeCalibMsg = (TimeCalibMsg *)(pMsg->data);
            call SystemTime.setCurrentTimeTicks(pTimeCalibMsg->currentTime);
            call Leds.greenOn();
            return pMsg;
        } 
    }

    event void McCORD.started() {
        _mccordInProgress = TRUE;
    }

    event void McCORD.done(result_t result) {
        _mccordInProgress = FALSE;
    }
}

