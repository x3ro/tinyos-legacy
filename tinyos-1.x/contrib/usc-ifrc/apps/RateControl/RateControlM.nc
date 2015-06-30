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

/** 
 * The code is currently not fully ready for generic used. We need 
 * to parameterize the SendReady interface and we need to decide 
 * how SendReady for different application is called when sendTimer 
 * fires
 */


includes Global;
includes RateControl;

module RateControlM { 

    provides {
        interface StdControl; 
        interface SendReady;
        interface SendMsg as Send[uint8_t id];
        interface ReceiveMsg as Receive[uint8_t id];
        command result_t setBS(uint16_t id);

    }

    uses { 

        interface StdControl as TimerControl;
        interface StdControl as QControl; 
        interface SendMsg as SendMsg[uint8_t id];
        interface QueueControl;

        interface CommControl;
        interface StdControl as SubControl;
        interface ReceiveMsg as ReceiveMsg[uint8_t id];

        interface UpdateHdr;

        interface Random;

        /* Only for nodes other than the base station */
        interface Timer as SendTimer; 
        /* Only for the base station */
        interface Timer as BeaconTimer;
#ifdef ROUTING    
        interface StdControl as RouteSelectionControl;
        interface RouteControl;
        interface Timer as RouteStabilizeTimer;
#endif



#if defined(LOG_RLOCAL) || defined (LOG_NEIGH)  || defined (LOG_LQI) || defined (LOG_PACKLOSS) || defined(LOG_LATENCY)|| defined(LOG_TRANS) || defined(LOG_LINKLOSS)
#define LOG_SOME
#endif
        
#ifdef LOG_SOME
        interface StdControl as LogControl;
        interface SendMsg   as LogMsg; 
#ifdef LOG_NEIGH
        interface Timer as LogNInfoTimer;
#endif
#ifdef LOG_LINKLOSS
        interface Timer as LogLinkLossTimer;
#endif
#endif 
#if 0
#ifdef DEBUG
        interface StdControl as ReportControl; 
        interface SendMsg as ReportSend;
#endif
#endif

        interface Leds;
    }
}

/* External Parameters 
 * 
 * MAX_NEIGH  
 * RESOLUTION
 */

