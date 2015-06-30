
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
 *  * Authors: Phil Buonadonna, David Culler, Matt Welsh
 *   *
 *    * $Revision: 1.1 $
 *     *
 *      * This MODULE implements queued send with optional retransmit.
 *       * NOTE: This module only queues POINTERS to the application messages.
 *        * IT DOES NOT COPY THE MESSAGE DATA ITSELF! Applications must maintain
 *         * their own data queues if more than one outstanding message is
 *         required.
 *          *
 *           */

/**
 *  * @author Phil Buonadonna
 *   * @author David Culler
 *    * @author Matt Welsh
 *     */


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


/* External Parameters 
 *   - SEND_TIMEOUT 
 *   - BASE_STATION_ID
 *   - MESSAGE_QUEUE_SIZE
 *   - MAX_RETRANSMIT_COUNT
 *   - ALPHA - Weight for EWMA of the queue
 */


includes AM;
includes QueuedSend;

#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
includes Global;
#endif


module QueuedSendM {
    provides {
        interface StdControl;
        interface SendMsg as QueueSendMsg[uint8_t id];
        interface QueueControl;
        interface UpdateHdr;
    }

    uses {
        interface SendMsg as SerialSendMsg[uint8_t id];
        interface MacBackoff;
        interface MacControl;
        interface Leds;
        interface StdControl as MsgControl;

        interface Random;

#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
        interface SendMsg as LogMsg;
        interface StdControl as LogControl;
#endif

        interface Timer as SendTimeoutTimer;

    }
}

