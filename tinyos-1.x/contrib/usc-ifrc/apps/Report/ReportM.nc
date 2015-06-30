
/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/*
 * @author Phil Buonadonna
 * @author Gilman Tolle
 */

/*
 * "Copyright (c) 2000-2005 The Regents of the University of Southern California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Authors: Sumit Rangwala
 * Embedded Networks Laboratory, University of Southern California
 */

/*
 * @author Phil Buonadonna
 * @author Gilman Tolle
 * Revision:	$Id: ReportM.nc,v 1.1 2006/05/28 07:52:01 srangwal Exp $
 */
  
/* 
 *
 */

module ReportM {
    provides {
        interface StdControl;
        interface SendMsg as SendMsg[uint8_t id];
    }
    uses {
        interface StdControl as UARTControl;
        interface BareSendMsg as UARTSend;

        interface Leds;
    }
}

implementation
{

    bool uartBusy;

    command result_t StdControl.init() {
        uartBusy = FALSE;
        call UARTControl.init();
        call Leds.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call UARTControl.start();
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call UARTControl.stop();
        return SUCCESS;
    }

    command result_t SendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {
        if(uartBusy)
            return FAIL;
        else {
            uartBusy = TRUE;
            msg->length = length;
            msg->type   = id;
            msg->group   = TOS_AM_GROUP;
            msg->addr   = TOS_UART_ADDR;
            call UARTSend.send(msg);
            return SUCCESS;
        }
    }

    event result_t UARTSend.sendDone(TOS_MsgPtr msg, result_t success) {

        if (!success) {
            // call Leds.redToggle();
        } else {
            //   call Leds.greenToggle();
        }

        uartBusy = FALSE;
        signal SendMsg.sendDone[msg->type](msg, success);
        return SUCCESS;
    }

    default event result_t SendMsg.sendDone[uint8_t id] (TOS_MsgPtr msg, result_t success) {
        return SUCCESS;
    }

}  
