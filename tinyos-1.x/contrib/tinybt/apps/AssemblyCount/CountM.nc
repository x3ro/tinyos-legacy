/*
  Count (and other commands) program that utilizes the Assembly
  interface and component.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include "debug.h"

#define debug(a) call Debug.debug(a)
#define ledson() debug(15)
#define ledsoff() debug(0)


// #define COUNT_CHATTER
// TODO: These does not work anyway. Change them to queryConnection?
#ifdef COUNT_CHATTER
#define chat(X) call Assembly.sendUp(X)
#else
#define chat(X)
#endif

#define fail(X) call Assembly.sendUp(X)
#define info(X) call Assembly.sendUp(X)

/** 
 * Assembly interface based count program.
 * 
 * <p>This component can answer a query that counts the number of
 * nodes in the network. The approach is very basic and is only meant
 * as a proof-of-concept. Only a single query/command at a time is
 * supported.</p>
 *
 * <p>To test this program, download the program to a number of nodes,
 * then turn on a Bluetooth interface on your PC and make it inq'able
 * and open for connections. Then turn on the nodes. They will form a
 * network with the PC as the Bluetooth root. You can now issue a
 * command be sending a node an ACL packet with the command as the
 * payload encoded in ascii. (A patch against hcitool is supplied that
 * provides an acl command, and you can use the perl program
 * <code>texttohex.pl</code> to encode ascii to the hex values it
 * expects.)</p>
 *
 * <p>If you do not have an inq'able Bluetooth device running, the
 * nodes will try for approximately 30 seconds, then they will become
 * masters in their own networks. So, simply turn a single node on,
 * wait for 30 seconds, then turn on the others. You can now perform
 * an inquery on the PC and connect (as slave - this requires the PC
 * Bluetooth interface to support role switching) to any child
 * interface and issue commands over this interface.</p>
 *
 * <p>Supported commands are 
 * <ul>
 * <li>l - Leds off</li>
 * <li>L - Leds on</li>
 * <li>t - Talk two lines</li>
 * <li>T - Talk four lines</li>
 * <li>s - Return the structure of the network</li>
 * <li>mx - The lowest first byte of the local address</li>
 * <li>Mx - The highest first byte of the local address</li>
 * <li>cx - Count the number of nodes (that respond)</li>
 * </ul>
 * where x is the number of periods the query maximally can
 * use. Because each level in the connection tree uses an interval, the
 * number should be at least the depth of the tree.</p>
 *
 * <p>For the commands l, L, t and T, no packets are returned.</p>
 *
 * <p>For the s command, a packet on the form "Rsxy" is returned for
 * each node, where x is the first byte in the senders local address,
 * and y is the first byte of the local address of the parent of the
 * running query.</p>
 * 
 * <p>The m and M commands return the minimum, respectively maximum,
 * of the first byte of the local addresses, on the form Rmx or
 * RMx.</p>
 * 
 * <p>The cx command returns the number of nodes that responded, in a
 * packet of the form Rcx, where x is the ascii value of the number
 * (0-9 only).</p> */
module CountM {
  provides {
    interface StdControl;
  }
  uses {
    interface AssemblyI as Assembly;
    interface LedDebugI as Debug;
    /* Shouldn't be using the Clock, I know, but hey... */
    interface Clock as Clock;
  }
}