implementation { 

    uint32_t rLocal; 
    uint32_t rThresh;
    uint8_t  mode; 
    uint8_t  weight;

    uint16_t parentId;
    uint32_t parentRLocal; 
    uint32_t parentRThresh;
    uint8_t  parentMode; 
    uint32_t parentSSThresh; 

    int8_t  congChildIndex;
    int8_t  congNeighIndex;
    uint8_t congNeighOrNeighChild;

    uint32_t ssThresh;
    uint8_t revertmode;

    /* For Dynamic Tree */ 
#define MAX_HISTORY 40 
    typedef struct rPacketInfo { 
        uint16_t originId;
        uint16_t seqNo;
        uint16_t lhId;
    }recPacketInfo; 

    recPacketInfo nodePacketInfo[MAX_HISTORY];
    uint8_t packetInfoIndex;
    
    neighInfo  neighTable[MAX_NEIGH];
    
    
    bool decLastCycle; 
    
    /* Packet that need to be forwarded need to be stored
     * till they are actually transmitted
     */
    TOS_Msg fwdMsgBuffer;


    void updateRLocal();
    void checkQueue();

    void bsIFRCRules();
    void IFRCRules();
    void calcParameters(int8_t neighIndex);


   /* Base Station specific variables and functions */
#define DEFAULT_CHILDMAX 1 
    uint16_t bsId;
    int8_t   bsChildMaxRLocalIndex;
    uint32_t bsChildMaxRLocal;
    uint32_t lastBSBeaconPeriod;

//    /** For debugging */
    uint16_t beaconCount; // seqNo for the packets from BS

    void sendBeacon(int count);
    void bsIFRCRules();
    void incrementBSRLocal(uint32_t beaconPeriod);

    
/* **********************************
 * Declarations for Utility Functions *
 * **********************************
 */
    uint32_t change(uint32_t v1 , uint32_t v2);
    uint16_t computeTCRC(MsgHdr *mptr);
    uint32_t calTimerVal(uint32_t rate);

/* *************************
 * Declaration for Logging *
 * *************************
 */
    
#ifdef LOG_RLOCAL
    TOS_Msg logRLocalMsg;
    uint8_t logRLocalIndex;
    void sendRLocal(bool sendImmediate, uint32_t increment);
#endif

#ifdef LOG_LQI
    TOS_Msg logLQIMsg;
    uint8_t logLQIIndex;
    void sendLQI(uint16_t nodeId, uint16_t lqi, bool status);
#endif
#ifdef LOG_NEIGH
#define LOG_NINFO_TIME 2000 // 2 sec  
    TOS_Msg logNeighMsg;
    void sendNInfo();
#endif
#ifdef LOG_PACKLOSS
    TOS_Msg logPackLossMsg;
    uint8_t logPackLossIndex;
    void sendPackLoss(uint16_t originId, uint16_t seqNo, uint8_t qSize, uint8_t cause);
#endif
#ifdef LOG_LATENCY
    TOS_Msg logPackInsMsg;
    void sendLatency(uint16_t originId, uint16_t seqNo, bool status);
#endif
#ifdef LOG_TRANS
    TOS_Msg logTransMsg;
    uint8_t logTransIndex;
    void sendTrans(uint16_t originId, uint16_t seqNo, uint8_t xmitCount, uint8_t dropped);
#endif
#ifdef LOG_LINKLOSS
#define LOG_LINKLOSS_TIME 10000 
    TOS_Msg logLinkLossMsg;
    uint16_t fwdSeqNo;
    uint16_t lastSeqNo;
#endif

#ifdef LOG_INFO
    void sendInfo(uint8_t *data, uint8_t size);
    TOS_Msg logInfoMsg;
#endif


#if 0
#ifdef DEBUG 
    TOS_Msg uartMsg;
#endif 
#endif 

    
/* *************************
 * Main Code starts here   *
 * *************************
 */
    command result_t StdControl.init()
    {
        uint16_t i ; 

        atomic {

            rLocal     = SSVALUE; 
            rThresh    = rLocal;
            mode       = START;
            weight     = 1;

            /* This functionality is need for the routing layer */
            /* MultiHopLQI sets the parentAddr = TOS_BCAST_ADDR if 
             * a parent is not found. Need to initialize so that 
             * check can be performed.
             */
            parentId        = TOS_BCAST_ADDR;
            parentRLocal    = rLocal;
            parentRThresh   = rThresh;
            parentMode      = START;
            parentSSThresh  = BANDWIDTH;

            congChildIndex     = -1;
            congNeighIndex     = -1;
            congNeighOrNeighChild = INVALID;

            ssThresh = BANDWIDTH;

            /* For Dynamic Tree */

            for(i=0; i < MAX_HISTORY; i++)
            {
                nodePacketInfo[i].originId = TOS_BCAST_ADDR;
                nodePacketInfo[i].seqNo = 0;
                nodePacketInfo[i].lhId = TOS_BCAST_ADDR;
            }
            packetInfoIndex = 0;
            

            for (i=0 ; i < MAX_NEIGH; i++)
                neighTable[i].type = INVALID;

            decLastCycle = FALSE;


            /* Base Station specific parameters
             */
            call setBS(BASE_STATION_ID);
        }

        call TimerControl.init();
        call QControl.init(); /* set the retransmit variable to true - Pending */
        call SubControl.init();

#ifdef ROUTING
        call RouteSelectionControl.init();
#endif 


#ifdef LOG_SOME
        call LogControl.init();
#ifdef LOG_RLOCAL
        logRLocalIndex = 0;
#endif 
#ifdef LOG_LQI
        logLQIIndex = 0;
#endif 
#ifdef LOG_PACKLOSS
        logPackLossIndex = 0;
#endif 
#ifdef LOG_TRANS
        logTransIndex = 0;
#endif 
#ifdef LOG_LINKLOSS 
        fwdSeqNo = 0;
        lastSeqNo = fwdSeqNo;
#endif
#endif 
#if 0
#ifdef DEBUG    
        call ReportControl.init();
#endif
#endif

        call Leds.init();
        return SUCCESS; 
    }



// STDCONTROL.START
    
    command result_t StdControl.start()
    {
        uint32_t timerVal;
        
#ifdef ROUTING
        /* If we are using the Routing module let the routing module 
         * stabilized on permanent routes
         */
        timerVal = 1000;
        timerVal *= ROUTE_STAB_TIME; 
        call RouteStabilizeTimer.start(TIMER_ONE_SHOT, timerVal);
        call RouteSelectionControl.start();
#endif 
                
        call QControl.start();
        call SubControl.start();
        call CommControl.setCRCCheck(TRUE); 
        call CommControl.setPromiscuous(TRUE); 

/*******************
 * Code for Logging
 * ****************/
#ifdef LOG_SOME
        call LogControl.start();
#endif 
#ifdef LOG_RLOCAL
        // Just so that the serial forwarder becomes active
        if(TOS_LOCAL_ADDRESS != bsId)
            sendRLocal(TRUE,0xFFFFFFFF);
#endif
#ifdef LOG_NEIGH
        call LogNInfoTimer.start(TIMER_REPEAT, LOG_NINFO_TIME);
#endif
#ifdef LOG_LINKLOSS
        call LogLinkLossTimer.start(TIMER_REPEAT, LOG_LINKLOSS_TIME);
#endif
#if 0
#ifdef DEBUG    
        call ReportControl.start();
#endif
#endif
        
        return SUCCESS; 
    }



    command result_t StdControl.stop()
    {
        call SendTimer.stop();
        call QControl.stop();
        call SubControl.stop();
#ifdef ROUTING
        call RouteSelectionControl.stop();
#endif 
#ifdef LOG_SOME
        call LogControl.stop();
#endif 
        return SUCCESS; 
    }


    /* This timer is used only in case of dynamic routing. Every time the timer
     * fires we check to see in the node is able to find a parent. If so we set
     * the parentAddr and move on. Else we wait for one more cycle of
     * ROUTE_STAB_TIME 
     * Moreover this Timer is not used for the BASE station Node.
     */

#ifdef ROUTING
    event result_t RouteStabilizeTimer.fired()
    {
        uint32_t  jitter;
        uint32_t  timerVal;

        parentId = call RouteControl.getParent();
        if(parentId != TOS_BCAST_ADDR)
        {
            // call RouteSelectionControl.stop();
            // The routing algorithm will keep running in case new nodes
            // want to join the network.
            call RouteControl.stopChange();
            if(TOS_LOCAL_ADDRESS == bsId)
            {
                sendBeacon(1);
                call BeaconTimer.start(TIMER_ONE_SHOT,calTimerVal(bsChildMaxRLocal/BEACONFACTOR));
            }
            else
            {
            // Not sure if jitter is necessarily required.
#ifdef FIXRATE 
                rLocal = RATE;
                jitter = (TOS_LOCAL_ADDRESS % 4)*500;
                call SendTimer.start(TIMER_ONE_SHOT,calTimerVal(rLocal + jitter));
#else
                jitter = ((call Random.rand() & 0xF) * SSVALUE)/0xF;
                call SendTimer.start(TIMER_ONE_SHOT,calTimerVal(rLocal + jitter));
#endif
            }
        }
        else 
        {
            /* Wait for some more time */
            timerVal = 1000;
            timerVal *= ROUTE_STAB_TIME; 
            call RouteStabilizeTimer.start(TIMER_ONE_SHOT, timerVal);
        }

        return SUCCESS;
    }
#endif



    event result_t SendTimer.fired() 
    {
        int i;
#ifdef LOG_RLOCAL
        uint32_t lastRLocal = rLocal;
#endif 

        for(i=0; i< weight; i++)
            signal SendReady.sendReady();
        
        // order of statements here is Imp. Be sure before 
        // changing it.
        updateRLocal();
        checkQueue();
        decLastCycle = FALSE;
        
#ifdef FIXRATE
        rLocal = RATE;
#endif
        call SendTimer.start(TIMER_ONE_SHOT,calTimerVal(rLocal));


#ifdef LOG_RLOCAL
        if(TOS_LOCAL_ADDRESS != bsId)
            sendRLocal(FALSE,change(rLocal, lastRLocal));
#endif

        return SUCCESS;
    }


    command result_t Send.send[uint8_t id](uint16_t address, uint8_t length, TOS_MsgPtr msg)
    {

#if defined(LOG_PACKLOSS) || defined(LOG_LATENCY)
        MsgHdr *mptr = (MsgHdr *) msg->data;
#endif

        if( call SendMsg.send[id](parentId,length,msg) == SUCCESS)
        {
#ifdef LOG_LATENCY
            if(mptr->originId == TOS_LOCAL_ADDRESS)
                sendLatency(mptr->originId,mptr->seqNo,SEND);
#endif
            return SUCCESS;
        }
        else 
        {
            // SendMsg.send Failed
#ifdef LOG_PACKLOSS
            if(mptr->originId != TOS_LOCAL_ADDRESS)
                sendPackLoss(mptr->originId, mptr->seqNo, call QueueControl.getOccupancy(), QUEUEFULL);
#endif 
            return FAIL;
        }

    }

    event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr msg, result_t success)
    {
        // All logging code.
#if defined(LOG_PACKLOSS) || defined(LOG_TRANS) 
        MsgHdr *mptr = (MsgHdr *) msg->data;
#ifdef LOG_PACKLOSS
        if(msg->ack == 0)
            sendPackLoss(mptr->originId, mptr->seqNo, 0xFF, LINKLOSS);
#endif 
#ifdef LOG_TRANS
        sendTrans(mptr->originId,mptr->seqNo,call QueueControl.getXmitCount(),!success);
#endif 
#endif
#ifdef LOG_TPUT 
        // inform the BS about any control packets that were sent. 
        if ( (TOS_LOCAL_ADDRESS == bsId) && (id == AM_BSBEACON)  && success)
            signal SendReady.sendReady();
#endif            

        // IFRC code
        return signal Send.sendDone[id](msg,success);
    }

    default event result_t Send.sendDone[uint8_t id] (TOS_MsgPtr msg, result_t success)
    {
        return success;
    }

    /* QueuedSendM signals this event once a packet reaches
     * the head of the queue. This event updates the field
     * in the packet related to most recent rate and
     * congestion information for the neighbours
     */
    event result_t UpdateHdr.updateHdr(uint16_t *address, TOS_MsgPtr msg)
    {

        MsgHdr *mptr = (MsgHdr*) msg->data;


        mptr->lhId = TOS_LOCAL_ADDRESS;
        mptr->lhRLocal = rLocal;
        mptr->lhRThresh = rThresh;
        mptr->lhMode = mode;
        mptr->lhSSThresh = ssThresh;

        if(congChildIndex != -1)
        {
            mptr->lhCongChildId = neighTable[congChildIndex].neighId;
            mptr->lhCongChildRLocal = neighTable[congChildIndex].neighRLocal;
            mptr->lhCongChildRThresh = neighTable[congChildIndex].neighRThresh;
            mptr->lhCongChildMode = neighTable[congChildIndex].neighMode;
        }
        else
        {
            mptr->lhCongChildId = TOS_BCAST_ADDR;
            mptr->lhCongChildRLocal = INFINITY;
            mptr->lhCongChildRThresh = INFINITY;
            mptr->lhCongChildMode = START;
        }

#ifdef LOG_LINKLOSS 
        if(call QueueControl.isSFailure())
            //mptr->lhFwdSeqNo = (fwdSeqNo - 1);
            ;
        else 
            mptr->lhFwdSeqNo = fwdSeqNo++;
#endif

        // Dynamic Tree 
        // Change the address only if it is the first time the packet is being
        // transmitted. This is to avoid loop. Rule of finding loops is: if you
        // receive the same packet (originId + seqNo) from a different node than
        // the previous one their is a loop. 
        if (*address != TOS_BCAST_ADDR && call QueueControl.getXmitCount() == 0)
            *address = parentId;
        
        /* This should be the last line in this function */
        mptr->tCRC = computeTCRC(mptr);
        return SUCCESS;
    }


    
    void updateRLocal()
    {
        uint32_t increment;
        uint32_t tmp;

        if(mode == START)
        {
            if (rLocal < parentRLocal)
            {
                increment = PHI;
                rLocal += increment;
            }
            if(rLocal >= ssThresh)
            {
                mode = AI;
                revertmode = AI;
                rThresh = ssThresh;
#ifdef PCALLOWED 
                call RouteControl.startChange();
#endif
            }
            // Stop route change during slow start
            else 
                call RouteControl.stopChange();
        }
        else 
        {
            /* The if statement is from the previous code. It should not be
             * required now so check without it once everything is working */
            if (rLocal < parentRLocal)
            {
                /* delta =  rThresh_{2}/EPSILON */
                /* r{i} = r{i} + delta/r{i} */
                /* since we keep r'= r{i}*RESOLUTION we need to 
                 * r'{i} = r'{i} + delta/r'{i} */
                /* The order of operation is important to avoid overflow */
                increment = rThresh/EPSILON;
                if (rThresh > rLocal)
                {
                    tmp = rThresh/rLocal;
                    increment *= tmp;
                }
                else 
                {
                    increment *= rThresh;
                    increment /= rLocal;
                }

                /* increase the value atleast by 0.001 */
                if (increment < 1)
                    increment = 1;
                
                rLocal += increment;
            }
        }
    }




    void checkQueue()
    {
        uint8_t qSize;

        /* Get q_{avg} */
        qSize = call QueueControl.getOccupancy();

        // Since this function is called on every packet reception
        // mode will move to higher state only via the lower congestion
        // state.
        switch(mode)
        {
            //Pending
            /* I think every time local congestion occurs ssThresh should be updated,
             * essentially whenever updating rThresh */
            
            case START:
                if(qSize >= UPPERTHRESH0)
                {
                    if (ssThresh == BANDWIDTH)
                    {
                        ssThresh = rLocal/2;
                        rThresh = ssThresh;
                    }
                    rLocal = SSVALUE + 11 ;
                    mode = HALF;
                    revertmode = START;
                }
                break;
            case AI:
                if(qSize >= UPPERTHRESH0)
                {
                    if(decLastCycle == FALSE )
                    {
                        rLocal = (int)((float)rLocal * MDFACTOR);
                        rThresh = rLocal;
                        ssThresh = rThresh;
                    }
                    mode = HALF;
                    revertmode = AI;
                }
                break;
            case HALF: 
                if(qSize >= UPPERTHRESH1)
                {
                    if(decLastCycle == FALSE )
                    {
                        rLocal = (int)((float)rLocal * MDFACTOR);
                        rThresh = rLocal;
                        ssThresh = rThresh;
                    }
                    mode = FOURTH;
                }
                else if ( qSize < LOWERTHRESH)
                    mode = revertmode;
                break;
            case FOURTH:
                if(qSize >= UPPERTHRESH2)
                {
                    if(decLastCycle == FALSE )
                    {
                        rLocal = (int)((float)rLocal * MDFACTOR);
                        rThresh = rLocal;
                        ssThresh = rThresh;
                    }
                    mode = EIGHTH;
                }
                else if ( qSize < LOWERTHRESH)
                    mode = revertmode;
                break;
            case EIGHTH:
                if(qSize >= UPPERTHRESH3)
                {
                    /* If queue has reached this level go into slow 
                     * start irrespective of whether you reduced your 
                     * rLocal last cycle 
                     */

                        // This line should no more be required.
                        rThresh = (int)((float)rLocal * MDFACTOR);
                       
                        rLocal = SSVALUE ;
                        mode = START; 
                        ssThresh = BANDWIDTH;
                }
                else if (qSize < LOWERTHRESH)
                    mode = revertmode;
                break;

        }

        if(rLocal <= SSVALUE && mode != START)
        {
            rLocal = SSVALUE;
            mode = START;
            ssThresh = BANDWIDTH;
        }

    }





    /* All message that are received are intercepted to
     * extract rate and congestion information about the
     * neighbour 
     */
    // Beacon id is different from the application message id. 
    // This should be on the same id. Find a way to handle this. 
    event TOS_MsgPtr ReceiveMsg.receive[uint8_t id](TOS_MsgPtr msg) 
    {
        uint16_t i;
        int freeIndex, neighIndex;
        bool newEntry;
        uint16_t oldParentId;
        recPacketInfo tmp;

        MsgHdr *mptr = (MsgHdr *) msg->data;

        newEntry = FALSE;

 

        /** Known bug - some times the length field is > DATA_LENGTH. 
         * Since no fix is known yet.
         */

        if (msg->length > DATA_LENGTH)
            return msg;
        if(mptr->tCRC != computeTCRC(mptr))
            return msg;

        // DYNAMIC TREE 
        for (i=0 ; i < MAX_HISTORY ; i++)
        {
            if( msg->addr == TOS_LOCAL_ADDRESS && 
                    (mptr->originId == nodePacketInfo[i].originId) &&
                    (mptr->seqNo == nodePacketInfo[i].seqNo) &&
                    (mptr->lhId  != nodePacketInfo[i].lhId)
                    )
            {
                sendNInfo();
#ifdef LOG_INFO
                sendInfo((uint8_t *)&nodePacketInfo[i], sizeof(recPacketInfo));
#endif
                tmp.originId = mptr->originId;
                tmp.seqNo = mptr->seqNo;
                tmp.lhId = mptr->lhId;
#ifdef LOG_INFO
                sendInfo((uint8_t *)&tmp, sizeof(recPacketInfo));
#endif
                call RouteControl.breakLoop();
            }
                
        }

        if(TOS_LOCAL_ADDRESS != bsId && msg->addr == TOS_LOCAL_ADDRESS)
        {
            nodePacketInfo[packetInfoIndex].originId = mptr->originId;
            nodePacketInfo[packetInfoIndex].seqNo = mptr->seqNo;
            nodePacketInfo[packetInfoIndex].lhId = mptr->lhId;
//            sendNInfo();
//            sendInfo((uint8_t*)&nodePacketInfo[packetInfoIndex], sizeof(recPacketInfo));
            packetInfoIndex = (packetInfoIndex + 1 ) % MAX_HISTORY;
        }
          
        oldParentId = parentId;
        parentId = call RouteControl.getParent();

        
        
#ifdef LOG_LQI
        sendLQI(mptr->lhId, msg->lqi)
#endif 

        freeIndex = -1;
        neighIndex = -1;
        for(i=0; i< MAX_NEIGH ; i++)
        {
            //DYNAMIC TREE
            if(oldParentId != parentId && neighTable[i].neighId == oldParentId)
                neighTable[i].type = NEIGH;
            if ( neighTable[i].neighId == parentId)
            {
                //Pending : convert the parent only if type!=INVALID else you
                //will set wrong values of parentRLocal etc. 
                neighTable[i].type = PARENT;
                neighTable[i].age  = AGELIMIT;

                /* Parameter are calculated based on the entry added. Since
                 * parent may or may not be that entry we need to calculate the
                 * following parameter on every packet reception. 
                 */
                atomic 
                {
                    parentRLocal = neighTable[i].neighRLocal;
                    parentRThresh = neighTable[i].neighRThresh;
                    parentMode = neighTable[i].neighMode;
                    parentSSThresh = neighTable[i].neighSSThresh;
                }
            }
            
            /* for now don't forget your parent :o */
            if(neighTable[i].age && neighTable[i].type != PARENT)
                neighTable[i].age--;

            if(neighTable[i].age <= 0)
            {
                neighTable[i].type = INVALID;
                neighTable[i].age = 0;
            }

            if( neighTable[i].type != INVALID && 
                neighTable[i].neighId == mptr->lhId)
                neighIndex = i;

            if( freeIndex == -1 && 
                neighTable[i].type == INVALID)
                freeIndex = i;
                
        }

        // No space to accomodate new neighbor
        if (neighIndex == -1 && freeIndex == -1)
            return msg;

        if(neighIndex == -1)
        {
            neighIndex = freeIndex;
            newEntry = TRUE;
        }


        if( newEntry==FALSE && neighTable[neighIndex].neighMode < mptr->lhMode )
           neighTable[neighIndex].neighTransition = TRUE; 
        else 
           neighTable[neighIndex].neighTransition = FALSE; 

        neighTable[neighIndex].neighId = mptr->lhId;
        neighTable[neighIndex].neighRLocal = mptr->lhRLocal;
        neighTable[neighIndex].neighRThresh = mptr->lhRThresh;
        neighTable[neighIndex].neighMode = mptr->lhMode;
        neighTable[neighIndex].neighSSThresh = mptr->lhSSThresh;
        
        if(newEntry==FALSE && mptr->lhCongChildId != TOS_BCAST_ADDR && 
           (neighTable[neighIndex].neighCongChildId != mptr->lhCongChildId ||
            neighTable[neighIndex].neighCongChildMode < mptr->lhCongChildMode)
           )
            neighTable[neighIndex].neighCongChildTransition = TRUE;
        else
            neighTable[neighIndex].neighCongChildTransition = FALSE;
        neighTable[neighIndex].neighCongChildId = mptr->lhCongChildId;
        neighTable[neighIndex].neighCongChildRLocal = mptr->lhCongChildRLocal;
        neighTable[neighIndex].neighCongChildRThresh = mptr->lhCongChildRThresh;
        neighTable[neighIndex].neighCongChildMode = mptr->lhCongChildMode;


        /* Inferred Parameter */
        neighTable[neighIndex].age = AGELIMIT;
        if(mptr->lhId == parentId)
            neighTable[neighIndex].type = PARENT;
        else if (msg->addr == TOS_LOCAL_ADDRESS)  
            neighTable[neighIndex].type = CHILD;
        else 
            neighTable[neighIndex].type = NEIGH;
            

#ifdef LOG_LINKLOSS
        if(newEntry)
        {
            neighTable[neighIndex].packLoss  = 0;
            neighTable[neighIndex].packCount = 0;
        }
        else {
            // Since in our scheme packet cannot arrive out of order. Now with
            // parent change allowed it can :O
            if( neighTable[neighIndex].lastFwdSeq < mptr->lhFwdSeqNo)
            {
                neighTable[neighIndex].packLoss   += (mptr->lhFwdSeqNo - neighTable[neighIndex].lastFwdSeq - 1);
                neighTable[neighIndex].packCount  += (mptr->lhFwdSeqNo - neighTable[neighIndex].lastFwdSeq);
            }
            else 
            {
                neighTable[neighIndex].packLoss   += (0xFF*sizeof(fwdSeqNo) - neighTable[neighIndex].lastFwdSeq) + (mptr->lhFwdSeqNo);
                neighTable[neighIndex].packCount  += (0xFF*sizeof(fwdSeqNo) - neighTable[neighIndex].lastFwdSeq) + (mptr->lhFwdSeqNo) + 1;
            }
        }



        neighTable[neighIndex].lastFwdSeq  = mptr->lhFwdSeqNo; 
#endif 


        /* If the message was sent by your child add it to
         * the send queue
         */

        if (msg->addr == TOS_LOCAL_ADDRESS)
        {	
            if (TOS_LOCAL_ADDRESS == bsId )
            {
                /* The packet is destined to this node (BS)
                 * send it to the application layer
                 */
                signal Receive.receive[id](msg);
            }
            else 
            {
                // Add to the queue
                call Send.send[id](parentId, msg->length,msg); 
            }
        }

        /* You should add the packet to the queue before you recalculate
         * parameters
         */
        
        calcParameters(neighIndex);
        if (TOS_LOCAL_ADDRESS != bsId)
            /* calcParameters can be called any number of
             * time (its freq. does not affect anything). We
             * call it here so that
             * congestion information get propogated with
             * the next packet that is sent out 
             */
        {
            checkQueue();
            IFRCRules();
        }
        else 
            /* Keep the information at the BS as updated as
             * possible
             */
        {
            bsIFRCRules();
        }


        neighTable[neighIndex].neighTransition = FALSE;
        neighTable[neighIndex].neighCongChildTransition = FALSE;

        return msg; 
    }


    default event TOS_MsgPtr Receive.receive[uint8_t id](TOS_MsgPtr msg)
    {
        return msg;
    }


    /* Based on the latest information calculates the value
     * of all the parameters rParent, rNeighMin,
     * neighCongestion,  rCongChildMin
     */

    void calcParameters(int8_t neighIndex) 
    {
        uint32_t congChildRLocal;
        uint32_t congNeighRLocal;
        uint32_t bsOldChildMaxRLocal;

        if(congChildIndex == -1)
            congChildRLocal = INFINITY;
        else
            congChildRLocal = neighTable[congChildIndex].neighRLocal;

        if(congNeighIndex == -1)
            congNeighRLocal = INFINITY;
        else
        {
            /* The warning for congNeighRLocal is ok. It will get assigned a
             * value */
            if(congNeighOrNeighChild == NEIGH) 
                congNeighRLocal = neighTable[congNeighIndex].neighRLocal;
            else if(congNeighOrNeighChild == NEIGHCHILD) 
                congNeighRLocal = neighTable[congNeighIndex].neighCongChildRLocal;
        }

        if(bsChildMaxRLocalIndex == -1)
            bsOldChildMaxRLocal = 0;
        else
            bsOldChildMaxRLocal = neighTable[bsChildMaxRLocalIndex].neighRLocal;

        if (neighTable[neighIndex].type == PARENT)
        {
            atomic 
            {
                parentRLocal = neighTable[neighIndex].neighRLocal;
                parentRThresh = neighTable[neighIndex].neighRThresh;
                parentMode = neighTable[neighIndex].neighMode;
                parentSSThresh = neighTable[neighIndex].neighSSThresh;
            }
        }
        else if (neighTable[neighIndex].type == CHILD)
        {
            if(neighTable[neighIndex].neighMode != START &&
                    neighTable[neighIndex].neighMode != AI)
            {
                if(congChildRLocal > neighTable[neighIndex].neighRLocal)
                    congChildIndex = neighIndex;
            }

            // For Base station node finding the child with max rLocal
            if(neighTable[neighIndex].neighRLocal > bsOldChildMaxRLocal)
            {
                bsOldChildMaxRLocal = neighTable[neighIndex].neighRLocal;
                bsChildMaxRLocalIndex = neighIndex;
            }


        }

        if(neighTable[neighIndex].neighMode != START &&
                neighTable[neighIndex].neighMode != AI)
            if(congNeighRLocal > neighTable[neighIndex].neighRLocal)
            {
                congNeighIndex =  neighIndex;
                congNeighOrNeighChild = NEIGH;
            }

        if(neighTable[neighIndex].neighCongChildMode != START &&
                neighTable[neighIndex].neighCongChildMode != AI)
            if(congNeighRLocal > neighTable[neighIndex].neighCongChildRLocal)
            {
                congNeighIndex =  neighIndex;
                congNeighOrNeighChild = NEIGHCHILD;
            }
        return;

    }

    void IFRCRules()
    {
        uint32_t jitter;

#ifdef LOG_RLOCAL
        uint32_t lastRLocal = rLocal;
#endif
        /* RULE 1: Make sure your rate is not greater than the rate of any
         * "congested" potential interferer.
         */
        if ( congNeighIndex != -1 )
        {
            if ( (congNeighOrNeighChild == NEIGH && neighTable[congNeighIndex].neighTransition &&
                        neighTable[congNeighIndex].neighRLocal < rLocal))

            {
                 /* Your neigbor is congested */
                rLocal = neighTable[congNeighIndex].neighRLocal;
                rThresh = neighTable[congNeighIndex].neighRThresh;
                decLastCycle = TRUE;
                if(mode == START)
                {
                    ssThresh = neighTable[congNeighIndex].neighSSThresh;
                    rLocal = SSVALUE + 12; // a hack
                }
#ifdef LOG_RLOCAL
                sendRLocal(FALSE,change(rLocal,lastRLocal));
#endif
            }
            else if( (congNeighOrNeighChild == NEIGHCHILD &&
                        neighTable[congNeighIndex].neighCongChildTransition &&
                        neighTable[congNeighIndex].neighCongChildRLocal < rLocal) )
            {
                /* Child of your neighbor is congested */
                rLocal = neighTable[congNeighIndex].neighCongChildRLocal;
                rThresh = neighTable[congNeighIndex].neighCongChildRThresh;
                decLastCycle = TRUE;
                /* We don't need to set ssThresh as the operating point is 
                 * now known and we shall not be going into SS again 
                 */
                if(mode == START)
                {
                    ssThresh = neighTable[congNeighIndex].neighSSThresh;
                    rLocal = SSVALUE + 13; // a hack
                }
#ifdef LOG_RLOCAL
                sendRLocal(FALSE,change(rLocal,lastRLocal));
#endif
            }

        }

        /* RULE 2: your rate should be less than the rate of your parent */
        if(parentMode != START && rLocal > parentRLocal )
        {
            rLocal = parentRLocal;
            rThresh = parentRThresh;
            decLastCycle = TRUE;
            if(mode == START)
            {
                /* This isn't fully correct need to look into this */ 
                /* Consider the scenario where the parent started with a high
                 * ssthresh and the operation point of the system changed due to
                 * heavy traffic. The ssThresh of the parent does not reflects
                 * the current operation point */
                ssThresh = parentSSThresh;
                rLocal = SSVALUE + 14; // a hack
            }
                //mode = AI;

#ifdef LOG_RLOCAL
            sendRLocal(FALSE,change(rLocal,lastRLocal));
#endif
        }

        /* In case of congestion collapse the parent may go in the slow start
         * mode.
         */
        if(parentMode == START && rLocal > parentRLocal )
        {
            rLocal = parentRLocal;
            mode = START;
            ssThresh = parentSSThresh;
#ifndef FIXRATE
            call SendTimer.stop();
            // Add random jitter
            jitter = ((call Random.rand() & 0xA) * SSVALUE)/10;
            call SendTimer.start(TIMER_ONE_SHOT,calTimerVal(rLocal + jitter));
#endif
#ifdef LOG_RLOCAL
                sendRLocal(FALSE,change(rLocal,lastRLocal));
#endif
        }


        if(rLocal <= SSVALUE && mode != START)
        {
            rLocal = SSVALUE;
            mode = START;
            ssThresh = BANDWIDTH;
        }


        return;
    }



    /********************************************** 
     * Code for Base Station follows.
     **********************************************/
   
    command result_t setBS(uint16_t id)
    {
        bsId = id;

        if(TOS_LOCAL_ADDRESS == bsId)
        {
            rLocal = BANDWIDTH; 
            parentRLocal = rLocal;
            bsChildMaxRLocalIndex = -1;
            bsChildMaxRLocal = DEFAULT_CHILDMAX * RESOLUTION ; // 1 packets per sec
            lastBSBeaconPeriod = RESOLUTION ;
            lastBSBeaconPeriod *= 1000;
            lastBSBeaconPeriod *= BEACONFACTOR;
            lastBSBeaconPeriod /= bsChildMaxRLocal ; // time is ms
            /* For Debugging*/
            beaconCount = 0;
        }
        /* Control packet from BS are prioritized by the Queueing module */
        call QueueControl.setBS(id);
        return SUCCESS;
    }





    event result_t BeaconTimer.fired()
    {
#ifdef LOG_RLOCAL
        uint32_t lastRLocal = rLocal;
#endif

        if(bsChildMaxRLocalIndex == -1 )
            bsChildMaxRLocal = DEFAULT_CHILDMAX * RESOLUTION;
        else
            bsChildMaxRLocal = neighTable[bsChildMaxRLocalIndex].neighRLocal;
        
        incrementBSRLocal(lastBSBeaconPeriod);
        sendBeacon(1);
        call BeaconTimer.start(TIMER_ONE_SHOT,calTimerVal(bsChildMaxRLocal/BEACONFACTOR));
        lastBSBeaconPeriod = calTimerVal(bsChildMaxRLocal/BEACONFACTOR);

#ifdef LOG_RLOCAL
        sendRLocal(FALSE, change(rLocal,lastRLocal));
#endif
        return SUCCESS;

    }


    void incrementBSRLocal(uint32_t beaconPeriod)
    {
        /* beaconPeriod is in ms */

        uint32_t increment;

        if(mode == AI)
        {

            /* Base station goes twice as fast as others */
            /* Slope of the curve is 2*delta */
            /* increment == 2*delta * t(lastBSBeaconPeriod) */
            increment = 2;
            increment *= rThresh;
            increment *= (rThresh/EPSILON);

            if (increment > RESOLUTION)
            {
                increment /= RESOLUTION;
                increment *= beaconPeriod;
                increment /= 1000;
            }
            else 
            {
                increment *= beaconPeriod;
                increment /= RESOLUTION;
                increment /= 1000;
            }

            /* increase the value atleast by 0.001 */
            if (increment < (RESOLUTION/1000) )
                increment = RESOLUTION/1000;

            rLocal += increment;

            if (rLocal > BANDWIDTH)
                rLocal = BANDWIDTH;

        }
        else if (mode == START)
            rLocal = BANDWIDTH;
        
        parentRLocal = rLocal; 
        return;

    }

    
    void sendBeacon(int count)
    {
        uint32_t i;

        MsgHdr *mptr = (MsgHdr *) &(fwdMsgBuffer.data);
        // Send beacon messages.
        for (i=0; i<count; i++)
        {
            mptr->seqNo = beaconCount++; // for debugging.
#ifndef FIXRATE
            call SendMsg.send[AM_BSBEACON](TOS_BCAST_ADDR, sizeof(MsgHdr),&fwdMsgBuffer);
#endif
        }
        return;
    }


    void bsIFRCRules()
    {

#ifdef LOG_RLOCAL
        uint32_t lastRLocal = rLocal;
#endif 

        if ( congChildIndex != -1 && neighTable[congChildIndex].neighTransition && 
                neighTable[congChildIndex].neighRLocal < rLocal)
        {
            rLocal = neighTable[congChildIndex].neighRLocal;
            rThresh = neighTable[congChildIndex].neighRThresh;
            parentRLocal = rLocal; 
            // We may want to send a packet here
            // Congestion information should be spread as quickly as possible.
            sendBeacon(2);

            if(rLocal <= SSVALUE)
                mode = START;
            else 
            {
                mode = AI;
                ssThresh = rLocal;
            }

#ifdef LOG_RLOCAL
            sendRLocal(FALSE,change(rLocal,lastRLocal));
            lastRLocal = rLocal;
#endif
            // Idea is to to increase the rLocal of the BS and send that too. 
            incrementBSRLocal(calTimerVal(rLocal));
            sendBeacon(2);
            call BeaconTimer.stop();
            call BeaconTimer.start(TIMER_ONE_SHOT,calTimerVal(rLocal));
            lastBSBeaconPeriod = calTimerVal(rLocal);

#ifdef LOG_RLOCAL
            sendRLocal(FALSE,change(rLocal,lastRLocal));
#endif
        }
    }

