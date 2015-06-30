
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
 * Authors:          Gilman Tolle
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



/* External Parameters 
 *   - PTHRESH - Should parent thresholding be used 
 *             If yes a parent is selected only when lqi to 
 *             the parent is > PARENTTHRESH and number control 
 *             packets heard from the parent > PCOUNT
 *   - FIXROUTE - User hardcoded routes 
 *               route need to be given in this file in the array rTable
 *   - BS_ADDRESS
 */

/*
 * With CONG_CONTROL defined the code will try to find the parent(either using
 * Link quality Threshold if PTHRESH is defined or the first available path to
 * the base station) and sticks to the parent for life. 
 * If FIXROUTE is defined the parent is set to as specified in
 * rTable[TOS_LOCAL_ADDRESS] after PCOUNT packets each with  lqi >
 * PARENTTHRESHOLD are received.
 */

#ifdef CONG_CONTROL
#undef  MHOP_HISTORY_SIZE
#define MHOP_HISTORY_SIZE 1 
#endif 

includes MultiHop;

module MultiHopLQI {

    provides {
        interface StdControl;
        interface RouteSelect;
        interface RouteControl;
    }

    uses {
        interface Timer;

        interface SendMsg;
        interface ReceiveMsg;

        interface Random;

#ifndef CONG_CONTROL
        interface RouteStats;
#endif


        interface Leds;
    }
}

