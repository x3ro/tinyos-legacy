// $Id: NeighborListM.nc,v 1.31 2006/10/03 12:55:53 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis
 * By Chien-Liang Fok.
 *
 * Washington University states that Agilla is free software;
 * you can redistribute it and/or modify it under the terms of
 * the current version of the GNU Lesser General Public License
 * as published by the Free Software Foundation.
 *
 * Agilla is distributed in the hope that it will be useful, but
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS",
 * OR OTHER HARMFUL CODE.
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to
 * indemnify, defend, and hold harmless WU, its employees, officers and
 * agents from any and all claims, costs, or liabilities, including
 * attorneys fees and court costs at both the trial and appellate levels
 * for any loss, damage, or injury caused by your actions or actions of
 * your officers, servants, agents or third parties acting on behalf or
 * under authorization from you, as a result of using Agilla.
 *
 * See the GNU Lesser General Public License for more details, which can
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
includes Agilla;

/**
 * Discovers neighbors using beacons.  Maintains a list of nodes that have
 * recently been heard from.
 *
 * @author Chien-Liang Fok
 * @author Sangeeta Bhattacharya
 */
module NeighborListM {
  provides {
    interface StdControl;
    interface NeighborListI;  
  }
  uses {
    interface Random; // Used for getting a random neighbor

    interface Time;
    interface TimeUtil;

    interface AddressMgrI;

    interface Timer as BeaconTimer;
    interface Timer as DisconnectTimer;

    interface SendMsg as SendBeacon;
    interface ReceiveMsg as RcvBeacon;

    // get neighbor list query
    interface ReceiveMsg       as RcvGetNbrList;
    interface SendMsg          as SendGetNbrList;

    // Response to get neighbor list query
    interface SendMsg          as SendNbrList;
    interface ReceiveMsg       as RcvNbrList;

    // Grid topology
    interface LocationMgrI;
    interface LocationUtilI;

    interface MessageBufferI;

    interface Leds; // debug

    #if ENABLE_EXP_LOGGING
      interface ExpLoggerI;
    #endif
  }
}
implementation {

  #define NO_CLUSTERHEAD -1

  typedef struct Neighbor 
  {
    uint16_t addr;          // The address of the neighbor
    uint16_t hopsToGW;      // The number of hops to the gateway
    tos_time_t timeStamp;   // The last time a beacon was received

    int16_t chId;           // The id of the cluster head of the cluster
                            //   to which the neighbor belongs; if the neighbor
                            //   is a cluster head, then chId = id;
    uint16_t linkQuality;   // The quality of the link to the neighbor
    uint16_t energy;        // The residual energy of the neighbor
  } Neighbor;

  /**
   * An array of neighbor locations and timestamps.
   * nbrs[0] through nbrs[numNbrs] have valid neighbor data.
   */
  Neighbor nbrs[AGILLA_MAX_NUM_NEIGHBORS];
  uint8_t numNbrs;
  uint16_t replyAddr; // used for retrieving the neighbor list

  int16_t _chId;            // id of the cluster head of the cluster to which this node belongs

  /**
   * Generate a random interval between sending beacons.
   * This value will be between BEACON_PERIOD and
   * BEACON_PERIOD + BEACON_RAND.
   */
  inline uint16_t genRand() 
  {
    return (call Random.rand() % BEACON_RAND) + BEACON_PERIOD;;
  }

  /**
   * A message buffer for holding neighbor list info.
   * This is used for debugging purposes.  It allows the
   * user to query a mote's neighbor list.
   */
  //TOS_Msg nbrMsg;
  uint8_t sendCount, nextSendCount; // for sending neighbor info to base station
  
  /**************************************************************/
  /*                    Method declarations                     */
  /**************************************************************/
  
  task void SendNbrListTask();

  /**************************************************************/
  /*                      Helper methods                        */
  /**************************************************************/
  
  /**
   * Returns the number of hops to the gateway.  If no gateway is
   * known, return NO_GW (0xffff).
   */
  /*uint16_t getHopsToGW(uint16_t* addr) 
  {
    if (call AddressMgrI.isGW())  
    {
      *addr == TOS_LOCAL_ADDRESS;
      return 0;
    } else
    {
      uint16_t numHops;    
      numHops = call NeighborListI.getGW(*addr);
      if (*addr != NO_GW)
      {
        numHops++;
        return numHops;      
      } else
        return NO_GW;
    }
  }*/
  
  /**
   * Returns true if the node with the specified id is a grid neighbor.
   */
  result_t isGridNbr(uint16_t id) {
    AgillaLocation nbrLoc, myLoc;
    call LocationMgrI.getLocation(TOS_LOCAL_ADDRESS, &myLoc);
    call LocationMgrI.getLocation(id, &nbrLoc);
    //dbg(DBG_USR1, "NeighborListM: isGridNbr(): myLoc = (%i, %i)\n", myLoc.x, myLoc.y);
    //dbg(DBG_USR1, "NeighborListM: isGridNbr(): nbrLoc = (%i, %i)\n", nbrLoc.x, nbrLoc.y);
    return call LocationUtilI.isGridNbr(&myLoc, &nbrLoc);
  }  
  
  #if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
    void printNbrList()
    {
      uint8_t i;
      dbg(DBG_USR1, "--- Neighbor list ---\n");
      for (i = 0; i < numNbrs; i++) {
        dbg(DBG_USR1, "\t%i:\tID=%i\thopsToGW=%i\n", i, nbrs[i].addr, nbrs[i].hopsToGW);
      }
    }
  #endif

  /**************************************************************/
  /*                     StdControl                             */
  /**************************************************************/
  
  command result_t StdControl.init() {
    numNbrs = 0;
    nextSendCount = 0;
    _chId = NO_CLUSTERHEAD;

    atomic {
      call Random.init();
    };
    dbg(DBG_USR1, "NTIMERS = %i\n", NTIMERS);
    //dbg(DBG_USR1, "uniqueCount(\"Timer\") = %i\n", uniqueCount("Timer"));
    call Leds.init();
    return SUCCESS;
  }

  command result_t StdControl.start() {
    call BeaconTimer.start(TIMER_ONE_SHOT, genRand());
    call DisconnectTimer.start(TIMER_REPEAT, BEACON_TIMEOUT);
    return SUCCESS;
  }

  command result_t StdControl.stop()  {
    return SUCCESS;
  }
  


  /**
   * Send a beacon. Then generate a random time to sleep before sending the next
   * beacon.
   */
  event result_t BeaconTimer.fired()
  {
    TOS_MsgPtr myBeacon = call MessageBufferI.getMsg();    
    if (myBeacon != NULL)
    {
      AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)myBeacon->data;
      uint16_t nbrToGW;
      
      bmsg->id = TOS_LOCAL_ADDRESS;

      // Determine the number of hops to the base station
      /*if (call AddressMgrI.isGW())
        bmsg->hopsToGW = 0;
      else
      {
        uint16_t addr;
        bmsg->hopsToGW = call NeighborListI.getGW(&addr);
        if (bmsg->hopsToGW != NO_GW)
        {
          bmsg->hopsToGW++;  // add one hop to get to the neighbor
        }
      }*/
      bmsg->hopsToGW = call NeighborListI.getGW(&nbrToGW);
      if (bmsg->hopsToGW != NO_GW && !call AddressMgrI.isGW()) bmsg->hopsToGW++;     // increment hop count to include hop to this node
      bmsg->chId = _chId;
      bmsg->energy = 0;      

      #if DEBUG_NEIGHBORLIST
        dbg(DBG_USR1, "NeighborListM: Send Beacon ID=%i, hopsToGW=%i, chID=%i, energy=%i\n", 
          bmsg->id, bmsg->hopsToGW, bmsg->chId, bmsg->energy);
      #endif

      if (!call SendBeacon.send(TOS_BCAST_ADDR, sizeof(AgillaBeaconMsg), myBeacon))
      {
        dbg(DBG_USR1, "NeighborListM: ERROR: Unable to send beacon.\n");
        call MessageBufferI.freeMsg(myBeacon);
      }
    }
    return call BeaconTimer.start(TIMER_ONE_SHOT, genRand());
  }

  event result_t SendBeacon.sendDone(TOS_MsgPtr m, result_t success)
  {
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }

  /**
   * Check for neighbors whom we have not heard beacons from recently
   * and remove them from the neighbor list.
   */
  event result_t DisconnectTimer.fired() {
    int16_t i,j;
    tos_time_t currTime = call Time.get();

//    #if DEBUG_NEIGHBORLIST
//      dbg(DBG_USR1, "NeighborListM: DisconnectTimer.fired(): The current time is %i %i\n",
//        currTime.high32, currTime.low32);
//    #endif

    atomic {
      for (i = 0; i < numNbrs; i++) {
        tos_time_t delta = call TimeUtil.subtract(currTime, nbrs[i].timeStamp);
        tos_time_t maxAge;

//        dbg(DBG_USR1, "NeighborListM: Checking neighbor %i, timestamp = %i %i\n",
//          nbrs[i].addr, nbrs[i].timeStamp.low32, nbrs[i].timeStamp.high32);

        maxAge.high32 = 0;
        maxAge.low32 = BEACON_TIMEOUT;

//        #if DEBUG_NEIGHBORLIST
//          dbg(DBG_USR1, "NeighborListM: DisconnectTimer.fired(): neighor %i, curr = %i %i, timestamp = %i %i, delta = %i %i, maxAge = %i %i\n",
//            nbrs[i].addr, currTime.high32, currTime.low32, nbrs[i].timeStamp.high32, nbrs[i].timeStamp.low32,
//            delta.high32, delta.low32, maxAge.high32, maxAge.low32);
//        #endif

        if (call TimeUtil.compare(delta, maxAge) > 0) 
        {
          #if DEBUG_NEIGHBORLIST
            dbg(DBG_USR1, "NeighborListM: DisconnectTimer.fired(): ----- Neighbor %i has left!\n",
              nbrs[i].addr);
          #endif
          #if NBR_LIST_PRINT_CHANGES
            dbg(DBG_USR1, "NeighborListM: Neighbor %i has left!\n", nbrs[i].addr);
            printNbrList();
          #endif

          for (j = i; j < numNbrs-1; j++) {  // remove the neighbor by shifting all of the following neighbors forward
            nbrs[j] = nbrs[j+1];
          }
          numNbrs--;
          i--;
        }
      }
    }
    return SUCCESS;
  }  // DisconnectTimer.fired()



  /**
   * Whenever a beacon is recieved, timestamp and store it in the
   * neighbor list (or update the timestamp if it is already in the
   * list.
   */
  event TOS_MsgPtr RcvBeacon.receive(TOS_MsgPtr m) {
    AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)m->data;
    int16_t i = 0, indx = -1; // the index of the location
    tos_time_t now = call Time.get();

    #if DEBUG_NEIGHBORLIST
      dbg(DBG_USR1, "NeighborListM: processBeacon(): ID = %i, hopsToGW = %i\n", bmsg->id, bmsg->hopsToGW);
    #endif

    #if ENABLE_NEIGHBOR_LIST_FILTER
      // Reject beacons if it comes from a node that is not a grid neighbor.
      if (!isGridNbr(bmsg->id))
      {
        #if DEBUG_NEIGHBORLIST
          dbg(DBG_USR1, "NeighborListM: processBeacon(): Not from grid neighbor, discarding...\n");
        #endif
        return m;
      }
    #endif

    // Check whether the neighbor is already in the list.  If so,
    // set indx equal to its position in the list, otherwise, set
    // indx = -1.
    while (i < numNbrs && indx == -1) {
      if (nbrs[i].addr == bmsg->id)
        indx = i;
      i++;
    }

    // If the beacon is NOT in the neighbor list, insert it.
    if (indx == -1 && numNbrs < AGILLA_MAX_NUM_NEIGHBORS)
    {
      indx = numNbrs++;
      nbrs[indx].addr = bmsg->id;

      #if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
        dbg(DBG_USR1, "NeighborListM: NEW NEIGHBOR: %i\n", bmsg->id);
      #endif
    } else if(numNbrs >= AGILLA_MAX_NUM_NEIGHBORS)
    {
        dbg(DBG_USR1, "NeighborListM: Error! Failed to insert neighbor: neighbor list maximum reached!\n");
        return m;
    }

    if (indx != -1)  // if the neighbor is in the list...
    {
      // Update the timestamp and number of hops to the base station.     
      nbrs[indx].hopsToGW = bmsg->hopsToGW;      
      nbrs[indx].timeStamp = now;
      nbrs[indx].chId = bmsg->chId;
      nbrs[indx].energy = bmsg->energy;
      //nbrs[indx].linkQuality = m->lqi;
      
//      #if DEBUG_NEIGHBORLIST
//        dbg(DBG_USR1, "BeaconBasedFinderM: processBeacon(): Timestamp of neighbor %i updated to %i %i\n",
//          nbrs[indx].addr, nbrs[indx].timeStamp.high32, nbrs[indx].timeStamp.low32);
//      #endif

    }  // end if the neighbor is in the list
    
    #if NBR_LIST_PRINT_CHANGES || DEBUG_NEIGHBORLIST
     printNbrList();
    #endif

    return m;
  } // event TOS_MsgPtr RcvBeacon.receive(...)

  /**
   * Checks whether this node has a neighbor with the specified address.
   *
   * @return SUCCESS if the specified location is a neighbor.
   */
  command result_t NeighborListI.isNeighbor(uint16_t addr)
  {
    int i;
    if (addr == TOS_UART_ADDR)
      return call AddressMgrI.isGW();
    for (i=0; i < numNbrs; i++) {
      if (nbrs[i].addr == addr)
        return SUCCESS;
    }
    return FAIL;
  }

  /**
   * Returns the number of neighbors.
   */
  command uint16_t NeighborListI.numNeighbors()
  {
    return numNbrs;
  }

  /**
   * Sets the specified AgillaLocation to be the ith
   * neighbor.  Returns SUCCESS if such a neighbor exists, and
   * FALSE otherwise.
   */
  command result_t NeighborListI.getNeighbor(uint16_t i, uint16_t* addr)
  {
    if (i < numNbrs)
    {
      *addr = nbrs[i].addr;
      return SUCCESS;
    } else
      return FAIL;
  }

  /**
   * Sets the specified location equal to the location of a randomly chosen
   * neighbor.  If no neighbors exist, return FAIL.
   */
  command result_t NeighborListI.getRandomNeighbor(uint16_t* addr) {
    if (numNbrs == 0)
      return FAIL;
    else {
      uint16_t rval = call Random.rand();
      *addr = nbrs[rval % numNbrs].addr;
      return SUCCESS;
    }
  }

  /**
   * Retrieves the address of the closest gateway, or neighbor closest
   * to the gateway.  If no gateway or neighbor is close to a gateway,
   * return FAIL.  Otherwise, the address is stored in the parameter.
   *
   * @param addr The neighbor that is closest to the gateway. 
   * @return The number of hops that the neighbor is from the gateway, or NO_GW (0xffff) if no
   * gateway is known.
   */
  command uint16_t NeighborListI.getGW(uint16_t* addr)
  {    
    if (call AddressMgrI.isGW())
    {
      *addr = TOS_LOCAL_ADDRESS;
      return 0;  // zero hops to GW
    }
    else
    {
      int i;
      uint16_t closest = NO_GW;
      for (i = 0; i < numNbrs; i++)
      {
        if(nbrs[i].hopsToGW < closest)
        {
          *addr = nbrs[i].addr;
          closest = nbrs[i].hopsToGW;
        }
      }
      return closest;
    }
  } // NeighborListI.getGW()


  //-------------------------------------------------------------------
  // Allow user to query a node's neighbor list.
  //

  /**
   * The user has queried this mote's neighbor list.
   */
  event TOS_MsgPtr RcvGetNbrList.receive(TOS_MsgPtr m)
  {
    AgillaGetNbrMsg* gnm = (AgillaGetNbrMsg*)m->data;

    if (call AddressMgrI.isOrigAddress(gnm->destAddr))
    {
      //call Leds.redToggle();
      sendCount = 0;
      replyAddr = gnm->replyAddr;
      post SendNbrListTask();
      #if NBR_LIST_PRINT_CHANGES
        dbg(DBG_USR1, "NeighborListM: User has queried neighbor list!\n");
        printNbrList();
      #endif
    }
    else
    {
      // The gateway re-broadcasts the message.  Note that a broadcast
      // must be used since it is delivered to a node based on it's *original*
      // address (not its current address).
      if (call AddressMgrI.isGW())
      {
        TOS_MsgPtr nbrMsg = call MessageBufferI.getMsg();
        if (nbrMsg != NULL)
        {
          // Save this node's address as the reply-to address so it can forward
          // the results back to the base station.
          gnm->replyAddr = TOS_LOCAL_ADDRESS;
          *nbrMsg = *m;
          if (!call SendGetNbrList.send(TOS_BCAST_ADDR, sizeof(AgillaGetNbrMsg), nbrMsg))
          {
            dbg(DBG_USR1, "NeighborListM: ERROR: Could not forward GetNbrList message.\n");
            call MessageBufferI.freeMsg(nbrMsg);
          }
        } else
        {
          dbg(DBG_USR1, "NeighborListM: ERROR: Could not get buffer for GetNbrList message.\n");
        }
      }
    }
    return m;
  } // event RcvGetNbrList


  event result_t SendGetNbrList.sendDone(TOS_MsgPtr m, result_t success)
  {
    call MessageBufferI.freeMsg(m);
    return SUCCESS;
  }

  /**
   * Send the neighbor list back to the base station.
   */
  task void SendNbrListTask()
  {
    TOS_MsgPtr nbrMsg = call MessageBufferI.getMsg();
    if (nbrMsg != NULL)
    {
      AgillaNbrMsg* nMsg = (AgillaNbrMsg *)nbrMsg->data;
      int i;

      nextSendCount = sendCount;

      // fill the message with the neighbor information
      for (i = 0; i < AGILLA_NBR_MSG_SIZE && nextSendCount < numNbrs; i++)
      {
        nMsg->nbr[i] = nbrs[nextSendCount].addr;
        nMsg->hopsToGW[i] = nbrs[nextSendCount].hopsToGW;
        nMsg->lqi[i] = 0;
        nextSendCount++;
      }

      // fill remainder of msg
      for (; i < AGILLA_NBR_MSG_SIZE; i++)
      {
        nMsg->nbr[i] = TOS_BCAST_ADDR;
      }

      if (replyAddr == TOS_LOCAL_ADDRESS || replyAddr == TOS_UART_ADDR)
      {
        if (call AddressMgrI.isGW())
        {
          if (!call SendNbrList.send(TOS_UART_ADDR, sizeof(AgillaNbrMsg), nbrMsg)) {
            call MessageBufferI.freeMsg(nbrMsg);
            post SendNbrListTask();
          }
        }
      }
      else
      {
        if (!call SendNbrList.send(replyAddr, sizeof(AgillaNbrMsg), nbrMsg))
        {
          call MessageBufferI.freeMsg(nbrMsg);
          post SendNbrListTask();
        }
      }
    }
  }

  event result_t SendNbrList.sendDone(TOS_MsgPtr m, result_t success)
  {
    call MessageBufferI.freeMsg(m);
    if (nextSendCount != 0)
    {
      if (success)
        sendCount = nextSendCount;  // proceed to next message
      if (sendCount < numNbrs)
        post SendNbrListTask();
      else
        nextSendCount = 0;
    }
    return SUCCESS;
  }

  /**
   * If this is the gateway, forward the neighbor list message to the
   * base station.
   */
  event TOS_MsgPtr RcvNbrList.receive(TOS_MsgPtr m)
  {
    if (call AddressMgrI.isGW())
    {
      TOS_MsgPtr nbrMsg = call MessageBufferI.getMsg();
      *nbrMsg = *m;
      call SendNbrList.send(TOS_UART_ADDR, sizeof(AgillaNbrMsg), nbrMsg);
    }
    return m;
  }


  #if ENABLE_GRID_ROUTING
    /**
     * Takes two TinyOS addresses, converts them to locations (assumes grid topology)
     * and calculates the distance between the two locations.
     */
    uint16_t dist(uint16_t addr1, uint16_t addr2)
    {
      AgillaLocation loc1, loc2;
      call LocationMgrI.getLocation(addr1, &loc1);
      call LocationMgrI.getLocation(addr2, &loc2);
      return call LocationUtilI.dist(&loc1, &loc2);
    }

    /**
     * Fetches the address of the closest neighbor to which an agent
     * should be forwarded do.  Saves the results in the location
     * specified by the nbr parameter.
     *
     * @return SUCCESS if a neighbor was found.
     */
    command result_t NeighborListI.getClosestNeighbor(uint16_t *nbr)
    {
      // If the destination is the serial port
      if (*nbr == TOS_UART_ADDR)
      {
        if (call AddressMgrI.isGW())
          return SUCCESS;
        else
          return (call NeighborListI.getGW(nbr) != NO_GW);
      }

      // If the destination is broadcast
      else if (*nbr == TOS_BCAST_ADDR)
        return SUCCESS;

      // If the destination is the local node
      else if (*nbr == TOS_LOCAL_ADDRESS)
        return SUCCESS;

      // If I have no neighbors, FAIL
      else if (numNbrs == 0)
      {
        #ifdef DEBUG_NEIGHBORLIST
          dbg(DBG_USR1, "NeighborListI: ERROR: No neighbors\n");
        #endif
        return FAIL;
      }

      // If the destination is a possible neighbor, but the neighbor has
      // not been heard from, assume it doesn't exist.
      else if (isGridNbr(*nbr) && !call NeighborListI.isNeighbor(*nbr))
      {
        dbg(DBG_USR1, "NeighborListM: ERROR: Grid Neighbor %i not present.\n", *nbr);

        return FAIL;
      }

      // Find the closest neighbor
      else
      {
        uint16_t i, cDist, cPos;

        #ifdef DEBUG_NEIGHBORLIST
          dbg(DBG_USR1, "NeighborListI: GetClosestNeighbor: Finding closest neighbor, numNbrs = %i...\n", numNbrs);
        #endif

        cPos = 0;
        cDist = dist(*nbr, nbrs[cPos].addr);

        for (i = 1; i < numNbrs; i++)
        {
          uint16_t d = dist(*nbr, nbrs[i].addr);

          #ifdef DEBUG_NEIGHBORLIST
            dbg(DBG_USR1, "NeighborListI: GetClosestNeighbor: Checking neighbor %i (dist = %i)...\n", nbrs[i].addr, d);
          #endif

          if (d < cDist)
          {
            cDist = d;
            cPos = i;
          }
        }
        *nbr = nbrs[cPos].addr;
        return SUCCESS;
      }
    }
  #endif /* ENABLE_GRID_ROUTING */
}