/*** Code for Base Station Ends here ****/

/*
 * *************************
 * Utility Functions      *
 * ************************
 */
    
    /* Under high traffic I saw MAC layer CRC failing */
    /* CRC function is same as in TCP */
    /* Make sure (sizeof(MsgHdr) - sizeof(mptr->tCRC) is even */
    uint16_t computeTCRC(MsgHdr *mptr)
    {
        uint8_t i;
        uint16_t word;

        uint32_t crc = 0;
        char *msgdata = (char*) mptr;
        for (i=0; i<(sizeof(MsgHdr) - sizeof(mptr->tCRC)); i=i+2)
        {
            word = ((msgdata[i] << 8) & 0xff00) + (msgdata[i+1] & 0x00ff);
            crc += (unsigned long) word;
        }
        crc = ~crc;
        return (uint16_t) crc;
    }


    /* Takes the value of rLocal, rParent etc and returns
     * the time period for the timer in msec */
    uint32_t calTimerVal(uint32_t rate)
    {
        uint32_t timerVal; 

#ifndef FIXRATE
        // Not sure if this should still be present. 
        // Ideally rate should never drop below SSVALUE
        if(rate < SSVALUE) 
            return 10000; // 10 sec
#endif

        timerVal = RESOLUTION;
        timerVal *= 1000; // because time need to be in ms
        timerVal /= rate; 

        return timerVal; 
    }

    /* returns abs(uint32_t - uint32_t) */
    uint32_t change(uint32_t v1 , uint32_t v2)
    {
        if (v1 > v2)
            return (v1 - v2);
        else 
            return (v2 - v1);
    }



