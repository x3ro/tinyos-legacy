/*
 * This component recursively sends route requests and the corresponding replies
 * to maintain a tree routing table.  A route broadcast is generated under
 * the following conditions:
 * - Periodically after the component has been started
 * - In response to a ROUTING_QUERY_ADJACENT_NODES message from a master node
 * - In response to the RouteRequest command
 *
 * When a node generates a route broadcast it sends a
 * ROUTING_QUERY_ADJACENT_NODES to each of its descendants.  Each descendant
 * replies with a ROUTING_REPLY_ADJACENT_NODES message with its own ID as the
 * destination, its own ID as the next hop, and a hop count of 0 from the next
 * node.
 *
 * When a node receives a REPLY_ADJACENT_NODES message it updates its own
 * routing table to the destination nodes and relays that message to its master
 * node, inserting itself as the next hop and increasing the hop count by 1.
 * If this node is unable to send the relayed message it buffers the packets
 * and retries up to RETRY_ATTEMPTS times
 *
 * The format of each message type is:
 * Payload[0:3]                  Payload[4:*]
 * ROUTING_QUERY_ADJACENT_NODES  Requesting node ID, Last Node, # hops from
 *                               last node
 * ROUTING_REPLY_ADJACENT_NODES  Requesting node ID, Next Node, # hops from
 *                               next node, Destination node ID
 *
 */



module TreeRoutingM
{
  provides {
    interface StdControl as Control;
    interface Routing;
    event result_t InvalidDest(uint32 Dest);
  }

  uses {
    interface Timer;
    interface StdControl as WDControl;
    interface WDTControl;
    interface NetworkPacket;
    interface NetworkTopology;
    interface LowPower;
    interface StatsLogger;

    command result_t NetworkDiscoveryActive(bool DiscoveryActive);
  }
}



