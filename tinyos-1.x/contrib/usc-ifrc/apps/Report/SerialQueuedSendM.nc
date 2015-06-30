
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
 * Authors: Phil Buonadonna, David Culler, Matt Welsh
 *
 */

/**
 * @author Phil Buonadonna
 * @author David Culler
 * @author Matt Welsh
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
 * Authors: Phil Buonadonna, David Culler, Matt Welsh
 * 
 * $Revision: 1.1 $
 *
 */

/**
 * @author Phil Buonadonna
 * @author David Culler
 * @author Matt Welsh
 */


/* This is more of less a copy of QueuedSend. 
 * Meant to be used with ReportC.nc for the 
 * purpose of logging data
 */

/* External Parameter 
 *  - SERIAL_MAX_RETRANSMIT_COUNT  
 *  - SERIAL_QUEUE_SIZE
 */

includes AM;
includes SerialQueuedSend;

module SerialQueuedSendM {
    provides {
        interface StdControl;
        interface SendMsg as QueueSendMsg[uint8_t id];
    }

    uses {
        interface SendMsg as SerialSendMsg[uint8_t id];
        interface Leds;
        interface StdControl as CommControl;
    }
}

implementation {
    
    struct _msgq_entry {
        uint16_t address;
        uint8_t length;
        uint8_t id;
        uint8_t xmit_count;
#if defined(PLATFORM_TELOSB) || defined(PLATFORM_TELOS)
        uint8_t mem_align;  // Courtesy msp430-gcc
#endif
        TOS_Msg msg;
    } msgqueue[SERIAL_QUEUE_SIZE];

    uint16_t enqueue_next, dequeue_next;
    bool retransmit;
    bool fQueueIdle;


    command result_t StdControl.init() {
        int i;
        for (i = 0; i < SERIAL_QUEUE_SIZE; i++) {
            msgqueue[i].length = 0;
        }

        retransmit = FALSE;  // Set to TRUE to enable retransmission

        enqueue_next = 0;
        dequeue_next = 0;
        fQueueIdle = TRUE;

        call CommControl.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        call CommControl.start();
        return SUCCESS;
    }
    command result_t StdControl.stop() {
        call CommControl.stop();
        return SUCCESS;
    }

    /* Queue data structure
       Circular Buffer
       enqueue_next indexes first empty entry
       buffer full if incrementing enqueue_next would wrap to dequeue
       empty if dequeue_next == enqueue_next
       or msgqueue[dequeue_next].length == 0
     */

    task void QueueServiceTask() {
        uint8_t id;
        // Try to send next message (ignore xmit_count)
        if (msgqueue[dequeue_next].length != 0) {
            call Leds.greenToggle();
            dbg(DBG_USR2, "SerialQueuedSend: sending msg (0x%x)\n", dequeue_next);
            id = msgqueue[dequeue_next].id;

            if (!(call SerialSendMsg.send[id](msgqueue[dequeue_next].address, 
                            msgqueue[dequeue_next].length, 
                            &msgqueue[dequeue_next].msg))) {
#ifndef PLATFORM_PC
                post QueueServiceTask();
#endif
                dbg(DBG_USR2, "SerialQueuedSend: send request failed. stuck in queue\n");
            }
        }
        else {
            fQueueIdle = TRUE;
        }
    }

    command result_t QueueSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg) {
        dbg(DBG_USR2, "SerialQueuedSend: queue msg enq %d deq %d\n", enqueue_next, dequeue_next);

        if (((enqueue_next + 1) % SERIAL_QUEUE_SIZE) == dequeue_next) {
            // Fail if queue is full
            dbg(DBG_USR2, "SerialQueuedSend: queue is full!\n");
            return FAIL;
        }

        if (length > TOSH_DATA_LENGTH) {
            dbg(DBG_USR2, "SerialQueuedSend: message too long to send!\n");
            return FAIL;
        }

        if (msg == NULL) {
            dbg(DBG_USR2, "SerialQueuedSend: No storage allocated!\n");
            return FAIL;
        }

        msgqueue[enqueue_next].address = address;
        msgqueue[enqueue_next].length = length;
        msgqueue[enqueue_next].id = id;
        msgqueue[enqueue_next].msg = *msg;
        msgqueue[enqueue_next].xmit_count = 0;
        msgqueue[enqueue_next].msg.ack = 0;

        enqueue_next++; enqueue_next %= SERIAL_QUEUE_SIZE;

        dbg(DBG_USR2, "SerialQueuedSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);



        if (fQueueIdle) {
            fQueueIdle = FALSE;
            post QueueServiceTask();
        }

        return SUCCESS;

    }

    event result_t SerialSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
        if (msg != &msgqueue[dequeue_next].msg) {
            return FAIL;		// This would be internal error
        }
        // filter out non-queuesend msgs

        if ((!retransmit) || (msg->ack != 0) || (msgqueue[dequeue_next].address == TOS_UART_ADDR)) {
            //signal sendSucceed(msgqueue[dequeue_next].address);
            signal QueueSendMsg.sendDone[id](msg,success);
            msgqueue[dequeue_next].length = 0; 
            dbg(DBG_USR2, "qent %d dequeued.\n", dequeue_next);
            dequeue_next++; dequeue_next %= SERIAL_QUEUE_SIZE;
        }
        else {
            call Leds.redToggle();
            if ((++(msgqueue[dequeue_next].xmit_count) > SERIAL_MAX_RETRANSMIT_COUNT)) {
                // Tried to send too many times, just drop
                //signal sendFail(msgqueue[dequeue_next].address);
                signal QueueSendMsg.sendDone[id](msg,FAIL);
                msgqueue[dequeue_next].length = 0; 
                dequeue_next++; dequeue_next %= SERIAL_QUEUE_SIZE;
            } 
        }

        // Send next
        post QueueServiceTask();

        return SUCCESS;
    }


    default event result_t QueueSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
        return SUCCESS;
    }

    default command result_t SerialSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {
        return SUCCESS;
    }
}

