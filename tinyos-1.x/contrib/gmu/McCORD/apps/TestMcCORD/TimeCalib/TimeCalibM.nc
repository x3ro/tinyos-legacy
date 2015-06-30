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

module TimeCalibM {
    provides interface StdControl;
    uses {
        interface Leds;
        interface StdControl as CommControl;
        interface SendMsg as SendTimeCalibMsg;
        interface SystemTime;
        interface StdControl as TimerControl;
        interface Timer;
    }
}

implementation {

    typedef struct {
        uint32_t currentTime; // in ticks.
    } __attribute__((packed)) TimeCalibMsg;

    TOS_Msg _msgBuf;

    task void sendTimeCalibMsg() {
        TimeCalibMsg * pTimeCalibMsg = (TimeCalibMsg *)(_msgBuf.data);

        pTimeCalibMsg->currentTime = call SystemTime.getCurrentTimeTicks();
        call SendTimeCalibMsg.send(TOS_BCAST_ADDR, sizeof(TimeCalibMsg),
            &_msgBuf);
    }

    command result_t StdControl.init() {
        call Leds.init();
        call TimerControl.init();
        call CommControl.init();
        return SUCCESS;
    }


    command result_t StdControl.start() {
        call TimerControl.start();
        call CommControl.start();
        call Leds.redOn();
        call Timer.start(TIMER_REPEAT, 1024);
        return SUCCESS;
    }  

    command result_t StdControl.stop() {
        call Timer.stop();
        call Leds.set(0);
        call CommControl.stop();
        call TimerControl.stop();
        return SUCCESS;
    }

    event result_t Timer.fired() {
        post sendTimeCalibMsg();
        return SUCCESS;
    }

    event result_t SendTimeCalibMsg.sendDone(TOS_MsgPtr msg, result_t success) {
        call Leds.greenToggle();
        return SUCCESS;
    }

}