/* *********************************************************
 * Logging code follows
 * *********************************************************
 */


#ifdef LOG_SOME 
    event result_t LogMsg.sendDone(TOS_MsgPtr m, result_t success)
    {
        return SUCCESS;
    }
#endif 
    
#ifdef LOG_NEIGH
    void sendNInfo()
    {
        uint8_t i, logNeighIndex = 0; 
        logPacket *logNeigh = (logPacket *) &logNeighMsg.data;
        nmemset((void *)logNeigh,0,DATA_LENGTH);
        logNeigh->type = NEIGHINFO;

        for(i = 0 ; i < MAX_NEIGH ; i++)
            if(neighTable[i].type != INVALID)
            {
                logNeigh->info.neigh[logNeighIndex].neighId =  neighTable[i].neighId;
                logNeigh->info.neigh[logNeighIndex].type =  neighTable[i].type;
                logNeigh->info.neigh[logNeighIndex].mode =  neighTable[i].neighMode;
                logNeigh->info.neigh[logNeighIndex++].rNeigh =  neighTable[i].neighRLocal;
                if (logNeighIndex >= (DATA_LENGTH - 2)/sizeof(logNeigh->info.neigh[0]))
                {
                    logNeigh->size = logNeighIndex;
                    call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logNeighMsg);
                    logNeighIndex = 0;
                    // This line causes some weird problem
                   // nmemset((void *)logNeigh,0,DATA_LENGTH);
                }
            }

        if(logNeighIndex != 0)
        {
            logNeigh->size = logNeighIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logNeighMsg);
            logNeighIndex = 0;
            
            //nmemset((void *)logNeigh,0,DATA_LENGTH);
        }

        return;

    }

    event result_t LogNInfoTimer.fired()
    {
        sendNInfo();
        return SUCCESS; 
    }

    