implementation {

    enum {
#if defined(CONG_CONTROL) 
        BASE_STATION_ADDRESS = BS_ADDRESS,
#else 
        BASE_STATION_ADDRESS = 0,
#endif
        BEACON_PERIOD        = 4,
        BEACON_TIMEOUT       = 8,
    };

    enum {
        ROUTE_INVALID    = 0xff
    };


    TOS_Msg msgBuf;
    bool msgBufBusy;

    uint16_t gbCurrentParent;
    uint16_t gbCurrentParentCost;
    uint16_t gbCurrentLinkEst;
    uint8_t  gbCurrentHopCount;
    uint16_t gbCurrentCost;

    uint8_t gLastHeard;

    int16_t gCurrentSeqNo;

    uint16_t gUpdateInterval;

    uint8_t gRecentIndex;
    uint16_t gRecentPacketSender[MHOP_HISTORY_SIZE];
    int16_t gRecentPacketSeqNo[MHOP_HISTORY_SIZE];

    uint8_t gRecentOriginIndex;
    uint16_t gRecentOriginPacketSender[MHOP_HISTORY_SIZE];
    int16_t gRecentOriginPacketSeqNo[MHOP_HISTORY_SIZE];

#ifdef PTHRESH
    uint8_t pCount[MAX_NODES];
    bool changeOk;
#endif

    uint16_t adjustLQI(uint8_t val) {
        uint16_t result = (80 - (val - 50));
        result = (((result * result) >> 3) * result) >> 3;
        return result;
    }

    task void SendRouteTask() {
        TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *) &msgBuf.data[0];
        BeaconMsg *pRP = (BeaconMsg *)&pMHMsg->data[0];
        uint8_t length = offsetof(TOS_MHopMsg,data) + sizeof(BeaconMsg);


        dbg(DBG_ROUTE,"MultiHopRSSI Sending route update msg.\n");

        if (gbCurrentParent != TOS_BCAST_ADDR) {
            dbg(DBG_ROUTE,"MultiHopRSSI: Parent = %d\n", gbCurrentParent);
        }

        if (msgBufBusy) {
#ifndef PLATFORM_PC
            post SendRouteTask();
#endif
            return;
        }

        dbg(DBG_ROUTE,"MultiHopRSSI: Current cost: %d.\n", 
                gbCurrentParentCost + gbCurrentLinkEst);

        pRP->parent = gbCurrentParent;
        pRP->cost = gbCurrentParentCost + gbCurrentLinkEst;
        pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
        pRP->hopcount = gbCurrentHopCount;
        pMHMsg->hopcount = gbCurrentHopCount;
        pMHMsg->originseqno = gCurrentSeqNo;
        pMHMsg->seqno = gCurrentSeqNo++;

        if (call SendMsg.send(TOS_BCAST_ADDR, length, &msgBuf) == SUCCESS) {
            atomic msgBufBusy = TRUE;
            call Leds.yellowToggle();
        }
        else 
            call Leds.redToggle();


        return;

    }

    task void TimerTask() {
        uint8_t val;

        // May need a #define here. We should make sure once the parent
        // is set gbCurrentParent isn't changed. 
#ifdef CONG_CONTROL
        if (gbCurrentParent == TOS_BCAST_ADDR) {
#endif
            atomic val = ++gLastHeard;
            if ((TOS_LOCAL_ADDRESS != BASE_STATION_ADDRESS) && (val > BEACON_TIMEOUT)) {
                gbCurrentParent = TOS_BCAST_ADDR;
                gbCurrentParentCost = 0x7fff;
                gbCurrentLinkEst = 0x7fff;
                gbCurrentHopCount = ROUTE_INVALID;
                gbCurrentCost = 0xfffe;
            }

#ifdef CONG_CONTROL
        }
#endif


#ifdef CONG_CONTROL
        if(!msgBufBusy)
#endif
            post SendRouteTask();
    }

    command result_t StdControl.init() {
        int n;

        gRecentIndex = 0;
        for (n = 0; n < MHOP_HISTORY_SIZE; n++) {
            gRecentPacketSender[n] = TOS_BCAST_ADDR;
            gRecentPacketSeqNo[n] = 0;
        }

        gRecentOriginIndex = 0;
        for (n = 0; n < MHOP_HISTORY_SIZE; n++) {
            gRecentOriginPacketSender[n] = TOS_BCAST_ADDR;
            gRecentOriginPacketSeqNo[n] = 0;
        }

        gbCurrentParent = TOS_BCAST_ADDR;
        gbCurrentParentCost = 0x7fff;
        gbCurrentLinkEst = 0x7fff;
        gbCurrentHopCount = ROUTE_INVALID;
        gbCurrentCost = 0xfffe;

        gCurrentSeqNo = 0;
        gUpdateInterval = BEACON_PERIOD;
        atomic msgBufBusy = FALSE;

        if (TOS_LOCAL_ADDRESS == BASE_STATION_ADDRESS) {
            gbCurrentParent = TOS_UART_ADDR;
            gbCurrentParentCost = 0;
            gbCurrentLinkEst = 0;
            gbCurrentHopCount = 0;
            gbCurrentCost = 0;
        }

#ifdef CONG_CONTROL
        call Random.init();
#ifdef PTHRESH
        for (n=0; n<MAX_NODES; n++)
            pCount[n] = 0 ;
#endif
        changeOk = TRUE;
#endif 
        call Leds.init();
        return SUCCESS;
    }

    command result_t StdControl.start() {
        gLastHeard = 0;
        call Timer.start(TIMER_ONE_SHOT, 
                call Random.rand() % (1024 * gUpdateInterval));
        return SUCCESS;
    }

    command result_t StdControl.stop() {
        call Timer.stop();
        return SUCCESS;
    }

    command bool RouteSelect.isActive() {
        return TRUE;
    }

    command result_t RouteSelect.selectRoute(TOS_MsgPtr Msg, uint8_t id, 
            uint8_t resend) {
        int i;
        TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

        //    if (gbCurrentParent != TOS_UART_ADDR && resend == 0) {
        if (pMHMsg->originaddr != TOS_LOCAL_ADDRESS && resend == 0) {
            // supress duplicate packets
            for (i = 0; i < MHOP_HISTORY_SIZE; i++) {
                if ((gRecentPacketSender[i] == pMHMsg->sourceaddr) &&
                        (gRecentPacketSeqNo[i] == pMHMsg->seqno)) {
                    return FAIL;
                }
            }

            gRecentPacketSender[gRecentIndex] = pMHMsg->sourceaddr;
            gRecentPacketSeqNo[gRecentIndex] = pMHMsg->seqno;
            gRecentIndex = (gRecentIndex + 1) % MHOP_HISTORY_SIZE;

            // supress multihop cycles and try to break out of it
            for (i = 0; i < MHOP_HISTORY_SIZE; i++) {
                if ((gRecentOriginPacketSender[i] == pMHMsg->originaddr) &&
                        (gRecentOriginPacketSeqNo[i] == pMHMsg->originseqno)) {
                    gbCurrentParentCost = 0x7fff;
                    gbCurrentLinkEst = 0x7fff;
                    gbCurrentParent = TOS_BCAST_ADDR;
                    gbCurrentHopCount = ROUTE_INVALID;
                    return FAIL;
                }
            }
            gRecentOriginPacketSender[gRecentOriginIndex] = pMHMsg->originaddr;
            gRecentOriginPacketSeqNo[gRecentOriginIndex] = pMHMsg->originseqno;
            gRecentOriginIndex = (gRecentOriginIndex + 1) % MHOP_HISTORY_SIZE;
        }

        if (gbCurrentParent != TOS_UART_ADDR && resend == 0) {
            pMHMsg->seqno = gCurrentSeqNo++;
        }
        pMHMsg->sourceaddr = TOS_LOCAL_ADDRESS;
        Msg->addr = gbCurrentParent;

        return SUCCESS;
    }

    command result_t RouteSelect.initializeFields(TOS_MsgPtr Msg, uint8_t id) {
        TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];

        pMHMsg->sourceaddr = pMHMsg->originaddr = TOS_LOCAL_ADDRESS;
        pMHMsg->originseqno = gCurrentSeqNo;
        pMHMsg->hopcount = gbCurrentHopCount;

        return SUCCESS;
    }

    command uint8_t* RouteSelect.getBuffer(TOS_MsgPtr Msg, uint16_t* Len) {

    }

    command uint16_t RouteControl.getParent() {
        return gbCurrentParent;
    }

    /* In case we need to manually set the parent we use this 
     * function to do so.
     */
