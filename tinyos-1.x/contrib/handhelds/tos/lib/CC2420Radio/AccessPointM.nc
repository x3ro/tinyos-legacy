/*
 * Copyright (c) 2004,2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Assumptions (that need to be removed some day):
 *   
 *  1. We're the PAN coordinator.  
 *
 *     This is a big assumption - it affects all addressing fields, the INTRA_PAN bit,
 *     and beacon packets.  
 *
 *  2. We don't have a method of handling timing.  For example, DATA REQUEST packets
 *     should be responded to quickly.  We really ought to keep a queue of packets
 *     to send and expiration times.  
 *
 * 
 * Authors:  Andrew Christian <andrew.christian@hp.com>
 *           16 December 2004
 *
 *
 * Added processing for disassociation request from clients
 * 11 July 2005 Bor-rong Chen
 */

includes Message;
includes ARP;
includes LinkLayer;
includes InfoMem;
includes AccessPoint;

module AccessPointM {
  provides {
    interface StdControl;
    interface Message;
    interface AccessPoint;  // Used to find our children
    interface ParamView;
  }

  uses {
    interface StdControl as RadioStdControl;
    interface Message2   as Radio;
    interface CC2420Control;

    interface Timer;
    interface StdControl as TimerControl;

    interface MessagePool;
    interface IEEEUtility;
  }
}