#endif

    
#ifdef LOG_LINKLOSS
    event result_t LogLinkLossTimer.fired()
    {
        uint8_t i, logLinkLossIndex = 0; 
        logPacket *logLinkLoss = (logPacket *) &logLinkLossMsg.data;
        nmemset((void *)logLinkLoss,0,DATA_LENGTH);
        logLinkLoss->type = LINKLOSSRATE;

        for(i = 0 ; i < MAX_NEIGH ; i++)
        {
            if(neighTable[i].type != INVALID  &&  (neighTable[i].packCount > 0 ))
            {
                // lqi is the loss rate on the link just reusing the struct definition
                logLinkLoss->info.linkLoss[logLinkLossIndex].nodeId =  neighTable[i].neighId;
                logLinkLoss->info.linkLoss[logLinkLossIndex].packetLoss =  neighTable[i].packLoss;
                logLinkLoss->info.linkLoss[logLinkLossIndex++].packetCount =  neighTable[i].packCount;
                if (logLinkLossIndex >= (DATA_LENGTH - 2)/sizeof(logLinkLoss->info.linkLoss[0]))
                {
                    logLinkLoss->size = logLinkLossIndex;
                    call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logLinkLossMsg);
                    logLinkLossIndex = 0;
               //     nmemset((void *)logLinkLoss,0,DATA_LENGTH);
                }


            }
            neighTable[i].packLoss = 0; 
            neighTable[i].packCount = 0; 
        }

        // Add current node information 
        logLinkLoss->info.linkLoss[logLinkLossIndex].nodeId = TOS_LOCAL_ADDRESS;
        logLinkLoss->info.linkLoss[logLinkLossIndex].packetLoss =  0;
        logLinkLoss->info.linkLoss[logLinkLossIndex++].packetCount = (fwdSeqNo - lastSeqNo);
        lastSeqNo = fwdSeqNo;

        if(logLinkLossIndex != 0)
        {
            logLinkLoss->size = logLinkLossIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logLinkLossMsg);
            logLinkLossIndex = 0;
            //nmemset((void *)logLinkLoss,0,DATA_LENGTH);
        }

        return SUCCESS; 
    }