#ifdef CONG_CONTROL 

    command void RouteControl.startChange()
    {
        changeOk = TRUE; 
        return;
    }
    command void RouteControl.stopChange()
    {
        changeOk = FALSE; 
        return;
    }

    command void RouteControl.breakLoop()
    {
        gbCurrentParentCost = 0x7fff;
        gbCurrentLinkEst = 0x7fff;
        gbCurrentParent = TOS_BCAST_ADDR;
        gbCurrentHopCount = ROUTE_INVALID;
        return;
    }
    
#endif

    command uint8_t RouteControl.getQuality() {
        return gbCurrentLinkEst;
    }

    command uint8_t RouteControl.getDepth() {
        return gbCurrentHopCount;
    }

    command uint8_t RouteControl.getOccupancy() {
        return 0;
    }

    command uint16_t RouteControl.getSender(TOS_MsgPtr msg) {
        TOS_MHopMsg		*pMHMsg = (TOS_MHopMsg *)msg->data;
        return pMHMsg->sourceaddr;
    }

    command result_t RouteControl.setUpdateInterval(uint16_t Interval) {

        gUpdateInterval = Interval;
        return SUCCESS;
    }

    command result_t RouteControl.manualUpdate() {
        post SendRouteTask();
        return SUCCESS;
    }


    event result_t Timer.fired() {
        post TimerTask();
        call Leds.greenToggle();
#ifdef CONG_CONTROL
        call Timer.start(TIMER_ONE_SHOT,  2 + call Random.rand() %(1024 * (gUpdateInterval-2)));
#else
        call Timer.start(TIMER_ONE_SHOT, 1024 * gUpdateInterval + 1);
#endif
        return SUCCESS;
    }

    
    /* This is the core of the module */
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr Msg) {


        TOS_MHopMsg *pMHMsg = (TOS_MHopMsg *)&Msg->data[0];
        BeaconMsg *pRP = (BeaconMsg *)&pMHMsg->data[0];

#ifdef FIXROUTE
        /* We are hardcoding the tree */

//        uint16_t rTable[] = {
//            255,255,1,2,1,3,1,3,1,13,9,1,1,8,8,13,13,16,16,16,15,17,19,15,23,23,19,25,26,17,17,32,17,30,33,33,34,35,36,37,37,34,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255};


        /* Tree for ssThresh experiment */
//        uint16_t rTable[] = {
//            255,255,1,9,3,1,2,2,1,1,1,9,9,9,12,13,13,13,15,15,15,17,19,19,22,22,19,22,26,15,29,29,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255};

        /* Node 9-39, bs 9 */
        uint16_t rTable[] = {
            255,255,255,255,255,255,255,255,255,255,9,9,9,9,12,13,13,13,15,15,15,16,19,18,23,23,19,26,26,15,20,20,20,30,33,33,33,33,33,34,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
                };
        

#endif

        /* if the message is from my parent
           store the new link estimation */

        if (pMHMsg->sourceaddr == gbCurrentParent) {
            // try to prevent cycles
            if (pRP->parent != TOS_LOCAL_ADDRESS) {
                gLastHeard = 0;
                gbCurrentParentCost = pRP->cost;
                gbCurrentLinkEst = adjustLQI(Msg->lqi);
                gbCurrentHopCount = pRP->hopcount + 1;
            }
            else {
                gLastHeard = 0;
                gbCurrentParentCost = 0x7fff;
                gbCurrentLinkEst = 0x7fff;
                gbCurrentParent = TOS_BCAST_ADDR;
                gbCurrentHopCount = ROUTE_INVALID;
            }

        } else {

            /* if the message is not from my parent, 
               compare the message's cost + link estimate to my current cost,
               switch if necessary */

            // make sure you don't pick a parent that creates a cycle

#ifdef FIXROUTE
            if(pMHMsg->sourceaddr == rTable[TOS_LOCAL_ADDRESS])
            {

                gLastHeard = 0;
                gbCurrentParent = pMHMsg->sourceaddr;
                gbCurrentParentCost = pRP->cost;
                gbCurrentLinkEst = adjustLQI(Msg->lqi);	
                gbCurrentHopCount = pRP->hopcount + 1;
            }

#else

            if(Msg->lqi > PARENTTHRESH)
                pCount[pMHMsg->sourceaddr]++;
            else 
                pCount[pMHMsg->sourceaddr] =  pCount[pMHMsg->sourceaddr]?  pCount[pMHMsg->sourceaddr] - 1 : 0;

            if (     ( (uint32_t) pRP->cost + (uint32_t) adjustLQI(Msg->lqi) 
                      < ((uint32_t) gbCurrentParentCost + (uint32_t) gbCurrentLinkEst) 
                      - (((uint32_t) gbCurrentParentCost + (uint32_t) gbCurrentLinkEst) >> 2)) &&
                    (pRP->parent != TOS_LOCAL_ADDRESS)) 
            {

                if (Msg->lqi > PARENTTHRESH && pCount[pMHMsg->sourceaddr] >= PCOUNT  && changeOk)
                {
                    gLastHeard = 0;
                    gbCurrentParent = pMHMsg->sourceaddr;
                    gbCurrentParentCost = pRP->cost;
                    gbCurrentLinkEst = adjustLQI(Msg->lqi);	
                    gbCurrentHopCount = pRP->hopcount + 1;

                    pCount[pMHMsg->sourceaddr] = 0;
                }
            }
#endif

        }

        return Msg;
    }

    event result_t SendMsg.sendDone(TOS_MsgPtr pMsg, result_t success) {
        atomic msgBufBusy = FALSE;
        return SUCCESS;
    }



    }