implementation {

  enum {
    CLIENT_FLAG_SADDR    = 0x01,     // Use short address with this client
    CLIENT_FLAG_SECURITY = 0x02,

    CLIENT_FLAG_STALE    = 0x40,     // This record timed out (and hence can be reactivated)
    CLIENT_FLAG_VALID    = 0x80      // This client record is ACTIVE
  };

  enum {
    MAX_CLIENT_RECORD     = 12,
    DEF_CLIENT_SADDR_BASE = 0,
    DEF_CLIENT_SADDR_TOP  = MAX_CLIENT_RECORD + DEF_CLIENT_SADDR_BASE,
    DEF_AP_SHORT_ADDRESS  = DEF_CLIENT_SADDR_TOP,

    TIMEOUT_INTERVAL      = 1024,   // Every second
    TIMEOUT_GO_STALE      = 10,     // 10 seconds without hearing from client = stale client record
    TIMEOUT_RELEASE_STALE = 60,     // 2 minutes from release; allow stale record reallocation

    TIMEOUT_FORCE_RESPONSE = 3,     // Always send _something_ response within 3 seconds
  };

  uint8_t  macDSN;
  uint8_t  macBSN;

  struct ClientRecord g_ClientRecord[MAX_CLIENT_RECORD];
  uint8_t             g_ClientCount;   // Active AND stale clients

  /*****************************************
   * StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    result_t r;

    call TimerControl.init();
    call MessagePool.init();
    r = call RadioStdControl.init();
    
    return r;
  }

  command result_t StdControl.start() {
    call TimerControl.start();

    call CC2420Control.set_pan_coord( TRUE );
    call CC2420Control.set_short_address( DEF_AP_SHORT_ADDRESS );
    call CC2420Control.set_pan_id( infomem->pan_id );

    call RadioStdControl.start();
    
    return call Timer.start( TIMER_REPEAT, TIMEOUT_INTERVAL );
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call TimerControl.stop();

    return call RadioStdControl.stop();
  }

  /*****************************************/
  /* Section 7.3 of the IEEE 802.15.4 spec */
  /*****************************************/

  /* We hardwire short beacons */

  void makeBeaconFrame( struct Message *msg )
  {
    msg_append_uint8( msg, FRAME_TYPE_BEACON );  // FCF
    msg_append_uint8( msg, SRC_MODE_SHORT );
    msg_append_uint8( msg, macBSN++ );

    // Source
    call CC2420Control.append_pan_id(msg);
    call CC2420Control.append_saddr(msg);

    // Superframe spec field
    msg_append_uint8( msg, 0x0f );    // Beacon order = 15, superframe order = 0
    if ( g_ClientCount < MAX_CLIENT_RECORD )
      msg_append_uint8( msg, BEACON_SUPERFRAME_PAN_COORDINATOR | BEACON_SUPERFRAME_ASSOCIATION_PERMIT );
    else
      msg_append_uint8( msg, BEACON_SUPERFRAME_PAN_COORDINATOR );

    // GTS
    msg_append_uint8( msg, 0 );  // Don't accept GTS

    // Pending address specification
    msg_append_uint8( msg, 0 );    // No pending addresses

    // Our own information goes here in the beacon payload.
    // Note that the Zigbee specification defines the first byte of the payload
    // as '0x00' to indicate a Zigbee network (the Protocol ID; see Table 139, pg 250
    
    msg_append_uint8( msg, HANDHELDS_IP_NETWORK );
    msg_append_str( msg, infomem->ssid );
  }

  /* 
   * Question:  Given that I'm repeating PanID, shouldn't I be able to set INTRA_PAN? 
   */
  void makeAssociationResponse( struct Message *msg, uint8_t *laddr, uint16_t saddr, uint8_t flag )
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD | ACK_REQUEST );  // FCF
    msg_append_uint8( msg, SRC_MODE_LONG | DEST_MODE_LONG );
    msg_append_uint8( msg, macDSN++ );

    // Destination
    call CC2420Control.append_pan_id(msg);
    msg_append_buf( msg, laddr, 8 );

    // Source
    call CC2420Control.append_pan_id(msg);
    call CC2420Control.append_laddr(msg);

    msg_append_uint8( msg, CMD_FRAME_ASSOCIATION_RESPONSE );  // Command identifier
    msg_append_saddr( msg, saddr );    // Client's new short address....(set 0xffff if not avail)
    msg_append_uint8( msg, flag );  // 00 = success, 01 = PAN at capacity...see table 68
  }

  /* 
   * This does NOT follow IEEE802.15.4.  See section 7.3.1.3.1 of the spec.
   * Normally this can only be sent to a LONG_ADDRESS.  Our problem is that
   * a reset access point with a fixed PAN_ID doesn't have any way of telling
   * a malingering client (one that had been associated) that it is no longer
   * in the association table.  Properly, the access point should not pick the
   * same PAN_ID.  But if for some reason it does, this is about the only way
   * to inform the client that it should re-associate.
   *
   * We use short addresses and skip the ACK field.
   */
     
  void makeShortDisAssociationNotification( struct Message *msg, uint16_t saddr )
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD );  // FCF
    msg_append_uint8( msg, DEST_MODE_SHORT ); // We're the PAN coordinator
    msg_append_uint8( msg, macDSN++ );

    // Destination
    call CC2420Control.append_pan_id(msg);
    msg_append_saddr( msg, saddr );
    msg_append_uint8( msg, CMD_FRAME_DISASSOCIATION_NOTIFICATION );
    msg_append_uint8( msg, DISASSOCIATION_REASON_COORDINATOR );
  }

  void processAssociationRequest( struct Message *msg, struct DecodedHeader *header )
  {
    struct ClientRecord *rec;
    uint16_t saddr;

    // Check to see if this is from an old client
    for ( saddr = DEF_CLIENT_SADDR_BASE, rec = g_ClientRecord; saddr < DEF_CLIENT_SADDR_TOP ; saddr++, rec++ ) {
      if ( (rec->flags & CLIENT_FLAG_VALID) && !memcmp( rec->laddr, header->src.a.laddr, 8)) {
	msg_clear(msg);
	makeAssociationResponse(msg, rec->laddr, saddr, 0 );
	rec->flags &= ~CLIENT_FLAG_STALE;   // Remove any stale bits
	rec->recv_timeout = TIMEOUT_GO_STALE;   
	signal AccessPoint.inform( NULL, saddr, INFORM_REASSOCIATE );
	return;
      }
    }

    // Check for sufficient free space to allocate a new client
    if ( g_ClientCount >= MAX_CLIENT_RECORD ) {
      msg_clear(msg);
      makeAssociationResponse( msg, header->src.a.laddr, 0xffff, 0x01 );  // PAN at capacity
      return;
    }

    // We have space, locate an empty record
    for ( saddr = DEF_CLIENT_SADDR_BASE, rec = g_ClientRecord; rec->flags & CLIENT_FLAG_VALID ; saddr++, rec++ ) 
      ;

    g_ClientCount++;
    memcpy( rec->laddr, header->src.a.laddr, 8 );
    memset( rec->ipaddr, 0, 4 );
    rec->flags   = (CLIENT_FLAG_SADDR | CLIENT_FLAG_VALID);
    rec->recv_timeout = TIMEOUT_GO_STALE;
    rec->pending      = NULL;

    // Fill the response message
    msg_clear(msg);
    makeAssociationResponse(msg, rec->laddr, saddr, 0 );

    // Inform the world
    signal AccessPoint.inform( NULL, saddr, INFORM_ASSOCIATE );
  }

  /*
   *  If we weren't PAN coordinator, we'd need to include source address information
   *  right after the destination.  However, we're almost certainly on the same PAN, 
   *  so we could set the INTRA_PAN bit and omit the source PAN_ID.
   */

  void makeEmptyDataMessage( struct Message *msg, uint16_t saddr )
  {
    msg_append_uint8( msg, FRAME_TYPE_DATA );   // Do not request an ACK (per 7.5.6.3)
    msg_append_uint8( msg, DEST_MODE_SHORT );   // We're the PAN coordinator
    msg_append_uint8( msg, macDSN++ );

    // Destination
    call CC2420Control.append_pan_id(msg);
    msg_append_saddr( msg, saddr );
  }

  void makeDataHeader( struct Message *msg, uint16_t saddr )
  {
    struct ClientRecord *rec = g_ClientRecord + (saddr - DEF_CLIENT_SADDR_BASE);
    uint8_t fcf1 = FRAME_TYPE_DATA | ACK_REQUEST;  

    if ( rec->pending ) fcf1 |= FRAME_PENDING;   // Check for more frames after this one

    msg_add_to_front( msg, 7 );
    msg_set_uint8( msg, 0, fcf1 );
    msg_set_uint8( msg, 1, DEST_MODE_SHORT );
    msg_set_uint8( msg, 2, macDSN++ );

    // Destination
    call CC2420Control.insert_pan_id( msg, 3 );
    msg_set_saddr( msg, 5, saddr );
  }

  void makeARPRequestMessage( struct Message *msg, struct ClientRecord *rec )
  {
    msg_append_uint8( msg, ARP_IP_ADDRESS_REQUEST );
  }

  /*
   * See 802.15.4, section 7.5.6.3
   *
   * Note we assume short addressing modes
   */

  bool processDataRequest( struct Message *msg, struct DecodedHeader *header )
  {
    struct ClientRecord *rec;
    uint16_t saddr;

    saddr = header->src.a.saddr;
    if ( saddr >= DEF_CLIENT_SADDR_BASE && saddr < DEF_CLIENT_SADDR_TOP ) {
      rec = g_ClientRecord + saddr - DEF_CLIENT_SADDR_BASE;

      if ( !(rec->flags & CLIENT_FLAG_VALID)) {  
	msg_clear(msg);
	makeShortDisAssociationNotification( msg, saddr );
	return call Radio.send(msg);
      }
      
      if (!(rec->flags & CLIENT_FLAG_STALE)) {
	rec->recv_timeout = TIMEOUT_GO_STALE;

	if ( rec->ipaddr[0] == 0 ) {      // Send an ARP request to find out the IP address
	  msg_clear(msg);
	  makeARPRequestMessage( msg, rec );
	  msg_prepend_uint8( msg, LL_ARP_PACKET );
	  makeDataHeader( msg, saddr );
	  return call Radio.send(msg);
	}
	else if ( rec->pending ) {      
	  msg = pop_queue( &rec->pending );
	  msg_prepend_uint8( msg, LL_IP_PACKET );
	  makeDataHeader( msg, saddr );
	  if ( call Radio.send(msg) != SUCCESS )
	    call MessagePool.free(msg);

	  return FALSE;   // We send the message from the queue and toss the message from the Radio
	}
	else {
	  // If we set FRAME_PENDING in the ACK, but don't have any data,
	  // we'd need to send an empty data message.
	  /*
	  msg_clear(msg);
	  makeEmptyDataMessage( msg, saddr );
	  return call Radio.send(msg);
	  */
	}
      }
    }

    return FALSE;
  }

  /*
   * See 802.15.4, section 7.5.3.2
   *
   * Note we assume short addressing modes
   */

  bool processDisAssociationNotification( struct Message *msg, struct DecodedHeader *header )
  {
    struct ClientRecord *rec;
    uint16_t saddr;


    saddr = header->src.a.saddr;
    if ( saddr >= DEF_CLIENT_SADDR_BASE && saddr < DEF_CLIENT_SADDR_TOP ) {
      rec = g_ClientRecord + saddr - DEF_CLIENT_SADDR_BASE;

      if ( !(rec->flags & CLIENT_FLAG_VALID)) {  
        //not a valid client
        return FALSE;
      } else {

        //release the client record
        rec->flags = 0;
        g_ClientCount--;
        // Toss messages
        // XXX: ideally we should re-distribute the messages queued for the disassociated client
        while ( rec->pending )
          call MessagePool.free( pop_queue( &rec->pending ));

        signal AccessPoint.inform( NULL, saddr, INFORM_RELEASED );
      }
    }

    return FALSE;
  }


  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processBeaconFrame( struct Message *msg, struct DecodedHeader *header )
  {
    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processARPPacket( struct Message *msg, struct ClientRecord *rec )
  {
    uint8_t arp_type;

    if (msg_get_length(msg) == 0)
      return FALSE;

    arp_type = msg_get_uint8(msg,0);
    msg_drop_from_front(msg,1);

    switch (arp_type) {
    case ARP_IP_ADDRESS_REQUEST:
      break;

    case ARP_IP_ADDRESS_RESPONSE:
      if ( (msg_get_length(msg) == 13) &&
	   msg_cmp_buf( msg, 1, rec->laddr, 8)) {
	msg_get_buf( msg, 9, rec->ipaddr, 4 );
	return TRUE;
      }
      break;
    }

    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processIPPacket( struct Message *msg )
  {
    int i;

    // If it's a small packet, we assume it goes to the UART interface
    if (msg_get_length(msg) < 20)
      return FALSE;

    // Match the destination IP address
    for ( i = 0 ; i < MAX_CLIENT_RECORD ; i++ ) {
      uint8_t flags = g_ClientRecord[i].flags;
      
      if ( (flags & CLIENT_FLAG_VALID) && 
	   !(flags & CLIENT_FLAG_STALE) &&
	   msg_cmp_buf( msg, 16, g_ClientRecord[i].ipaddr, 4 )) {
	append_queue( &(g_ClientRecord[i].pending), msg );
	return TRUE;
      }
    }

    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processDataLinkLayer( struct Message *msg, struct ClientRecord *rec, uint16_t saddr )
  {
    uint8_t msg_type;
    if (msg_get_length(msg) == 0)
      return FALSE;

    msg_type = msg_get_uint8(msg, 0);
    msg_drop_from_front(msg,1);

    switch (msg_type) {
    case LL_ARP_PACKET:
      if (processARPPacket( msg, rec )) {
	msg_clear( msg );
	signal AccessPoint.inform( msg, saddr, INFORM_ARP );
	return TRUE;
      }
      break;

    case LL_IP_PACKET:
      if (!processIPPacket(msg))  // If it didn't go to another client, we pass it up
	signal Message.receive(msg);
      return TRUE;
    }

    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processDataFrame( struct Message *msg, struct DecodedHeader *header )
  {
    struct ClientRecord *rec;
    uint16_t saddr;

    // We rely on address decoding to guarantee this message was for us
    if ( (header->fcf2 != SRC_MODE_SHORT) ||
	 (header->src.pan_id == 0xffff))
      return FALSE;

    saddr = header->src.a.saddr;

    if ( saddr >= DEF_CLIENT_SADDR_BASE && saddr < DEF_CLIENT_SADDR_BASE + MAX_CLIENT_RECORD ) {
      rec = g_ClientRecord + saddr - DEF_CLIENT_SADDR_BASE;

      //if not on record, send a DisAssociation command
      if ( !(rec->flags & CLIENT_FLAG_VALID)) {  
	msg_clear(msg);
	makeShortDisAssociationNotification( msg, saddr );
	return call Radio.send(msg);
      }
      
      if ( (rec->flags & CLIENT_FLAG_VALID) && !(rec->flags & CLIENT_FLAG_STALE)) {
	rec->recv_timeout = TIMEOUT_GO_STALE;
	return processDataLinkLayer( msg, rec, saddr );
      }
    }
    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processAckFrame( struct Message *msg, struct DecodedHeader *header )
  {
    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processCmdFrame( struct Message *msg, struct DecodedHeader *header )
  {
    if (msg_get_length(msg) < 1)
      return FALSE;

    switch (msg_get_uint8(msg,0)) {
    case CMD_FRAME_BEACON_REQUEST:  // Only accept short beacon requests
      if ( (msg_get_length(msg) != 1) || 
	   (header->fcf2 != DEST_MODE_SHORT) ||
	   (header->dest.pan_id  != 0xffff ) ||
	   (header->dest.a.saddr != 0xffff ))
	return FALSE;       // Poorly formed
      
      msg_clear(msg);
      makeBeaconFrame(msg);
      return call Radio.send(msg);

    case CMD_FRAME_ASSOCIATION_REQUEST:
      // We rely on address decoding to verify it is for us....
      if ( (header->fcf2 != (DEST_MODE_SHORT | SRC_MODE_LONG) ) ||
	   (msg_get_length(msg) != 2) ||
	   (header->dest.pan_id == 0xffff) ||    // Make sure it was sent to our PAN
	   (header->src.pan_id != 0xffff))
	return FALSE;
      processAssociationRequest(msg,header);
      return call Radio.send(msg);

    case CMD_FRAME_DATA_REQUEST:
      // If this is from one of OUR clients, we'll take it
      // Note that we are acting as PAN coordinator, so we have no address
      if ( (header->fcf2 != SRC_MODE_SHORT) ||
	   (msg_get_length(msg) != 1) ||
	   (header->src.pan_id == 0xffff))
	return FALSE;

      return processDataRequest(msg,header);

    case CMD_FRAME_DISASSOCIATION_NOTIFICATION:
      //if this is from one of our clients, we'll delete its record
      if ( (header->fcf2 != SRC_MODE_SHORT) ||
	   (msg_get_length(msg) != 2) ||
	   (header->src.pan_id == 0xffff))
	return FALSE;

      return processDisAssociationNotification(msg, header);

    case CMD_FRAME_ASSOCIATION_RESPONSE:
    case CMD_FRAME_PAN_ID_CONFLICT_NOTIFICATION:
    case CMD_FRAME_ORPHAN_NOTIFICATION:
    case CMD_FRAME_COORDINATOR_REALIGNMENT:
    case CMD_FRAME_GTS_REQUEST:
    default:
      return FALSE;  // Illegal command
    }

    return FALSE;
  }

  /*
   * Return TRUE if the message has been handled or FALSE if the message
   * should be released
   */

  bool processFrame( struct Message *msg )
  {
    struct DecodedHeader head;
    
    if ( !call IEEEUtility.decodeHeader( msg, &head ))
      return FALSE;

    switch (head.fcf1 & FRAME_TYPE_MASK) {
    case FRAME_TYPE_BEACON:
      return processBeaconFrame(msg,&head);
    case FRAME_TYPE_DATA:
      return processDataFrame(msg,&head);
    case FRAME_TYPE_ACK:
      return processAckFrame(msg,&head);
    case FRAME_TYPE_CMD:
      return processCmdFrame(msg,&head);
    default:
      // Unknown frame type
      return FALSE;
    }
  }

  /*****************************************/

  event void Radio.receive( struct Message *msg ) 
  {
    if (!processFrame(msg))
      call MessagePool.free(msg);
  }

  event void Radio.sendDone( struct Message *msg, result_t result, int flags )
  {
    call MessagePool.free(msg);
  }

  /***************************************************/

  async event bool CC2420Control.is_data_pending( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr )
  {
    struct ClientRecord *rec;
    uint16_t saddr;

    if (src_mode != SRC_MODE_SHORT || !src_addr ) 
      return FALSE;
    
    saddr  = src_addr[0];
    saddr |= src_addr[1] << 8;

    if ( saddr >= DEF_CLIENT_SADDR_BASE && saddr < DEF_CLIENT_SADDR_TOP ) {
      rec = g_ClientRecord + saddr - DEF_CLIENT_SADDR_BASE;

      // We have either a data packet or an ARP request to send to the client
      // OR the client is invalid and we'd like to send a DISASSOCIATE notify
      if ( !(rec->flags & CLIENT_FLAG_VALID) || 
	   rec->pending || 
	   rec->ipaddr[0] == 0)
	return TRUE;
    }

    return FALSE;
  }

  /* This should only be called once when the radio is powered up */

  event void CC2420Control.power_state_change( enum POWER_STATE state )
  {
    signal AccessPoint.startup();
  }

  /***************************************************/

  command void AccessPoint.reset()
  {
    int i;

    for ( i = 0 ; i < MAX_CLIENT_RECORD ; i++ ) {
      while ( g_ClientRecord[i].pending ) 
	call MessagePool.free( pop_queue( &g_ClientRecord[i].pending ));

      g_ClientRecord[i].flags = 0;
    }

    g_ClientCount = 0;
  }

  command struct ClientRecord * AccessPoint.find( uint16_t saddr )
  {
    return g_ClientRecord + (saddr - DEF_CLIENT_SADDR_BASE);
  }

  uint16_t find_next( uint16_t saddr )
  {
    struct ClientRecord *rec = g_ClientRecord + saddr - DEF_CLIENT_SADDR_BASE;

    while ( saddr < DEF_CLIENT_SADDR_TOP ) {
      if (rec->flags & CLIENT_FLAG_VALID)
	return saddr;

      saddr++;
      rec++;
    }

    return 0xffff;
  }

  command uint16_t AccessPoint.first()
  {
    return find_next( DEF_CLIENT_SADDR_BASE );
  }

  command uint16_t AccessPoint.next( uint16_t saddr )
  {
    return find_next( saddr );
  }

  command uint16_t AccessPoint.count()
  {
    return g_ClientCount;
  }

  command void AccessPoint.append_laddr( struct Message *msg )
  {
    call CC2420Control.append_laddr(msg);
  }

  command uint16_t AccessPoint.get_frequency()
  {
    return call CC2420Control.get_frequency();
  }

  /***************************************************
   * Process a message received from the UART
   ***************************************************/

  command result_t Message.send( struct Message *msg )
  {
    uint8_t  i;

    // IP Packet headers are always 20 bytes lon
    if ( msg_get_length(msg) < 20 )
      return FAIL;

    // Match the destination IP address
    for ( i = 0 ; i < MAX_CLIENT_RECORD ; i++ ) {
      uint8_t flags = g_ClientRecord[i].flags;
      
      if ( (flags & CLIENT_FLAG_VALID) && 
	   !(flags & CLIENT_FLAG_STALE) &&
	   msg_cmp_buf( msg, 16, g_ClientRecord[i].ipaddr, 4 )) {
	append_queue( &(g_ClientRecord[i].pending), msg );
	return SUCCESS;
      }
    }
    return FAIL;
  }

  event result_t Timer.fired()
  {
    uint16_t saddr;
    struct ClientRecord *rec;
    
    for ( saddr = DEF_CLIENT_SADDR_BASE, rec = g_ClientRecord; saddr < DEF_CLIENT_SADDR_TOP ; saddr++, rec++ ) {
      if ( rec->flags & CLIENT_FLAG_VALID ) {
	rec->recv_timeout--;

	if ( !rec->recv_timeout ) {
	  if ( rec->flags & CLIENT_FLAG_STALE ) {   // Release this record
	    rec->flags = 0;
	    g_ClientCount--;
	    // Toss messages
	    while ( rec->pending )
	      call MessagePool.free( pop_queue( &rec->pending ));

	    signal AccessPoint.inform( NULL, saddr, INFORM_RELEASED );
	  }
	  else {    // Make'm stale
	    rec->flags |= CLIENT_FLAG_STALE;
	    rec->recv_timeout = TIMEOUT_RELEASE_STALE;
	    signal AccessPoint.inform( NULL, saddr, INFORM_STALE );
	  }
	}
      }
    }
    return SUCCESS;
  }

  /*****************************************
   *  ParamView interface
   *****************************************/

  const struct Param s_AccessPoint[] = {
    { "clients",  PARAM_TYPE_UINT8, &g_ClientCount },
    { NULL, 0, NULL }
  };

  struct ParamList g_AccessPointList = { "ap", &s_AccessPoint[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_AccessPointList );
    return SUCCESS;
  }

}