#endif


#ifdef LOG_RLOCAL
    void sendRLocal(bool sendImmediate, uint32_t increment)
    {
        logPacket *logRLocal = (logPacket *) &logRLocalMsg.data; 
        logRLocal->type = RLOCAL;
        logRLocal->info.rLocal[logRLocalIndex].increment = increment;
        logRLocal->info.rLocal[logRLocalIndex].rThreshold = rThresh;
        logRLocal->info.rLocal[logRLocalIndex].ssThresh = ssThresh;
        logRLocal->info.rLocal[logRLocalIndex++].rLocal = rLocal;
        if (logRLocalIndex >= (DATA_LENGTH - 2)/sizeof(logRLocal->info.rLocal[0]) || sendImmediate)
        {
            logRLocal->size = logRLocalIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logRLocalMsg);
            atomic logRLocalIndex = 0;
        }

        return;
    }

#endif 

#ifdef LOG_PACKLOSS
    void sendPackLoss(uint16_t originId, uint16_t seqNo, uint8_t qSize, uint8_t
            cause)
    {
        logPacket *logPackLoss = (logPacket *) &logPackLossMsg.data; 
        logPackLoss->type = PACKLOSS;
        logPackLoss->info.packLoss[logPackLossIndex].originId = originId;
        logPackLoss->info.packLoss[logPackLossIndex].seqNo = seqNo;

        logPackLoss->info.packLoss[logPackLossIndex].qSize = qSize;
        logPackLoss->info.packLoss[logPackLossIndex++].cause = cause;

        if(logPackLossIndex >= (DATA_LENGTH - 2)/sizeof(logPackLoss->info.packLoss[0]))
        {
            logPackLoss->size = logPackLossIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logPackLossMsg);
            atomic logPackLossIndex = 0 ;
        }

    }