implementation {
  /** Pointer to our local bdaddr */
  bdaddr_t * address;

  /** How many times we have tried to join a network. */
  uint8_t tryJoinCount;

  /** Mostly to keep sure that we are internally consistent. */
  uint8_t numConnections;

  /** Used to determine what query is ongoing. */
  char query;

  /** Used during queries as a "parent" connection pointer - NULL, when no query 
      is ongoing. */
  connectionId * queryConnection;
  /** Used to keep track of the number of clock fire events left in the current query. */
  int clockFireEventsLeft;

  /** Used during a query phase. */
  uint8_t queryResult;

  /* Test */
  /** Used to store incoming connection information in. */
  hci_acl_data_pkt * incomingPkt;

  /** Initialize.  
   *
   * <p>Sets the tryJoinCount, numConnections and queryConnection
   * pointer, clears the incomingConnection and incomingPkt.</p> */
  command result_t StdControl.init() {
    tryJoinCount       = 3;
    numConnections     = 0;
    atomic { 
      queryConnection    = NULL; 
      incomingPkt        = NULL; 
    }
    return SUCCESS;
  }

  /** Empty start. */
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /** Empty stop. */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /**
   * Ready callback.
   *
   * <p>The assembly layer issues this event when it is ready to
   * function. The default response is to try and join an existing
   * network.</p> */
  event void Assembly.ready(bdaddr_t * localAddress) {
    address = localAddress;
    call Assembly.join();
  }

  /**
   * joinTimeout callback.
   *
   * <p>This is issued when the join procedure have been running for a 
   * while unsuccesfull.</p>
   * 
   * <p>The response is to try a number of times, then start a new network
   * by itself.</p> */
  event void Assembly.joinTimeout() {
    if (tryJoinCount > 0) {
      call Assembly.join();
      --tryJoinCount;
    } else {
      call Assembly.assemble();
    }
  }

  /**
   * Callback for new connections.
   *
   * <p>Simply increase the connection count.</p>
   *
   * @param connection Pointer to the new connection */
  event void Assembly.newConnection(connectionId * connection) {
    numConnections++;
  }

  /**
   * Callback for disconnections.
   *
   * <p>Decrease the connection count. If 0 is reached, a new join
   * procedure is started. If the connection that was lost is the
   * current query connection, stop the query.</p>
   *
   * <p>TODO: Only if we are not our own network do we want to try and
   * join.... need a way to closeParentConnection or something...</p>
   * 
   * @param connection Pointer to the connection that was lost */
  event void Assembly.disconnection(connectionId * connection) {
    /* This will fail if we are disconnected from our parent, but it
       is debug anyway... */
    chat("CountM.Assembly.disconnection");
    atomic {
      if (connection == queryConnection) {
	queryConnection = NULL;
      }
    }
    --numConnections;
    // TODO: We do not always want to do this...
    if (numConnections == 0) {
      tryJoinCount = 3;
      call Assembly.join();
    }
  }

  /**
   * Task to post the results of the current query.
   *
   * <p>Checks what the current query is, and return a suitable result.</p> */
  task void postResult() {
    /*Check if we have a connection, then if we need to respond or what */
    connectionId tmpqc;
    bool returnflag = FALSE;
    atomic { 
      if (NULL == queryConnection) {
	returnflag = TRUE;
      } else {
	tmpqc = *queryConnection;
      }
    }
    
    if (returnflag) {
      // fail("CountM lost querer");
      return;
    } 
    
    if (query == 'c' || query == 'm' || query == 'M') {
      char * buf = "R__";
      buf[1] = query;
      switch(query) {
      case 'c': {
	buf[2] = queryResult + '0' + 1; // We add one for ourselves...
	break;
      }
      case 'm':
      case 'M': {
	buf[2] = queryResult;
	break;
      }
      }
      call Assembly.postSendString(&tmpqc, buf);
    }
    /* The query is over... */
    atomic { queryConnection = NULL; }
  }

  /** 
   * Handler for the Clock.fire event.
   * 
   * <p>If enough fire events have happened, stop the clock and post
   * postResult. */
  async event result_t Clock.fire() {
    int tmp;
    atomic {
      tmp = clockFireEventsLeft;
      if (tmp > 0) {
	--clockFireEventsLeft;
      }
    }
    /* In a future version atomic may support return */
    if (tmp > 0) {
      return SUCCESS;
    }
    /* OK, the query is done */
    /* Stop the clock */
    call Clock.setRate(TOS_I0PS, TOS_S0PS);
    /* Post a task to notify our parent */
    post postResult();
    return SUCCESS;
  }

  /**
   * Forward a data packet to all our kids.
   * 
   * <p>Called by some commands, duplicates the packet to all, then
   * forwards it. The packet is not consumed or changed, only
   * borrowed.</p>
   *
   * @param pkt The packet to be forwarded
   * @return The number of packets that have been queued for forwarding */
  static int forwardPacketToKids(hci_acl_data_pkt * pkt) {
    /* Send to all children we can find
       Note that we violate the stuff about protecting the array. 
       Hmm - and the numChildren and other stuff... oh well. 
       This really should be protected somehow. */
    int i;
    int count = 0;
    connectionId * connections = call Assembly.getConnections();
    connectionId * tmpqc;
    // Note: It is not necc. to check for tmpqc == NULL here...
    atomic { tmpqc = queryConnection; };
    for (i = 0; i < MAX_NUM_CONNECTIONS; ++i) {
      if (connections[i].state == connected 
	  && &(connections[i]) != tmpqc) {
	/* Found one */
	hci_acl_data_pkt * tmp = call Assembly.getBuffer();
	count++;
	/* Copy pkt into tmp
	   This is actually wasteful if we have only a single child */
	pkt_cpy((gen_pkt *) tmp, (gen_pkt *) pkt);

	if (SUCCESS != call Assembly.postSend(&(connections[i]), tmp)) {
	  fail("forward: failed child send");
	  call Assembly.putBuffer(tmp);
	  return count;
	} else {
	  chat("forward: send to child");
	}
      }
    }
    /* Check ... for debug */
    if (count != (numConnections-1)) {
      fail("forward: confused");
    }
    return count;
  }
  

  /** Check a command.
   *
   * <p>Check any commands in the packet, react to it. For most
   * commands this involves forwarding the command to the
   * children.</p>
   * 
   * <p>A valied queryConnection is assumed when calling this
   * function, and a valid value in incomingPkt too.</p> */
  // static void checkCommand(hci_acl_data_pkt * pkt) {
  task void checkCommand() {
    char * tmp;
    hci_acl_data_pkt * pkt;
    debug(DEBUG_APPLICATION_CHECKCOMMAND);
    atomic {
      if (NULL == incomingPkt) {
	FAIL2(FAIL_APPLICATION, FAIL_APPLICATION_CHECKCOMMAND);
      }
      pkt = incomingPkt;
      incomingPkt = NULL;
    }
    
    tmp = ((char *) pkt->start) + sizeof(hci_acl_hdr);
    /* Double check... - this actually only work partially */
    {
      connectionId * tmpqc; 
      atomic { tmpqc = queryConnection; }
      if (tmpqc == NULL) {
	fail("checkCommand : No queryConnection");
	return;
      }
    }

    /* Save the current query type... */
    query = *tmp;
    /* Default time before a query times out */
    atomic {
      clockFireEventsLeft = 2;
    }
    switch (*tmp) {
    case 'R': {
      /* This is a response, that has been delayed and therefore it
	 looks a lot like a new query. Just forget it */
      atomic { queryConnection = NULL; }
      return;
    }
    case 'l': {
      /* Turn the leds off */
      ledsoff();
      break;
    }
    case 'L': {
      /* Turn the leds on */
      ledson();
      break;
    }
    case 't': {
      connectionId * foo;
      connectionId tmpqc;
      atomic { foo = queryConnection; if (NULL != queryConnection) tmpqc = *queryConnection; }
      if (NULL != foo) {
	call Assembly.postSendString(&tmpqc, "t called (a)");
	call Assembly.postSendString(&tmpqc, "t called (b)");
      }
      break;
    }
    case 'T': {
      connectionId * foo;
      connectionId tmpqc;
      atomic { foo = queryConnection; if (NULL != queryConnection) tmpqc = *queryConnection; }
      if (NULL != foo) {
	call Assembly.postSendString(&tmpqc, "T called (a)");
	call Assembly.postSendString(&tmpqc, "T called (b)");
	call Assembly.postSendString(&tmpqc, "T called (c)");
	call Assembly.postSendString(&tmpqc, "T called (d)");
      }
      break;
    }
    case 's': { /* Structure can respond immidiately */
      bool ok = TRUE;
      connectionId tmpqc;
      char * buf = "Rs__";
      atomic { 
	if (NULL == queryConnection) {
	  ok = FALSE;
	} else {
	  tmpqc = *queryConnection;
	  buf[2] = *((uint8_t *) address);
	  buf[3] = *((uint8_t *) &(queryConnection->bdaddr));
	}
      }
      if (ok) {
	call Assembly.postSendString(&tmpqc, buf);
      }
      break;
    }
      /* The commands that uses the clock */
    case 'c':
    case 'm':
    case 'M': {
      /* Get the clockFireEventsLeft set up right */
      if (pkt->start->dlen != 2) {
	fail("Malformed query");
	call Assembly.putBuffer(pkt);
	return;
      } else {
	uint8_t tmp1 = *(tmp + 1) - '0'; /* clockFireEvents are in ascii */
	atomic {
	  clockFireEventsLeft = tmp1;
	}
	--tmp1;
	/* Changes the packet - prepare to forward it. */
	*(tmp + 1) = tmp1 + '0';
      } /* Wellformed packet */
      
      /* **********************************************************************
       * Inner command switch... 
       * *********************************************************************/
      switch (*tmp) {
      case 'c': {
	int mytmp;
	atomic { mytmp = clockFireEventsLeft; }
	if (numConnections <= 1 || mytmp == 0) {
	  /* If we have no more than 1 connection, it is probably the querier that
	     we are connected to - if we have no time, just post. */
	  connectionId tmpqc;
	  bool ok = TRUE;
	  atomic { 
	    if (NULL == queryConnection) {
	      ok = FALSE;
	    } else {
	      tmpqc = *queryConnection;
	    }
	  }
	  if (ok) {
	    call Assembly.postSendString(&tmpqc, "Rc1");
	  }
	  /* The query is complete - we are not starting the clock */
	  atomic { queryConnection = NULL; }
	  call Assembly.putBuffer(pkt);
	  return;
	} else {
	  queryResult = 0;
	}
	break;
      } 	
      case 'm':
      case 'M': {
	int mytmp;
	connectionId tmpqc;
	bool ok = TRUE;
	atomic { 
	  mytmp = clockFireEventsLeft; 
	  if (NULL == queryConnection) { 
	    ok = FALSE;
	  } else {
	    tmpqc = *queryConnection;
	  }
	}
	if (ok && numConnections <= 1 || mytmp == 0) {
	  char * buf = "R__";
	  /* If we have no more than 1 connection, it is probably the querier that
	     we are connected to - if we have no time, just post. */
	  buf[1] = query;
	  buf[2] = *((uint8_t *) address);
	  call Assembly.postSendString(&tmpqc, buf);
	  /* The query is complete - we are not starting the clock */
	  atomic { queryConnection = NULL; }
	  call Assembly.putBuffer(pkt);
	  return;
	} else {
	  queryResult = *((uint8_t *) address);
	}
	break;
	
      } /* m, M */
      } /* Inner switch (on c, m, M)*/
      
    } /* c, m, M */
    } /* Switch on command  */
    
    /* Set up the clock to make sure the query is terminated */
    call Clock.setRate(TOS_I4PS, TOS_S4PS);
    /* Forward the (possibly modified) packet */
    forwardPacketToKids(pkt);
    call Assembly.putBuffer(pkt);
  } /* Check command */
  


  /** Check a packet from our children.
   *
   * <p>Checks for the different types of queries that needs aggregating, 
   * and adjust the values stored accordingly.</p>
   * 
   * <p>A valid incomingPkt and queryConnection are assumed for this function 
   * to work.</p> */
  // static hci_acl_data_pkt * checkChildPacket(hci_acl_data_pkt * pkt) {
  task void checkChildPacket() {
    char * tmp;
    hci_acl_data_pkt * pkt;

    debug(DEBUG_APPLICATION_CHECKCHILDPACKET);
    atomic {
      if (NULL == incomingPkt) {
	FAIL2(FAIL_APPLICATION, FAIL_APPLICATION_CHECKCHILDPACKET);
      }
      pkt = incomingPkt;
      incomingPkt = NULL;
    }

    tmp = ((char *) pkt->start) + sizeof(hci_acl_hdr) + 1;
    /* We can not really do anything, if no queryConnection ... 
       we could wait for a new, but why bother? */
    {
      bool returnflag = FALSE;
      atomic { 
	if (queryConnection == NULL) {
	  returnflag = TRUE;
	}
      }
      if (returnflag) {
	call Assembly.putBuffer(pkt);
	return;
      }
    }
    /* Check that this a result */
    if ('R' != *(tmp-1)) {
      debug(DEBUG_APPLICATION_NORESPONSEPACKET);
      call Assembly.putBuffer(pkt);
      return;
    }

    /* Check if it is any of the aggregating queries */
    switch (*(tmp)) {
      /* They have a lot in common, these guys */
    case 'c':
    case 'm':
    case 'M': {
      uint8_t tmp1 = *(tmp + 1);
      if (pkt->start->dlen != 3) {
	fail("malformed child packet");
	break;
      }
      switch(*tmp) {
      case 'c': {
	queryResult += (tmp1 - '0');
	call Assembly.putBuffer(pkt);
	return;
      }
      case 'm': {
	if (tmp1 < queryResult) {
	  queryResult = tmp1;
	}
	call Assembly.putBuffer(pkt);
	return;
      }
      case 'M': {
	if (tmp1 > queryResult) {
	  queryResult = tmp1;
	}
	call Assembly.putBuffer(pkt);
	return;
      }
      } /* Inner switch */
    } /* c, m, M */
    } /* Outer switch */

    /* If reaching here, forward packet to queryConnection */
    {
      connectionId tmpqc;
      bool ok = TRUE;
      atomic { 
	if (NULL == queryConnection) {
	  ok = FALSE; 
	} else { 
	  tmpqc = *queryConnection; 
	}
      }

      if (!ok) {
	debug(DEBUG_APPLICATION_NOQUERYCONNECTION);
	call Assembly.putBuffer(pkt);
	return;
      }
      
      
      if (SUCCESS != call Assembly.postSend(&tmpqc, pkt)) {
	// fail("C.A.recv: failed parent send");
	call Assembly.putBuffer(pkt);
      } 
    }
  }

  /**
   * Callback for receiving data.
   *
   * <p>Data from the first connection (parent) is send to
   * <code>checkCommand</code>. Packets from any other (children) is
   * sent to <code>checkChildPacket</code>.</p>
   *
   * @param connection The connection the data arrived on
   * @param pkt The actual data
   * @return An unused packet */
  async event hci_acl_data_pkt * Assembly.recv(connectionId * connection, hci_acl_data_pkt * pkt) {
    debug(DEBUG_APPLICATION_1);

    /* Check if we got the info from our "parent" */
    if (connection == NULL) {
      FAIL2(FAIL_APPLICATION, FAIL_APPLICATION_NULLCONNECTION);
      /* fail("C.A.r: null connection");
	 return pkt; */
    }

    /* Store the packet temporary here */
    atomic {
      if (incomingPkt != NULL) {
	FAIL2(FAIL_APPLICATION, FAIL_APPLICATION_OVERRUN);
      }
      incomingPkt = pkt;
    }
    /* If connection == queryConnection, we are already doing a query, but
       something could be wrong here... a chance to reset... 
       This logic does not work when a child sends data from the Assembly layer, e.g. a
       connection message or similar. */
    atomic {
      if (queryConnection == NULL || connection == queryConnection) { 
	/* No current query or more stuff from queryOwner - this is one */
	queryConnection = connection;
	post checkCommand();
      } else { /* connection != firstConnection */
	/* Stuff from a child. A sweet innocent child. *sob* */
	post checkChildPacket();
      }
    }
    return call Assembly.getBuffer();
  }

}