implementation {

    uint32_t packetLost;
    uint32_t packetSuccessful;


    /* Id of the base station */
    norace uint16_t bsId;

    /* average queue length q_{avg} */
    norace uint32_t  queueLength;

    struct _msgq_entry {
        uint16_t address;
        uint8_t length;
        uint8_t id;
        uint8_t xmit_count;
#if defined(PLATFORM_TELOSB)  || defined(PLATFORM_TELOS)  
        uint8_t mem_align;  // Courtesy msp430-gcc
#endif     
        TOS_Msg msg;
    } msgqueue[MESSAGE_QUEUE_SIZE];

    /* head and tail of the queue */
    norace uint16_t enqueue_next, dequeue_next;

    /* Should packet be retransmitted */
    bool retransmit; 
    bool fQueueIdle;


#ifdef LOG_LINKLOSS
    // True if their was a s/w failure in sending the 
    // packet. Required for calculating link loss rate.
    // The s/w failure occurs when we try to send a packet to GenericComm and it
    // returns FAIL because it already has a packet to send. This other packet
    // is a control packet from the routing module. 
    bool sFailure; 
#endif

#ifdef LOG_QUEUE 
    TOS_Msg logQueueMsg;  
    uint8_t logQueueIndex;  
#endif

#ifdef LOG_SDLOSS
    TOS_Msg   logSDLossMsg;
#endif


// Queue length maintained with the accuracy of 1/QRESOLUTION
#define QRESOLUTION 100

    
    void calQueueLength();

    command result_t StdControl.init() {
        int i;
        for (i = 0; i < MESSAGE_QUEUE_SIZE; i++) 
            msgqueue[i].length = 0;

        retransmit = TRUE;

        enqueue_next = 0;
        dequeue_next = 0;
        fQueueIdle = TRUE;


        queueLength = 0;
        packetLost = 0; 
        packetSuccessful = 0;
        bsId = BASE_STATION_ID;

#ifdef LOG_LINKLOSS
        sFailure = FALSE;
#endif

        call Leds.init();
        call MsgControl.init();
        call Random.init();

#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
        call LogControl.init();
        logQueueIndex = 0;
#endif

        return SUCCESS;
    }

    command result_t StdControl.start() {

        call MsgControl.start();
        call MacControl.enableAck();
        
#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
        call LogControl.start();
#endif
        return SUCCESS;
    }

    command result_t StdControl.stop() {

        call MsgControl.stop();
        
#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
        call LogControl.stop();
#endif
        return SUCCESS;
    }

    command result_t QueueControl.setBS(uint16_t id)
    {
        bsId = id;
        return SUCCESS;
    }

    async event int16_t MacBackoff.initialBackoff(TOS_MsgPtr m)
    {
        /* Base station get highest priority as all its 
         * packets are control packets which are used to 
         * propagate rLocal of the BS 
         */

        if(bsId == TOS_LOCAL_ADDRESS)
        {
            return (call Random.rand() & BS_INIT_BACKOFF) + 1;  
        }  
        else 
        {
            return (call Random.rand() & (DEFAULT_INIT_BACKOFF)) + 1;  
        }


    }

    async event int16_t MacBackoff.congestionBackoff(TOS_MsgPtr m)
    {

        if(bsId == TOS_LOCAL_ADDRESS)
        {
            return (call Random.rand() & BS_CONG_BACKOFF) + 1;  
        }  
        else 
        {
            return (call Random.rand() & DEFAULT_CONG_BACKOFF) + 1;  
        }

    }


    /* Queue data structure
       Circular Buffer
       enqueue_next indexes first empty entry
       buffer full if incrementing enqueue_next would wrap to dequeue
       empty if dequeue_next == enqueue_next
       or msgqueue[dequeue_next].length == 0
     */

    /* This task is called repeatedly until there isn't any message left
     * in the queue. When the queues goes empty the repeated cycle
     * of calling QueueServiceTask ends and fQueueIdle is set to TRUE
     */


    task void QueueServiceTask() 
    {
        uint8_t id;

        /** for some reason the length field sometimes get corrupted 
         * corrupted 
         */
        if(msgqueue[dequeue_next].length > DATA_LENGTH)
        {
            // Drop the packet
            msgqueue[dequeue_next].length = 0; 
            dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
            post QueueServiceTask();
            return;
        }


        dbg(DBG_USR3,"dequeue_next = %d msgqueue[dequeue_next].length = %d\n",dequeue_next,msgqueue[dequeue_next].length); 

        // Try to send next message (ignore xmit_count)
        if (msgqueue[dequeue_next].length != 0) 
        {
            dbg(DBG_USR3, "QueuedSend: sending msg (0x%x)\n", dequeue_next);
            id = msgqueue[dequeue_next].id;

            /*IFRC: Make an upcall for upper layer to add control
             * information to the outgoing packet.
             */
            signal UpdateHdr.updateHdr(&msgqueue[dequeue_next].address, &(msgqueue[dequeue_next].msg));

            if (!(call SerialSendMsg.send[id](msgqueue[dequeue_next].address, 
                            msgqueue[dequeue_next].length, 
                            &(msgqueue[dequeue_next].msg)))) 
            {
                if(!post QueueServiceTask())
                {
                    // pass
                }
#ifdef LOG_LINKLOSS
                atomic sFailure = TRUE;
#endif 
            }
            else 
            {
#ifdef LOG_LINKLOSS
                atomic sFailure = FALSE;
#endif
                /**
                 * SendTimeoutTimer make sure we come out of queue blocking
                 * due to loss of sendDone
                 */
                call SendTimeoutTimer.start(TIMER_ONE_SHOT, SEND_TIMEOUT);
            }
        }
        else 
        {
            fQueueIdle = TRUE;
        }
    }



    command result_t QueueSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {


#ifdef LOG_QUEUE
        logPacket *logQueue = (logPacket *) &logQueueMsg.data;
#endif
#ifdef LOG_QUEUE
        logQueue->type = QUEUEINFO;
        logQueue->info.qInfo[logQueueIndex].avgLength    = call QueueControl.getOccupancy();
        logQueue->info.qInfo[logQueueIndex].instLength = call QueueControl.getInstOccupancy();
        logQueue->info.qInfo[logQueueIndex].enqueue =  enqueue_next;
        logQueue->info.qInfo[logQueueIndex].dequeue = dequeue_next;
        logQueue->info.qInfo[logQueueIndex++].fQueueIdle = fQueueIdle;

        if (logQueueIndex >= (DATA_LENGTH - LOGHEADER)/sizeof(logQueue->info.qInfo[0]))
        {
            logQueue->size = logQueueIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logQueueMsg);
            atomic logQueueIndex = 0;
        }
#endif

        if (((enqueue_next + 1) % MESSAGE_QUEUE_SIZE) == dequeue_next) {
            // Queue is Full. Calculate queueLength and return FAIL.
            calQueueLength(); 
            return FAIL;
        }
        msgqueue[enqueue_next].address = address;
        msgqueue[enqueue_next].length = length;
        msgqueue[enqueue_next].id = id;

        msgqueue[enqueue_next].msg = *msg;
        msgqueue[enqueue_next].xmit_count = 0;
        msgqueue[enqueue_next].msg.ack = 0;

        enqueue_next++; enqueue_next %= MESSAGE_QUEUE_SIZE;

        dbg(DBG_USR3, "QueuedSend: Successfully queued msg to 0x%x, enq %d, deq %d\n", address, enqueue_next, dequeue_next);
        if (fQueueIdle) {
            fQueueIdle = FALSE;
            if(!post QueueServiceTask())
                ;
        }

        /* Calculate q_{avg}. This means that the 
         * queue length is calculated on every packet
         * addition to the queue.
         */
        calQueueLength();

        return SUCCESS;

    }

    event result_t SerialSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {

        if (msg != &(msgqueue[dequeue_next].msg))
        {
            return FAIL;		// This would be internal error
        }

        // Surprise, we received a sendDone after send :) 
        // Turn off the timeout timer.
        call SendTimeoutTimer.stop();

        // filter out non-queue send msgs
        if ((!retransmit) || (msg->ack != 0) || (msgqueue[dequeue_next].address == TOS_UART_ADDR) ||
                (msgqueue[dequeue_next].address == TOS_BCAST_ADDR) )
        {
            signal QueueSendMsg.sendDone[id](msg,success);
            packetSuccessful++;
            msgqueue[dequeue_next].length = 0;
            dbg(DBG_USR3, "qent %d dequeued.\n", dequeue_next);
            dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
        }
        else 
        {
            dbg(DBG_USR3,"QueuedSend: xmit_count = %ld\n",msgqueue[dequeue_next].xmit_count);
            packetLost++;
            if ((++(msgqueue[dequeue_next].xmit_count) > MAX_RETRANSMIT_COUNT)) 
            {
                // Tried to send too many times, just drop
                signal QueueSendMsg.sendDone[id](msg,FAIL);
                msgqueue[dequeue_next].length = 0;
                dequeue_next++; dequeue_next %= MESSAGE_QUEUE_SIZE;
            } 
        }


        // Send next
        if(!post QueueServiceTask())
            ;

        dbg(DBG_USR3,"QueuedSend: packetLost = %ld  packetSuccessful = %ld\n",packetLost,packetSuccessful);

        return SUCCESS;
    }

    event result_t SendTimeoutTimer.fired()
    {
        /* We reach here if a sendDone is not received in SEND_TIMEOUT ms after a
         * SendMsg 
         */

#ifdef LOG_SDLOSS
        logPacket *logSDLoss = (logPacket *) &logSDLossMsg.data;
#endif

#ifdef LOG_SDLOSS
        logSDLoss->type = SDLOSS;
        logSDLoss->size = 0;
        call LogMsg.send(TOS_UART_ADDR,LOGHEADER,&logSDLossMsg);
#endif

        post QueueServiceTask();
        return SUCCESS;
    }

    uint16_t outstandingQueue()
    {

        uint16_t uiOutstanding;
            
        if (enqueue_next >= dequeue_next)    
            uiOutstanding = enqueue_next - dequeue_next;
        else 
            uiOutstanding = enqueue_next + (MESSAGE_QUEUE_SIZE - dequeue_next);

        return uiOutstanding;

    }

    uint8_t command QueueControl.getInstOccupancy()
    {
        uint16_t uiOutstanding = enqueue_next - dequeue_next;
        // This statement works only if MESSAGE_QUEUE_SIZE%2 == 0 
        //uiOutstanding %= MESSAGE_QUEUE_SIZE;
        
         uiOutstanding = outstandingQueue();
        return (uint8_t) uiOutstanding;

    }


    async command uint16_t QueueControl.getOccupancy() 
    {
        /* Returns avg queue length q_{avg}
         * Except for the return statement all the other 
         * statements are for debugging purposes. 
         * Finds out the instantaneous queue at the node
         * for printing purposes. Note that the avg queue
         * length is "not" updated here. 
         */

//        uint16_t uiOutstanding = enqueue_next - dequeue_next;
//        uiOutstanding %= MESSAGE_QUEUE_SIZE;
//          uiOutstanding = outstandingQueue();


        return queueLength/QRESOLUTION; 
    }


    /* This function calculates the queue length as 
     * a weighted average. 
     * The instances when this function is called which
     * in turn decides the frequency with which avg
     * queue is calculated "matters"
     */

    void calQueueLength()
    {
        /* keep this 32 bit to avoid overflow */ 

        uint32_t newQueueLength; 
        uint32_t tmp;
        
        /* uiOutstanding is the instantaneous queue size */
        uint16_t uiOutstanding = enqueue_next - dequeue_next;
        // uiOutstanding %= MESSAGE_QUEUE_SIZE;
         uiOutstanding = outstandingQueue();

        

        /* queueLength is the Weighted average of the queue
         * length with weightage as ALPHA
         *    q_{avg} =  (1-\alpha) * q_{avg} + \alpha * q_{inst}
         */
        /* maintain qlength as queueLength = q_{avg} * 100 */
        //queueLength  = ((100 - ALPHA) * queueLength + ALPHA*uiOutstanding)/100;
        //queueLength  = ((QRESOLUTION - ALPHA) * queueLength + ALPHA*uiOutstanding*QRESOLUTION)/QRESOLUTION;
        
        newQueueLength  = (QRESOLUTION - ALPHA); 
        newQueueLength *= queueLength;
        tmp = ALPHA*uiOutstanding;
        tmp *= QRESOLUTION;
        newQueueLength += tmp;
        newQueueLength /= QRESOLUTION;

        queueLength = newQueueLength;
        
        
        return;
    }

    /* Gives the number of time the packet at the head 
     * of the queue is been transmitted.
     */
    command uint8_t QueueControl.getXmitCount() {
        if (msgqueue[dequeue_next].length != 0)
            return msgqueue[dequeue_next].xmit_count;
        return 0;
    }


    default event result_t QueueSendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success) {
        return SUCCESS;
    }

    default command result_t SerialSendMsg.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {
        return SUCCESS;
    }
    

#ifdef LOG_LINKLOSS
    command bool QueueControl.isSFailure()
    {
        return sFailure;
    }
#endif 

#if defined(LOG_QUEUE) || defined(LOG_SDLOSS)
    event result_t LogMsg.sendDone(TOS_MsgPtr m, result_t success)
    {
        return SUCCESS;
    }
#endif




}