#endif


#ifdef LOG_LATENCY
    void sendLatency(uint16_t originId, uint16_t seqNo, bool status)
    {
        logPacket *logPackIns = (logPacket *) &logPackInsMsg.data; 
        logPackIns->type = PACKINS;
        logPackIns->size = 1;
        logPackIns->info.packIns.nodeId = originId;
        logPackIns->info.packIns.seqNo = seqNo;
        logPackIns->info.packIns.status = SEND;
        call LogMsg.send(TOS_UART_ADDR,LOGHEADER + sizeof(logPackIns->info.packIns),&logPackInsMsg);
    }

#endif

#ifdef LOG_LQI
    // LQI value for the link nodeId->TOS_LOCAL_ADDRESS 
    void sendLQI(uint16_t nodeId, uint16_t lqi, bool status)
    {
        logPacket *logLQI = (logPacket *) &logLQIMsg.data;
        logLQI->type = LQI;
        logLQI->info.link[logLQIIndex].nodeId   = nodeId;
        logLQI->info.link[logLQIIndex++].lqi    = lqi;
        if (logLQIIndex >= (DATA_LENGTH - 2)/sizeof(logLQI->info.link[0]))
        {
            logLQI->size = logLQIIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logLQIMsg);
            atomic logLQIIndex = 0;
        }
    }
