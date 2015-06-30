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

/* Most of the code in this file is for the BS. 
 * Things which apply only to nodes other than the BS are duly noted with
 * the comment "OT:"
 */

/* External Parameters 
 *   - MAX_NODES
 *   - BASE_STATION_ID
 *   - TPUTTIME -  How often should the per-node tput should be reported.
 *
 */


includes Appl;

module ApplM {

    provides interface StdControl; 

    uses {
        interface StdControl as RateControl;
        interface SendMsg;
        interface ReceiveMsg;
        interface SendReady;
        command result_t setBS(uint16_t id);

        interface Leds;


#if defined(LOG_TPUT) || defined(LOG_LATENCY)
        interface StdControl as LogControl;
        interface SendMsg as LogMsg;
#endif 

#ifdef LOG_TPUT
        interface Timer as LogTputTimer;
#endif 

    }

}

implementation {

    TOS_Msg msg;

    /* Base station stuff */ 
    
    /* Count of no. of packets recieved from each node */
    uint32_t msgCount[MAX_NODES];
    /* Largest seq no. from each node */
    uint16_t seq[MAX_NODES];
    /* Id of the node with largest from which a packet is received at the base
     * station
     */
    uint16_t numOfNodes; 

    /* OT: seqNo for the next outgoing packet (on the Radio) */
    uint16_t seqNo;

    uint16_t packetCount;
    uint16_t nodeIndex;
    
#ifdef LOG_TPUT
    TOS_Msg logTputMsg;
#endif 
#ifdef LOG_LATENCY
    TOS_Msg logPackInsMsg;
#endif

    command result_t StdControl.init() 
    {
        uint16_t i;

        seqNo = 1; 

        for (i = 0; i < MAX_NODES; i++){
            msgCount[i] = 0;
            seq[i] = 0;
        }

        numOfNodes = 0;
        call RateControl.init();
        call setBS(BASE_STATION_ID); /* This func need to be called in init()
                                        and after RateControl.init()*/
        call Leds.init();


#if defined(LOG_TPUT) || defined(LOG_LATENCY)
        call LogControl.init();
#endif 

        return SUCCESS; 
    }

    command result_t StdControl.start()
    {

        dbg(DBG_USR1,"ApplM: BASE_STATION = %d, LOCAL = %d\n",BASE_STATION_ID,TOS_LOCAL_ADDRESS); 

        call RateControl.start();

#if defined(LOG_TPUT) || defined(LOG_LATENCY)
        call LogControl.start();
#endif

#if defined(LOG_TPUT) 
        if(TOS_LOCAL_ADDRESS == BASE_STATION_ID)
            call LogTputTimer.start(TIMER_REPEAT,TPUTTIME); 
#endif 

        return SUCCESS;
    }

    command result_t StdControl.stop()
    {

        call RateControl.stop();

#if defined(LOG_TPUT) || defined(LOG_LATENCY)
        call LogControl.stop();
#endif 
#ifdef LOG_TPUT 
        call LogTputTimer.stop();
#endif 
        return SUCCESS;
    }



    /* SendReady is signal from the Network layer
     * (congestion control layer). Every signal 
     * indicates that the Application is allowed to 
     * add a packet(it's own packet) to the network.
     */

    event result_t SendReady.sendReady() 
    {

        /*OT: This is the only essential part that is executed for 
         * all the nodes other than the BS. 
         * In plain English it would read - Send a packet to the network layer
         * if you are not the base station.
         */
        MsgHdr *mptr = (MsgHdr *) &(msg.data);
        if(TOS_LOCAL_ADDRESS != BASE_STATION_ID)
        {
            mptr->originId = TOS_LOCAL_ADDRESS;
            mptr->seqNo = seqNo;
            if(call SendMsg.send((uint8_t )NULL,sizeof(MsgHdr),&msg))
            {
                //call Leds.greenToggle();
                ++seqNo;
            }
        }

#ifdef LOG_TPUT 
        /* A much elegant implementation shouldn't had required this. In the
         * module RateControl, sendReady is signalled whenever the node (in our
         * case only the basestation) sends out a control packet. By updating
         * seq[] and msgCount[] we count the number of control packets sent out
         * by the base station.
         */
        else 
        {
            seq[TOS_LOCAL_ADDRESS]++;
            msgCount[TOS_LOCAL_ADDRESS]++;
            if(TOS_LOCAL_ADDRESS > numOfNodes)
                numOfNodes = TOS_LOCAL_ADDRESS;
            return SUCCESS;
        }
#endif        
        return SUCCESS;
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr m, result_t success)
    {
        return success;
    }


    /* This is called only when the packet was destined for this particular
     * node.  In our single sink scenario this will be signalled only for the
     * base station node.
     */
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
    {
        uint16_t i;
        MsgHdr *mptr = (MsgHdr *) m->data;

#ifdef LOG_LATENCY
        logPacket *logPackIns = (logPacket *) &logPackInsMsg.data;
#endif

        if(mptr->originId >= MAX_NODES) 
            /* packet corrupted ?*/
            return m;

        if(mptr->originId > numOfNodes)
            numOfNodes = mptr->originId;

        /* Only count non-duplicate packets */
        if(mptr->seqNo > seq[mptr->originId] 
          || ((mptr->seqNo < seq[mptr->originId]) 
              && ((seq[mptr->originId] - mptr->seqNo) > 0xffff/2 ))) // added wrap around condition
        {
            seq[mptr->originId] = mptr->seqNo;
            ++msgCount[mptr->originId];

            if((mptr->seqNo - seq[mptr->originId]) > 1 )
                dbg(DBG_USR1,"ApplM: Received %d after %d from %d\n",mptr->seqNo,seq[mptr->originId],mptr->originId);
        }
        else if (mptr->seqNo == seq[mptr->originId])
            dbg(DBG_USR1,"ApplM: Duplicate packet from %d with seqNo = %d\n",mptr->originId,mptr->seqNo);


        dbg(DBG_USR1,"ApplM: Received ");
        for(i=0; i<= numOfNodes ; i++)
            dbg(DBG_USR1,"%d=%d ",i,msgCount[i]); 
        dbg(DBG_USR1,"\n");

#ifdef LOG_LATENCY
        logPackIns->type = PACKINS;
        logPackIns->size = 1;
        logPackIns->info.packIns.nodeId = mptr->originId;
        logPackIns->info.packIns.seqNo = mptr->seqNo;
        logPackIns->info.packIns.status = RECEIVE;
        call LogMsg.send(TOS_UART_ADDR, LOGHEADER + sizeof(logPackIns->info.packIns),&logPackInsMsg);
#endif


        return m;
    }



#ifdef LOG_TPUT   

    event result_t LogTputTimer.fired()
    {
        uint16_t i, logTputIndex = 0;
        logPacket *logTput = (logPacket *) &logTputMsg.data;
        nmemset((void *)logTput,0,DATA_LENGTH);
        logTput->type = THROUGHPUT;

        for(i=0; i<=numOfNodes ; i++)
        {
            if(msgCount[i] > 0 )
            {
                logTput->info.throughput[logTputIndex].nodeId= i;
                logTput->info.throughput[logTputIndex].seqNo=seq[i];
                logTput->info.throughput[logTputIndex++].mCount=msgCount[i];
                if(logTputIndex >= (DATA_LENGTH - 2)/sizeof(Tput))
                {
                    logTput->size = logTputIndex;
                    call LogMsg.send(TOS_UART_ADDR, DATA_LENGTH, &logTputMsg);
                    logTputIndex = 0;
                }
            }
        }

        if(logTputIndex != 0)
        {
            logTput->size = logTputIndex;
            call LogMsg.send(TOS_UART_ADDR, DATA_LENGTH, &logTputMsg);
        }

        return SUCCESS;
    }

#endif 

#if defined(LOG_TPUT) || defined(LOG_LATENCY)
    event result_t LogMsg.sendDone(TOS_MsgPtr m, result_t success)
    {
        return SUCCESS;
    }

#endif 




}