implementation
{

#define TRACE_DEBUG_LEVEL DBG_USR2

  enum {ROUTING_QUERY_ADJACENT_NODES = 1,
        ROUTING_REPLY_ADJACENT_NODES,
        ROUTING_BEACON,
        ROUTING_INVALIDATE_ROUTE};

  //#define ROUTE_BEACON_INTERVAL 120000  // 12s period for sending route requests
  //#define LOW_POWER_BEACON_INTERVAL 300000  // in low power, period = 60 seconds

#if 0	// LN : slower beacons & resets
  #define ROUTE_BEACON_INTERVAL 12000  // 12s period for sending route requests
  #define LOW_POWER_BEACON_INTERVAL 60000  // in low power, period = 60 seconds
#else
  #define ROUTE_BEACON_INTERVAL 60000  // 12s period for sending route requests
  #define LOW_POWER_BEACON_INTERVAL 120000  // in low power, period = 60 seconds
  
#endif

  #define MAX_CONNECTIONS       12
  #define MAX_QUEUED_MESSAGES   10
  #define MAX_NETWORK_SIZE      32

  typedef struct tRoutingMessage {
    uint32 Command;
    uint32 RequestingNode;      // originator of this message
    uint32 LastNode;            // last node on the path from the source node
    uint32 Hops;                // hops from source to LastNode
    uint32 DestinationNode;
  } tRoutingMessage;

  tRoutingMessage QueuedMessages[MAX_QUEUED_MESSAGES];
  int MessageHead;     // index of the oldest entry in the Message FIFO
  int MessageTail;     // index of the next entry to fill in the Message FIFO
  // (MessageHead == MessageTail) => FIFO is empty

  uint32 ThisNodeID;

  #define REPLY_LENGTH 20
  #define QUERY_LENGTH 16
  #define BEACON_LENGTH 16

  int    TimeSinceLastMessage;

  #define NO_ROUTE_MESSAGE_TIMEOUT 4 // number of beacon intervals without
                                      // receiving a message before resetting
                          

  int   NoRouteMessageTimeout;


  /*
   * Query a specific node and its sub-tree for routing information.
   */

  void QueryNode(uint32 Requestor, uint32 Node, uint32 Hops) {
    char    *buffer;
    uint32  *t;

    buffer = call NetworkPacket.AllocateBuffer(QUERY_LENGTH);
    if (buffer == NULL) return;

    t = (uint32 *) buffer;
    t[0] = (uint32) ROUTING_QUERY_ADJACENT_NODES;
    t[1] = Requestor;
    t[2] = ThisNodeID;
    t[3] = Hops;
    if (call NetworkPacket.Send(Node, buffer, QUERY_LENGTH) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
      return;
    }
  }



  void BeaconNeighbors(uint32 Requestor, uint32 LastNode, uint32 Hops) {
    char    *buffer;
    uint32  *t;
    uint32  NeighborList[MAX_CONNECTIONS];
    int     i, NumNeighbor;

    call NetworkTopology.Get1HopDestinations( MAX_CONNECTIONS, &NumNeighbor, 
                                              &(NeighborList[0]));

    for (i = 0; i < NumNeighbor; i++) {
      if ((NeighborList[i] != LastNode) && // don't reflect request back
          (call NetworkTopology.IsPropertySupported(NeighborList[i],
                   NETWORK_PROPERTY_TEMPORARY_CONNECTION) == FALSE)) {
        buffer = call NetworkPacket.AllocateBuffer(BEACON_LENGTH);
        if (buffer == NULL) return;

        t = (uint32 *) buffer;
        t[0] = (uint32) ROUTING_BEACON;
        t[1] = Requestor;
        t[2] = ThisNodeID;
        t[3] = Hops;
        if (call NetworkPacket.Send(NeighborList[i], buffer, BEACON_LENGTH)
              == FAIL) {
          call NetworkPacket.ReleaseBuffer(buffer);
          return;
        }
      }
    }
  }



  void InvalidateRoute(uint32 InvalidNode, uint32 NotifyingNode) {
    uint32 NumDest, DestList[16], i;
    char    *buffer;
    uint32  *t;

    call NetworkTopology.Get1HopDestinations(16, &NumDest, &(DestList[0]));

    for (i = 0; i < NumDest; i++) {
      // signal master that route to node is invalid
    //  if (call NetworkTopology.IsASlave(DestList[i])) { 
      if ((DestList[i] != NotifyingNode) && // don't send invalidate message
                                            // back to sender
           (call NetworkTopology.IsPropertySupported(DestList[i],
            NETWORK_PROPERTY_TEMPORARY_CONNECTION) == FALSE)) {
        buffer = call NetworkPacket.AllocateBuffer(8);
        if (buffer == NULL) return;

        t = (uint32 *) buffer;
        t[0] = (uint32) ROUTING_INVALIDATE_ROUTE;
        t[1] = InvalidNode;
        if (call NetworkPacket.Send(DestList[i], buffer, 8) == FAIL) {
          call NetworkPacket.ReleaseBuffer(buffer);
          return;
        }
      }
    //  }
    }
    signal Routing.RouteDisconnected(InvalidNode);
  }



  /*
   * Query all of this node's children for routing information.  Requestor is
   * the original requestor of the routing information, Hops is the hop count
   * from this node to the Requestor node.
   */
  void QueryNeighbors (uint32 Requestor, uint32 LastNode, uint32 Hops) {

    uint32  NeighborList[MAX_CONNECTIONS];
    int     i, NumNeighbor;


    call NetworkTopology.Get1HopDestinations( MAX_CONNECTIONS, &NumNeighbor, 
                                              &(NeighborList[0]));

    for (i = 0; i < NumNeighbor; i++) {
      if ((NeighborList[i] != LastNode) && // don't reflect request back
          (call NetworkTopology.IsPropertySupported(NeighborList[i],
                   NETWORK_PROPERTY_TEMPORARY_CONNECTION) == FALSE)) {
        QueryNode(Requestor, NeighborList[i], Hops);
      }
    }
  }



  task void SendRouteBeacon() {

    uint32 i, NumNodes, Nodes[8];

    call NetworkTopology.GetNodeID(&ThisNodeID);

#if 0 // VEH force disconnect if not linked to display
    if ((call NetworkTopology.IsPropertySupported(ThisNodeID,
               NETWORK_PROPERTY_ACTIVE_ROUTING) == TRUE) ||
       (call NetworkTopology.IsASlave(0xFFFFFFFF) == FALSE)) {
      QueryNeighbors (ThisNodeID, ThisNodeID, 0);
    }
#endif
    if ((call NetworkTopology.GetNumRTEntries() >= MAX_NETWORK_SIZE)) {
      BeaconNeighbors (ThisNodeID, ThisNodeID, 0);
      call NetworkDiscoveryActive(FALSE);
    } else {
      if (call NetworkTopology.IsPropertySupported(ThisNodeID,
                 NETWORK_PROPERTY_ACTIVE_ROUTING) == TRUE) {
        QueryNeighbors (ThisNodeID, ThisNodeID, 0);
      }
      call NetworkDiscoveryActive(TRUE);
    }

    // Get network properties for any nodes which still have
    //  NETWORK_PROPERTY_NULL

    NumNodes = call NetworkTopology.GetNodesSupportingProperty(
                  NETWORK_PROPERTY_NULL, 8, &(Nodes[0]));

    for (i = 0; i < NumNodes; i++) {
      // trigger another request to get network properties
      signal Routing.NewNetworkRoute(Nodes[i]);
    }
  }



  void SendReply(uint32 Requestor, uint32 NextNode) {
    char    *buffer;
    uint32  *t;

    buffer = call NetworkPacket.AllocateBuffer(REPLY_LENGTH);
    if (buffer == NULL) return;

    t = (uint32 *) buffer;
    t[0] = (uint32) ROUTING_REPLY_ADJACENT_NODES;
    t[1] = Requestor;
    t[2] = ThisNodeID;
    t[3] = 0;
    t[4] = ThisNodeID;
    if (call NetworkPacket.Send(NextNode, buffer, REPLY_LENGTH) == FAIL) {
      call NetworkPacket.ReleaseBuffer(buffer);
      return;
    }
  }



  void RelayReply( tRoutingMessage *Message ) {
    char    *buffer;
    uint32  *t;
    uint32  NextNode;

    buffer = call NetworkPacket.AllocateBuffer(REPLY_LENGTH);
    if (buffer == NULL) return;

    t = (uint32 *) buffer;
    t[0] = (uint32) ROUTING_REPLY_ADJACENT_NODES;
    t[1] = Message->RequestingNode;
    t[2] = ThisNodeID;
    t[3] = Message->Hops + 1;
    t[4] = Message->DestinationNode;

    if ((call NetworkTopology.GetNextConnection(Message->RequestingNode,
           &NextNode, NULL) != SUCCESS) ||
        (call NetworkPacket.Send(NextNode, buffer, REPLY_LENGTH) != SUCCESS)) {

      call NetworkPacket.ReleaseBuffer(buffer);

    }
    return;
  }



  command result_t Routing.ConnectNode( uint32 OtherNodeID) {

    if ((call NetworkTopology.AddRoute(OtherNodeID, OtherNodeID, 1))==SUCCESS) {
      QueryNode(ThisNodeID, OtherNodeID, 0);
    }

    // always tell the higher levels when a new connection is made
    signal Routing.NewNetworkRoute(OtherNodeID);

    return SUCCESS;
  }



  command result_t Routing.DisconnectNode ( uint32 OtherNodeID) {

    InvalidateRoute(OtherNodeID, INVALID_NODE);
    
    trace(TRACE_DEBUG_LEVEL,"Removing route to %05X\n\r", OtherNodeID);

    return (call NetworkTopology.RemoveRoute(OtherNodeID));
  }



/*
 * Start of NetworkPacket interface.
 */

  event result_t NetworkPacket.SendDone( char *data) {

    call NetworkPacket.ReleaseBuffer( data );
    call StatsLogger.BumpCounter(NUM_ROUTING_SEND, 1);
    return SUCCESS;

  }




  task void ProcessQueuedMessages() {
    tRoutingMessage *Message;

    while (MessageHead != MessageTail) {
      Message = &(QueuedMessages[MessageHead]);

      switch (Message->Command) {

        case ROUTING_BEACON:
          BeaconNeighbors ( Message->RequestingNode, Message->LastNode,
                           Message->Hops + 1);
          call NetworkDiscoveryActive(FALSE);
          break;

        case ROUTING_QUERY_ADJACENT_NODES:
          // If a new route was created, signal that a new node was found
          if ((call NetworkTopology.AddRoute(Message->RequestingNode,
             Message->LastNode, Message->Hops + 1)) == SUCCESS) {
            signal Routing.NewNetworkRoute(Message->RequestingNode);
          }
          QueryNeighbors ( Message->RequestingNode, Message->LastNode,
                           Message->Hops + 1);
          SendReply(Message->RequestingNode, Message->LastNode);
          call NetworkDiscoveryActive(TRUE);
          break;

        case ROUTING_REPLY_ADJACENT_NODES:
          // If a new route was created, signal that a new node was found
          if ((call NetworkTopology.AddRoute(Message->DestinationNode,
             Message->LastNode, Message->Hops + 1)) == SUCCESS) {

            signal Routing.NewNetworkRoute(Message->DestinationNode);
          }
          if (Message->RequestingNode != ThisNodeID) RelayReply(Message);
          break;

        default:
      }

      MessageHead = (MessageHead == (MAX_QUEUED_MESSAGES - 1) ) ?
                      0 : MessageHead + 1;
    }
    return;
  }


  event result_t NetworkPacket.Receive( uint32 Source, uint8 *Data,
                                        uint16 Length) {

    uint32          RTNextNode;
    uint32          NextTail, *t;
    tRoutingMessage *Message;

    call StatsLogger.BumpCounter(NUM_ROUTING_RECV, 1);

    TimeSinceLastMessage = 0; // reset counter for any received message

    t = (uint32 *) Data;

    switch (t[0]) {
      case ROUTING_BEACON:
      case ROUTING_QUERY_ADJACENT_NODES:
      case ROUTING_REPLY_ADJACENT_NODES:
        NextTail = (MessageTail == (MAX_QUEUED_MESSAGES - 1) ) ?
                   0 : MessageTail + 1;
        if (NextTail != MessageHead) {
          Message = &(QueuedMessages[MessageTail]);
          Message->Command = t[0];
          Message->RequestingNode = t[1];
          Message->LastNode = t[2];
          Message->Hops = t[3];
          Message->DestinationNode =
            (Message->Command == ROUTING_REPLY_ADJACENT_NODES) ? t[4] : 0;
    
          MessageTail = NextTail;
          post ProcessQueuedMessages();
        } else {
          // buffer overflow too many queued messages before processing
          return FAIL;
        }
        break;

    case ROUTING_INVALIDATE_ROUTE:
        trace(TRACE_DEBUG_LEVEL,"Got invalidate route from %05X for %05X\n\r", Source, t[1]);

        if (call NetworkTopology.GetNextConnection(t[1], &RTNextNode, NULL)
             == SUCCESS) {
          if (RTNextNode == Source) {
              // the route through Source to t[1] is invalid
              trace(TRACE_DEBUG_LEVEL,"Removing route to %05X\n\r", t[1]);
              call NetworkTopology.RemoveRoute(t[1]);
              InvalidateRoute(t[1], Source);
          }
        }
        break;

      default:
    }

    return SUCCESS;
  }



/*
 * End of NetworkPacket interface.
 */


  /*
   * Determine a route to a network node.  In this implementation only network
   * broadcasts are supported.
   */

  command result_t Routing.RouteRequest(uint32 NodeID) {

    if (NodeID == INVALID_NODE) {
      QueryNeighbors (ThisNodeID, ThisNodeID, 0);
      return SUCCESS;
    } else {
      return FAIL;
    }

  }



/*
 * Start of StdControl interface.
 */

  command result_t Control.init() {
    MessageHead = 0;
    MessageTail = 0;
    NoRouteMessageTimeout = NO_ROUTE_MESSAGE_TIMEOUT;

    call WDControl.init();

    return SUCCESS;
  }




  command result_t Control.start() {
    post SendRouteBeacon();
    call WDControl.start();
    call Timer.start(TIMER_REPEAT, ROUTE_BEACON_INTERVAL);
    return SUCCESS;
  }


  command result_t Control.stop() {
    call WDControl.stop();
    call Timer.stop();
    return SUCCESS;
  }

/*
 * End of StdControl interface.
 */

/*
 * Start of Timer interface
 */

  event result_t Timer.fired() {

    TimeSinceLastMessage++;
    if (TimeSinceLastMessage >= NoRouteMessageTimeout) {
      if ((call NetworkTopology.IsPropertySupported(ThisNodeID,
               NETWORK_PROPERTY_CLUSTER_HEAD) == TRUE) || //VEH don't reset root
          (call NetworkTopology.GetNumRTEntries() >= MAX_NETWORK_SIZE)) {
        // no messages received after network reaches max size
        TimeSinceLastMessage = 0;
      } else {
          trace(TRACE_DEBUG_LEVEL,"Tree Routing : Resetting\n\r");

        call WDTControl.AllowForceReset();
      }
    }

    post SendRouteBeacon();

    return SUCCESS;
  }

/*
 * End of Timer interface
 */

  event result_t InvalidDest(uint32 Dest) {
    InvalidateRoute(Dest, INVALID_NODE);

    return SUCCESS;
  }

  /*
   * Low Power interface
   */
  event result_t LowPower.EnterLowPowerComplete () {
    return SUCCESS;
  }

  event result_t LowPower.PowerModeChange(bool LowPowerMode) {
    call Timer.stop();
    if (LowPowerMode) {
       call Timer.start(TIMER_REPEAT, LOW_POWER_BEACON_INTERVAL);
    } else {
       call Timer.start(TIMER_REPEAT, ROUTE_BEACON_INTERVAL);
    }
    return SUCCESS;
  }

}