#endif 


#ifdef LOG_TRANS

    void sendTrans(uint16_t originId, uint16_t seqNo, uint8_t xmitCount, uint8_t
            dropped)
    {
        logPacket *logTrans = (logPacket *) &logTransMsg.data; 
        logTrans->type = TRANS;
        logTrans->info.tInfo[logTransIndex].originId = originId;
        logTrans->info.tInfo[logTransIndex].seqNo = seqNo;
        logTrans->info.tInfo[logTransIndex].xmitCount = xmitCount;
        logTrans->info.tInfo[logTransIndex++].drop = dropped;

        if(logTransIndex >= (DATA_LENGTH - 2)/sizeof(logTrans->info.tInfo[0]))
        {
            logTrans->size = logTransIndex;
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logTransMsg);
            atomic logTransIndex = 0 ;
        }
    }
#endif

#ifdef LOG_INFO 
    void sendInfo(uint8_t *data, uint8_t size)
    {
        logPacket *logInfo = (logPacket *) &logInfoMsg.data; 
        logInfo->type = OTHER ;
        if(size <= (DATA_LENGTH - 2))
        {
            logInfo->size = size;
            memcpy(&logInfoMsg.data[2], data, size); 
            call LogMsg.send(TOS_UART_ADDR,DATA_LENGTH,&logInfoMsg);
        }
        return;
    }

#endif
    
    
    
}

