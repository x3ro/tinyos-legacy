/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "sp.h"

/**
 * Sensornet Protocol (SP): Primary link communication mechanism.
 * <p>
 * SP is a unifying link abstraction for running network protocols over
 * a variety of link layer and physical layer technologies without
 * changing network protocol implementation. 
 * <p>
 * SPC and its interfaces are described in detail in the following 
 * publication: <br>
 * <a href="http://www.polastre.com/papers/sensys05-sp.pdf">
 * A Unifying Link Abstraction for Wireless Sensor Networks
 * </a><br>
 * In Proceedings of the Third ACM Conference on Embedded Networked 
 * Sensor Systems (SenSys), November 2-4, 2005.
 * <p>
 * Messages are transmitted using the SPSend interface and message futures
 * are handled through the SPSendNext interface.  To send a message
 * on a particular AM type, such as AM type 5, wire your network protocol
 * to SPSend[5].  The SP message pool will hold on to a message and its
 * corresponding packets until it may be sent over the channel. 
 * <p>
 * Fields of each SP message (<tt>sp_message_t</tt>) should never be
 * directly accessed.  Instead, they can be set using the parameters of
 * the SPSend interface.  Reading parameter should be done through 
 * the SPMessage interface.
 * <p>
 * Reception is on a per packet basis (not a per message basis like
 * SPSend).  Packets are immediately dispatched to higher layer services
 * based on AM type.
 * <p>
 * The SP Neighbor Table is accessed through the SPNeighbor interface.
 * Users must wire to the SP Neighbor Table with the parameter
 * <tt>unique("SPNeighbor")</tt>.  Each service then has its own identity
 * for controlling the insertions, removals, and changes of entries
 * in the SP Neighbor Table.  See the SPNeighbor interface for more info.
 * <p>
 * Various utilities as part of SP's processing are available in the
 * SPUtil interface.  These include link estimation functions and
 * link post-arbitration time stamps.
 * 
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration SPC {
  provides {
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
    
    interface SPSend[uint8_t id];     // use with your AM identifier
    interface SPSendNext[uint8_t id]; // use with the same AM identifier
    interface SPReceive[uint8_t id];

    interface SPNeighbor[uint8_t id]; // use with unique("SPNeighbor")

    interface SPMessage;              // ADT access to sp_message_t

    interface SPInterface;            // Metadata about physical interfaces

    interface SPUtil;
  }
}
implementation {
  components MainUartPacketC;
  components MainSPC;
  components new ObjectPoolC(sp_message_t, SP_SIZE_MESSAGE_POOL) as MessagePool
    , new ObjectPoolC(sp_neighbor_t, SP_SIZE_NEIGHBOR_TABLE) as NeighborTable
    , Counter32khzC
    , SPM as Impl
    , SPMessageM as Msg
    , SPDataM as Data
    , SPNeighborTableM as Mgr
    , SPUtilM as Util
    , SPInterfaceM as Interface
    , SPAdaptorGenericCommM as Adaptor
    , LinkRadio
    , UARTFramedPacket as UARTPacket
    , SPGenericInterfaceUart
    ;

  // implement the message pool
  Data.Pool -> MessagePool;
  Data.LocalTime -> Counter32khzC;

  SPSend = Impl;
  SPSendNext = Impl;

  SPMessage = Msg;

  SPInterface = Interface;
  Interface.LowerInterface[SP_I_RADIO] -> LinkRadio;
  Interface.LowerInterface[SP_I_UART] -> SPGenericInterfaceUart;

  // notification that the contents of the pool has changed
  Mgr.NeighborTable -> NeighborTable;
  Mgr.NeighborTableEvents -> NeighborTable;
  Mgr.SPLinkStats -> LinkRadio;
  Mgr.SPLinkEvents -> LinkRadio;

  SPNeighbor = Mgr;

  // notification that the contents of the pool has changed
  Impl.Pool -> MessagePool;
  Impl.PoolEvents -> MessagePool;

  // internal timers
  Impl.LocalTime -> Counter32khzC;
  
  // Send messages via the Radio
  Impl.SPDataMgr -> Data.SPSend;
  Impl.SPDataMgrNext -> Data.SPSendNext;
  Impl.LowerSend -> LinkRadio.SPSend;
  Impl.SPLinkStats -> LinkRadio;
  Impl.SPLinkEvents -> LinkRadio;

  Impl.SPNeighbor -> Mgr.SPNeighbor[unique("SPNeighbor")];

  Data.UARTSend -> UARTPacket;

  LinkRadio.Pool -> MessagePool;

  // receive just flows straight through SP
  Impl.LowerReceive -> LinkRadio;
  Impl.UARTReceive -> UARTPacket;
  ReceiveMsg = Impl;
  SPReceive = Impl;

  // if someone doesn't send with SP messages, use an adaptor
  SendMsg = Adaptor;
  Adaptor.SPSend -> Impl.SPSend;

  SPUtil = Util;
  Util.TimeStamping -> LinkRadio;
  Util.SPLinkStats -> LinkRadio;

}
