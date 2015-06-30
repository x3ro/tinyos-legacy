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
 * A couple of key assumptions.  First, we scan for all
 * available access points and ALWAYS pick the one with 
 * the highest signal strength (rssi) that we see.  If
 * we fail to associate with that one, we go to sleep for
 * a while.  
 *
 * Things to fix....
 *
 *    We need to turn on security encoding/decoding
 *    We should flush the message queue on losing our connection ???
 *    
 *
 * Authors:  Andrew Christian
 *           Bor-rong Chen
 *           6 July 2005
 */

#include "IEEE802154.h"

includes Message;
includes CC2420Control;
includes InfoMem;

module ClientM {
  provides {
    interface StdControl;
    interface Message;
    interface Client;
    interface ParamView;
  }

  uses {
    interface StdControl as RadioStdControl;
    interface Message2   as Radio;
    interface CC2420Control;

    interface Timer;
    interface Timer as AutoReScanTimer;
    interface Leds;
    interface MessagePool;
    
    interface IEEEUtility;
  }
}

implementation {
  enum {
    TIMEOUT_SCAN_PER_CHANNEL   = 50,  // Minimum is 23 ms
    TIMEOUT_ASSOCIATE_RESPONSE = 200,

    TIMEOUT_FAILED_SCAN        = 2048,
  };

  enum {
    CLIENT_STATE_IDLE = 0,       // No connection, doing nothing
    CLIENT_STATE_SCAN,           // Actively scanning local channels for Beacons
    CLIENT_STATE_ASSOCIATE,      // Attempting to associate with an access point
    CLIENT_STATE_ACTIVE_TX,      // Associated with an access point; periodic requests for data
    CLIENT_STATE_ACTIVE_WAIT,    // Waiting for data packets from the access point
    CLIENT_STATE_SNOOZE,         // Associated with an access point, but the radio is off
    CLIENT_STATE_SNOOZE_POWER_DOWN,  // In the process of powering down
    CLIENT_STATE_SNOOZE_POWER_UP,    // In the process of powering up
    CLIENT_STATE_DISASSOCIATED,  // Received a disassociation notify
    CLIENT_STATE_DISASSOCIATING,      // In the process of sending out DisAssociation message
  };

  enum {
    PAN_FLAG_AP_SADDR     = 0x01,   // Talk to access point using short address
    PAN_FLAG_CLIENT_SADDR = 0x02,   // Client has a valid short address
    PAN_FLAG_SECURITY     = 0x04,   // Security is turned on
    PAN_FLAG_COORDINATOR  = 0x08,   // Our access point is the PAN coordinator
    PAN_FLAG_ASSOCIATED   = 0x10    // We're associated
  };

  /* Constants for channel rescanning */
  enum {
    RSSI_TOLERANCE = 5,        //If signal strength drops by RSSI_TOLERANCE dB
                                //compared to the rssi value at association time, 
                                //attemp to rescan 
    AUTO_RESCAN_TIMER_DURATION = 10000,     //Number of milliseconds for automatic rescan timer to fire
    PERIOD_AUTO_RESCAN = 6      //Number of AUTO_RESCAN_TIMER_DURATIONs
                                //The auto rescan should happen very infrequently so
                                //that it will not burn too much power
  };

  struct PanEntry {
    uint16_t id;           // Source Pan ID
    uint16_t saddr;        // Source Pan short address
    uint8_t  laddr[8];     // Source Pan long address
    uint8_t  flags;
    uint8_t  channel;
    int8_t   rssi;         // From the scan
  };

  void switchClientState(int newState);

  /*
   * Snooze functions handle how long we put the radio to sleep before requesting more data
   * and how long we run without hearing the access point before we give up and try to re-associate.
   *
   * The g_SnoozeLevel counter controls how long we sleep between data requests.  It gets increased
   * every time we send or receive packets with data (but not for DATA_REQUESTS or empty DATA packets).
   * g_SnoozeLevel gets decremented once each time we issue a DATA_REQUEST.
   * 
   * At values above NUM_SNOOZE_TIMEOUTS we don't actually sleep - instead we issue DATA_REQUEST 
   * packets at DEF_ACTIVE_DURATION intervals.  Below NUM_SNOOZE_TIMEOUTS the sleep time gets 
   * progressively longer (see s_SnoozeTimeouts).  When we hit level 0, not only are the snooze
   * timeouts at their maximum level, but we also keep track of how many packets we've missed from the
   * access point.  If that count goes above DEF_SNOOZE_TIMEOUTS_UNTIL_RESCAN, we give up on this
   * access point and re-scan for access points.
   */
  enum {
    DEF_SNOOZE_TIMEOUTS_UNTIL_RESCAN = 1,
    DEF_SNOOZE_DURATION = 1024,  // 1 second      ...Time to sleep (by default)
    DEF_ACTIVE_DURATION = SYMBOLS_TO_MILLISECONDS( IEEE802154_aMaxFrameResponseTime),   // 640 jiffies or 19 ms

    NUM_SNOOZE_TIMEOUTS = 8,     // The number of stages in the snooze timeout list
    SNOOZE_ADD_SEND     = 1,
    SNOOZE_ADD_RECEIVE  = 3,
    MAX_SNOOZE_LEVEL    = 10
  };

  uint8_t g_SnoozeTimeout;       // How many times we've done a full snooze since we've seen a packet
  uint8_t g_PktDrop;       // How many packets have been dropped by Message.send()
  uint8_t g_SnoozeLevel;         // Our current snooze level (see the s_SnoozeTimeouts array)
  const uint32_t s_SnoozeTimeouts[NUM_SNOOZE_TIMEOUTS] = { 1024, 512, 256, 256, 128, 128, 64, 64 };
  
  
  static void changeSnoozeLevel( int amount )
  {
    g_SnoozeLevel += amount;
    if (g_SnoozeLevel > MAX_SNOOZE_LEVEL)
      g_SnoozeLevel = MAX_SNOOZE_LEVEL;
  }

  static void updateSnoozeLevel( const struct Message *msg )
  {
    if ( msg_get_length(msg) > 0 ) {
      g_SnoozeLevel += SNOOZE_ADD_RECEIVE;
      if (g_SnoozeLevel > MAX_SNOOZE_LEVEL)
	g_SnoozeLevel = MAX_SNOOZE_LEVEL;
    }
  }

  uint8_t         g_macDSN;
  struct PanEntry g_PanEntry;
  struct PanEntry g_ScanPanEntry;
  uint8_t         g_ScanChannel;
  uint8_t         g_ClientState;
  int8_t          g_rssiRef;             // Reference RSSI, recoreded at association time
  uint8_t         g_AutoReScanTimeout;   // number of full snoozes before an automatic rescan 
  struct Message *g_SendQueue;           // Pending outbound queue

  enum {
    CLIENT_FLAG_RESCAN             = (1<<0),  // Re-scan required
//    CLIENT_FLAG_RESCAN_INTERRUPTED = (1<<1),  // Re-scan interrupted by pending packet
    CLIENT_FLAG_DATA_PENDING       = (1<<2),  // The last packet received had data pending set
    CLIENT_FLAG_DATA_REQUEST       = (1<<3)   // The last packet sent was a data request
  };

  uint8_t         g_Flags;

  static void inline recordRSSI( const struct DecodedHeader *head )
  {
    int tmp;
    tmp = ((int)(g_PanEntry.rssi + head->rssi)>>1);
    g_PanEntry.rssi=tmp;    
  }

  static void inline recordAckRSSI( int flags)
  {
    int tmp;
    tmp = ((int)(g_PanEntry.rssi + (flags >> 8))>>1);
    g_PanEntry.rssi=tmp;    
  }

 static void inline clearRSSI()
  {
    g_PanEntry.rssi=0;
  }


  /*****************************************
   *  StdControl interface
   *****************************************/

  command result_t StdControl.init() {
    call MessagePool.init();
    //    call Leds.init();
    call RadioStdControl.init();

    return SUCCESS;
  }

  command result_t StdControl.start() {

    // This will raise the power level, causing a 'power_state_change' event to be fired.
    call RadioStdControl.start();
    call AutoReScanTimer.start( TIMER_REPEAT, AUTO_RESCAN_TIMER_DURATION );

   return SUCCESS;
  }

  command result_t StdControl.stop() {
    call Timer.stop();
    call AutoReScanTimer.stop();

    switchClientState(CLIENT_STATE_IDLE);
    signal Client.connected(FALSE);
    call RadioStdControl.stop();
    call MessagePool.init();

    return SUCCESS;
  }

  /*****************************************
   *  Client interface
   *****************************************/

  command bool Client.is_connected() {
    return ( g_ClientState >= CLIENT_STATE_ACTIVE_TX );
  }

  command uint8_t Client.get_mac_address_length() {
    return 8;
  }

  command void Client.get_mac_address( uint8_t *buf ) {
    call CC2420Control.get_long_address( buf );
  }

  command void Client.append_mac_address( struct Message *msg ) {
    call CC2420Control.append_laddr( msg );
  }

  command void Client.insert_mac_address( struct Message *msg, uint8_t offset ) {
    call CC2420Control.insert_laddr( msg, offset );
  }

  command void Client.set_ip_address(uint8_t octet1, uint8_t octet2, uint8_t octet3, uint8_t octet4)
  {
  }

  command int Client.get_average_rssi()
  {
    return g_PanEntry.rssi;
  }

  command int Client.get_ref_rssi()
  {
    return g_rssiRef;
  }

  command int Client.get_pan_id()
  {
    return g_PanEntry.id;
  }
 
  command int Client.get_channel()
  {
    return g_PanEntry.channel;
  }

  /* Prepend tranmissions information on this packet
     We always have a FCF + DSN fields (3 bytes).
     For now, we assume we're talking short addresses to the
     PAN coordinator
  */

  void makeDataHeader( struct Message *msg )
  {
    msg_add_to_front( msg, 7 );
    msg_set_uint8( msg, 0, FRAME_TYPE_DATA | ACK_REQUEST );  
    msg_set_uint8( msg, 1, SRC_MODE_SHORT );   // Assume we talk to PAN coordinator
    msg_set_uint8( msg, 2, g_macDSN++ );

    call CC2420Control.insert_pan_id( msg, 3 );
    call CC2420Control.insert_saddr( msg, 5 );
  }

  void makeDataRequest( struct Message *msg )
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD | ACK_REQUEST );  
    msg_append_uint8( msg, SRC_MODE_SHORT );   // Assume we talk to PAN coordinator
    msg_append_uint8( msg, g_macDSN++ );

    call CC2420Control.append_pan_id( msg );
    call CC2420Control.append_saddr( msg );

    msg_append_uint8( msg, CMD_FRAME_DATA_REQUEST );  // Command identifier
  }

  /* 
     Return TRUE if we actually found and sent a message from the queue 
     Set a flag bit if we send a DATA_REQUEST packet
   */

  bool sendFromQueue( bool forceDataRequest )
  {
    struct Message *msg = pop_queue( &g_SendQueue );

    if (msg) makeDataHeader( msg );
    
    g_Flags &= ~CLIENT_FLAG_DATA_REQUEST;

    if (!msg && forceDataRequest) {
      msg = call MessagePool.alloc();
      if (msg) {
        makeDataRequest(msg);
	g_Flags |= CLIENT_FLAG_DATA_REQUEST;
      }
    }

    if (msg) {
      if (call Radio.send(msg) == SUCCESS) {
	if ( !(g_Flags & CLIENT_FLAG_DATA_REQUEST))
	  changeSnoozeLevel( SNOOZE_ADD_SEND );
	return TRUE;
      }

      call MessagePool.free(msg);
    }
    return FALSE;
  }

  /* We don't allow security frames yet */
  bool isDisassociationNotification( struct Message *msg, struct DecodedHeader *header )
  {
    return ( (msg_get_length(msg) == 2 ) &&
	     (msg_get_uint8(msg,0) == CMD_FRAME_DISASSOCIATION_NOTIFICATION));
  }

  /* uncomment to enable Logic analyzer debugging */
  /*
  void setADC(int i) {

    //trigger
    TOSH_SET_ADC7_PIN();
    TOSH_CLR_ADC7_PIN();

    if(i & 0x1) TOSH_SET_ADC0_PIN();
    else TOSH_CLR_ADC0_PIN();

    if(i & 0x2) TOSH_SET_ADC1_PIN();
    else TOSH_CLR_ADC1_PIN();

    if(i & 0x4) TOSH_SET_ADC2_PIN();
    else TOSH_CLR_ADC2_PIN();

    if(i & 0x8) TOSH_SET_ADC3_PIN();
    else TOSH_CLR_ADC3_PIN();

  }
  */

  void switchClientState(int newState) {
    g_ClientState = newState;
    //XXX: for logic analyzer debug
    //setADC(newState);
  }

 
  /*****************************************
   *  Active Wait operating mode
   *
   *  The radio is turned on and we received
   *  a message that said data was pending.  We
   *  are waiting for a data packet to arrive
   *****************************************/

 void doSnooze();

  void handleActiveWaitTimeout()
  {
    if (sendFromQueue((g_Flags & CLIENT_FLAG_DATA_PENDING) != 0))
      switchClientState(CLIENT_STATE_ACTIVE_TX);
    else 
      doSnooze();
  }

  void handleActiveWaitSend( struct Message *msg )
  {
    append_queue( &g_SendQueue, msg );
  }

  void handleActiveWaitReceive( struct Message *msg, struct DecodedHeader *header )
  {
    switch (header->fcf1 & FRAME_TYPE_MASK) {
    case FRAME_TYPE_CMD:
      if ( isDisassociationNotification( msg, header )) 
	switchClientState(CLIENT_STATE_DISASSOCIATED);  // Only valid because a Timer is still due to fire

      call MessagePool.free(msg);
      break;

    case FRAME_TYPE_DATA:
      updateSnoozeLevel( msg );
      if ( header->fcf1 & FRAME_PENDING )
	g_Flags |= CLIENT_FLAG_DATA_PENDING;

      signal Message.receive(msg);

      if ( call Timer.stop() == SUCCESS ) 
	handleActiveWaitTimeout();
      break;

    default:
      call MessagePool.free(msg);
      break;
    }
  }

  void ScanRequest();

  /*****************************************
   *  Active Tx operating mode
   *
   *  The radio is turned on and a message
   *  has been sent (we're waiting for sendDone)
   *****************************************/

  void handleActiveTxSendDone( struct Message *msg, result_t result, int flags )
  {
    bool force_data_request = FALSE;

    call MessagePool.free(msg);

    if ( result == SUCCESS && (flags & MESSAGE2_ACK) ) {
      g_SnoozeTimeout = 0;   // We know we received an ACK

      if ( flags & MESSAGE2_DATA_PENDING ) {
	if (g_Flags & CLIENT_FLAG_DATA_REQUEST) {  // We just SENT a data request
	  g_Flags &= ~CLIENT_FLAG_DATA_PENDING;    
	  switchClientState(CLIENT_STATE_ACTIVE_WAIT);
	  call Timer.start( TIMER_ONE_SHOT, DEF_ACTIVE_DURATION );
	  return;
	}
	else {
	  force_data_request = TRUE;  // Sending a data request would be a good idea
	}
      }
    } 
    
    if (!sendFromQueue(force_data_request)) 
      doSnooze();
  }

  void handleActiveTxSend( struct Message *msg )
  {
    append_queue( &g_SendQueue, msg );
  }

  void handleActiveTxReceive( struct Message *msg, struct DecodedHeader *header )
  {
    g_SnoozeTimeout = 0;

    switch (header->fcf1 & FRAME_TYPE_MASK) {
    case FRAME_TYPE_DATA:
      updateSnoozeLevel( msg );
      signal Message.receive(msg);
      break;

    default:
      call MessagePool.free(msg);
      break;
    }
  }


  /*****************************************
   *  Snooze mode
   * 
   *  In a low power, resting mode.  Wake up
   *  if either (a) we have a new message to
   *  send or (b) we timeout of snooze.
   *****************************************/

  void snoozeSend()
  {
    if (sendFromQueue(TRUE)) 
      switchClientState(CLIENT_STATE_ACTIVE_TX);
    else {
      switchClientState(CLIENT_STATE_SNOOZE_POWER_DOWN);
      call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );  // Allocation problems. Try later
    }
  }

  void makeShortDisAssociationNotification( struct Message *msg);

  void doSnooze()
  {
    if (g_AutoReScanTimeout > PERIOD_AUTO_RESCAN) {         //Auto-rescan
      g_Flags |= CLIENT_FLAG_RESCAN;
      ScanRequest();      
    } else if ( g_Flags & CLIENT_FLAG_RESCAN ) { 
      ScanRequest();     
    } else if ( g_SnoozeTimeout++ > DEF_SNOOZE_TIMEOUTS_UNTIL_RESCAN ) {    // Rescan
      signal Client.connected(FALSE);
      ScanRequest();      // Don't turn off the power; we re-scan immediately
    }
    else {
      if ( g_SnoozeLevel > 0 )
	g_SnoozeLevel--;

      if ( g_SnoozeLevel >= NUM_SNOOZE_TIMEOUTS ) 
	snoozeSend();   // Go immediately to a send data request
      else {
	switchClientState(CLIENT_STATE_SNOOZE_POWER_DOWN);
	call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );
      }
    }
  }

  void handleSnoozeTimeout()
  {
    switchClientState(CLIENT_STATE_SNOOZE_POWER_UP);
    call CC2420Control.set_power_state( POWER_STATE_ACTIVE );
  }

  void handleSnoozePowerDown()
  {
    if (g_SendQueue) {
      switchClientState(CLIENT_STATE_SNOOZE_POWER_UP);
      call CC2420Control.set_power_state( POWER_STATE_ACTIVE );
    }
    else {
      switchClientState(CLIENT_STATE_SNOOZE);
      call Timer.start( TIMER_ONE_SHOT, s_SnoozeTimeouts[ g_SnoozeLevel ] );
    }
  }

  void handleSnoozePowerUp()
  {
    snoozeSend();
  }

  void handleSnoozeSend( struct Message *msg )
  {
    append_queue( &g_SendQueue, msg );
    
    // Cancel the timer.  If it returns FAIL, that means it has already fired
    switch (g_ClientState) {
    case CLIENT_STATE_SNOOZE:
      if ( call Timer.stop() == SUCCESS )
	handleSnoozeTimeout();
      break;
    }
  }

  void handleSnoozeReceive( struct Message *msg, struct DecodedHeader *header )
  {
    // We should do something smarter here if we see a message with the DATA_PENDING flag
    // But we didn't expect to see any messages anway.
    g_SnoozeTimeout = 0;

    switch (header->fcf1 & FRAME_TYPE_MASK) {
    case FRAME_TYPE_DATA:
      updateSnoozeLevel(msg);
      signal Message.receive(msg);
      break;

    default:
      call MessagePool.free(msg);
      break;
    }
  }


  /*****************************************
   * Interface for association
   *
   * Send an ASSOCIATION_REQUEST
   * Wait for an ASSOCIATION_RESPONSE
   *
   * If accepted, set our personnal ID. 
   *****************************************/
  
  void makeAssociationRequest( struct Message *msg, struct PanEntry *pan )
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD | ACK_REQUEST );  // FCF
    if ( pan->flags & PAN_FLAG_AP_SADDR )
      msg_append_uint8( msg, DEST_MODE_SHORT | SRC_MODE_LONG );
    else
      msg_append_uint8( msg, DEST_MODE_LONG | SRC_MODE_LONG );

    msg_append_uint8( msg, g_macDSN++ );

    msg_append_saddr( msg, pan->id );       // Dest PAN
    if ( pan->flags & PAN_FLAG_AP_SADDR )
      msg_append_saddr( msg, pan->saddr );  // Dest addr
    else
      msg_append_buf( msg, pan->laddr, 8 );  // Dest addr

    // Source address is long
    msg_append_saddr( msg, 0xffff );
    call CC2420Control.append_laddr( msg );

    msg_append_uint8( msg, CMD_FRAME_ASSOCIATION_REQUEST );  // Command identifier
    msg_append_uint8( msg, CAP_ALLOCATE_ADDRESS );  // Request short address
  }

  void AssociateDone( result_t result )
  {
    if ( result == SUCCESS ) {
      g_SnoozeTimeout = 0;
      g_SnoozeLevel   = 0;
      signal Client.connected( TRUE );
      snoozeSend();   // Will immediately send a DATA REQUEST packet
    }
    else {
      // Failed to associate.  We _should_ try the next best access point,
      // but for convenience, we'll just power down and try again in a bit.
      switchClientState(CLIENT_STATE_IDLE);
      call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );
    }
  }

  /* Only called if we did not receive an associate_okay message within TIMEOUT */
  void handleAssociateTimeout()
  {
    AssociateDone( (g_PanEntry.flags & PAN_FLAG_ASSOCIATED) ? SUCCESS : FAIL );
  }

  void handleAssociateSendDone( struct Message *msg, result_t result )
  {
    call MessagePool.free(msg);

    if ( result == SUCCESS ) 
      call Timer.start( TIMER_ONE_SHOT, TIMEOUT_ASSOCIATE_RESPONSE );
    else 
      AssociateDone( FAIL );
  }

  /* We don't allow security frames yet */
  bool isAssociationResponse( struct Message *msg, struct DecodedHeader *header )
  {
    return ( (msg_get_length(msg)  == 4 ) &&
	     (header->fcf1 == (FRAME_TYPE_CMD | ACK_REQUEST)) &&
	     (header->fcf2 == (DEST_MODE_LONG | SRC_MODE_LONG)) &&
	     (msg_get_uint8(msg,0) == CMD_FRAME_ASSOCIATION_RESPONSE));
  }

  void handleAssociateMessage( struct Message *msg, struct DecodedHeader *header )
  {
    uint16_t saddr;

    if ( isAssociationResponse(msg,header) && msg_get_uint8(msg, 3) == 0 ) {
      saddr  = msg_get_saddr( msg, 1 );
      g_PanEntry.flags |= PAN_FLAG_ASSOCIATED;

      if ( saddr != 0xfffe ) {
	call CC2420Control.set_short_address( saddr );
	g_PanEntry.flags |= PAN_FLAG_CLIENT_SADDR;
      }
    }

    //cancel the timer
    if ( call Timer.stop() == SUCCESS ) 
      AssociateDone( (g_PanEntry.flags & PAN_FLAG_ASSOCIATED) ? SUCCESS : FAIL );

    call MessagePool.free(msg);
  }

  result_t AssociateRequest()
  {
    struct Message *msg = call MessagePool.alloc();
    if (!msg) 
      return FAIL;

    //record the reference RSSI at association time
    g_rssiRef = g_PanEntry.rssi;

    call CC2420Control.set_channel(g_PanEntry.channel);
    call CC2420Control.set_pan_id(g_PanEntry.id);
    
    makeAssociationRequest(msg,&g_PanEntry);

    if ( (call Radio.send(msg)) != SUCCESS ) {
      call MessagePool.free(msg);
      return FAIL;
    }

    switchClientState(CLIENT_STATE_ASSOCIATE);

    return SUCCESS;
  }

  /*****************************************
   * Interface for scanning
   *
   * For the moment we ignore the type and always
   * send out a beacon request
   *****************************************/
  
  void makeBeaconRequestFrame( struct Message *msg )
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD );  // FCF
    msg_append_uint8( msg, DEST_MODE_SHORT );
    msg_append_uint8( msg, g_macDSN++ );
    msg_append_saddr( msg, 0xffff );  // Dest PAN
    msg_append_saddr( msg, 0xffff );  // Dest Short address
    msg_append_uint8( msg, CMD_FRAME_BEACON_REQUEST );
  }

  /*****************************************
   * Make a disassociation notification
   * See 802.15.4  section 7.3.1.3
   *****************************************/
  void makeShortDisAssociationNotification( struct Message *msg)
  {
    msg_append_uint8( msg, FRAME_TYPE_CMD | ACK_REQUEST );  
    msg_append_uint8( msg, SRC_MODE_SHORT );   // Assume we talk to PAN coordinator
    msg_append_uint8( msg, g_macDSN++ );

    // Destination
    call CC2420Control.append_pan_id( msg );
    call CC2420Control.append_saddr( msg );

    msg_append_uint8( msg, CMD_FRAME_DISASSOCIATION_NOTIFICATION ); //Command
    msg_append_uint8( msg, DISASSOCIATION_REASON_DEVICE ); //reason: device wants to leave
  }

  void ScanDone(int channel)
  {
    //reset auto rescan counter
    if(g_AutoReScanTimeout)
      g_AutoReScanTimeout = 0;

    //if it is a rescan we check the RSSI of newly scanned channel
    if (g_Flags & CLIENT_FLAG_RESCAN) {
      g_Flags &= ~CLIENT_FLAG_RESCAN;

      //switch back to the original channel to keep the original communication going
      call CC2420Control.set_channel(g_PanEntry.channel);
      call CC2420Control.set_pan_id(g_PanEntry.id);

      //see if this is the same channel, the same pan_id
      if(g_ScanPanEntry.id == g_PanEntry.id && g_ScanPanEntry.channel == g_PanEntry.channel) {
        //do nothing
        g_rssiRef = g_ScanPanEntry.rssi;
        doSnooze();
        return;
      }

      //if we get a rssi better than the original by RSSI_TOLERANCE/2
      if(g_ScanPanEntry.rssi > (g_PanEntry.rssi + RSSI_TOLERANCE/2)) {
      //if we get a better rssi, switch to the new access point
      //if(g_ScanPanEntry.rssi > g_PanEntry.rssi) {

        struct Message *msg = NULL;

        //send a disassociation request to original AP
        msg = call MessagePool.alloc();
        if (msg) {
          makeShortDisAssociationNotification(msg);


          if(call Radio.send(msg) == SUCCESS) {
            memcpy(&g_PanEntry, &g_ScanPanEntry, sizeof(struct PanEntry));
            switchClientState(CLIENT_STATE_DISASSOCIATING);
            //return and then wait for sendDone to comeback
            //after Radio.sendDone we'll go into handleDisAssociateSendDone()
            return;
          }
          else {
            call MessagePool.free(msg);
          }
        } else {
          //can't get a message
        }
      }
      doSnooze();
      return;
    }

    memcpy(&g_PanEntry, &g_ScanPanEntry, sizeof(struct PanEntry));

    if ( channel <= 0 || AssociateRequest() != SUCCESS ) {
      // We failed to go to association state.  Restart IDLE state and try again in 2 seconds
      g_ClientState = CLIENT_STATE_IDLE;
      call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );
    }
  }
 
  void handleScanSendDone(struct Message *msg, result_t result )
  {
    call MessagePool.free(msg);
    call Timer.start( TIMER_ONE_SHOT, TIMEOUT_SCAN_PER_CHANNEL );
  }

  void handleDisAssociateSendDone(struct Message *msg, result_t result )
  {
    //this function is called after you get a sendDone from sending
    //out a disassociation message to an old access point
    
    call MessagePool.free(msg);

    signal Client.connected(FALSE);

    if ( AssociateRequest() != SUCCESS ) {
      // We failed to go to association state.  Restart IDLE state and try again in 2 seconds
      switchClientState(CLIENT_STATE_IDLE);
      call CC2420Control.set_power_state( POWER_STATE_VREG_OFF );
    }
  }
 
  
  void handleScanTimeout()
  {
    struct Message *msg;

    //if it is a rescan, look at send queue
    /* XXX
    if(g_Flags & CLIENT_FLAG_RESCAN) {
      if(count_queue(g_SendQueue)) {
        call CC2420Control.set_channel(g_PanEntry.channel);
        call CC2420Control.set_pan_id(g_PanEntry.id);
        g_Flags |= CLIENT_FLAG_RESCAN_INTERRUPTED;
        sendFromQueue( TRUE );
        return;
      }
    }*/

    g_ScanChannel++;
    if ( g_ScanChannel > 27 ) {
      //XXX g_Flags &= ~CLIENT_FLAG_RESCAN_INTERRUPTED;
      return ScanDone( g_ScanPanEntry.channel );
    }

    call CC2420Control.set_channel( g_ScanChannel );

    msg = call MessagePool.alloc();
    if ( msg ) {
      makeBeaconRequestFrame(msg);
      if ( (call Radio.send(msg) == SUCCESS) )
	return;
      call MessagePool.free(msg);
    }

    // We failed to get a scan message out.  Shut off; try later
    ScanDone( -1 );
  }

  enum {
    BEACON_SUPERFRAME_BATTERY_LIFE_EXT   = 0x10,
    BEACON_SUPERFRAME_PAN_COORDINATOR    = 0x40,
    BEACON_SUPERFRAME_ASSOCIATION_PERMIT = 0x80
  };

  bool isValidBeaconFrame( struct Message *msg, struct DecodedHeader *header )
  {
    if ( (header->fcf1 != FRAME_TYPE_BEACON) ||   // We don't allow security-enabled beacons
	 (header->fcf2 != SRC_MODE_SHORT && header->fcf2 != SRC_MODE_LONG) ||
	 (msg_get_length(msg) < 5) ||
	 (msg_get_uint8(msg,0) != 0x0f) ||      // superframe 1
	 !(msg_get_uint8(msg,1) & BEACON_SUPERFRAME_ASSOCIATION_PERMIT) || // superframe 2
	 (msg_get_uint8(msg,2) != 0) ||         // GTS
	 (msg_get_uint8(msg,3) != 0) ||         // Pending
	 (msg_get_uint8(msg,4) != HANDHELDS_IP_NETWORK))
      return FALSE;

    // Can we skip the SSID check?
    if ( infomem->ssid[0] == 0 )
      return TRUE;

    if (msg_get_length(msg) < 5 + strlen(infomem->ssid))
      return FALSE;

    return msg_cmp_str( msg, 5, infomem->ssid );
  }

  void handleScanMessage( struct Message *msg, struct DecodedHeader *header )
  {
    // Ignore this response if it isn't a valid beacon frame or if we already
    // have a stronger signal
    if ( isValidBeaconFrame(msg,header) && 
	 (g_ScanPanEntry.channel == 0 || header->rssi > g_ScanPanEntry.rssi)) {

      g_ScanPanEntry.id    = header->src.pan_id; 
      g_ScanPanEntry.flags = 0;
      if (msg_get_uint8(msg,1) & BEACON_SUPERFRAME_PAN_COORDINATOR)
	g_ScanPanEntry.flags = PAN_FLAG_COORDINATOR;

      // The 'isBeaconFrame' check validated the source mode
      if ( header->fcf2 == SRC_MODE_SHORT ) {
	g_ScanPanEntry.saddr = header->src.a.saddr;
	g_ScanPanEntry.flags |= PAN_FLAG_AP_SADDR;
      }
      else {
	memcpy( g_ScanPanEntry.laddr, header->src.a.laddr, 8 );
      }

      g_ScanPanEntry.channel = g_ScanChannel;
      g_ScanPanEntry.rssi    = header->rssi;
    }

    call MessagePool.free(msg);
  }

  /* 
   * Switch into scanning mode. Only enter this when the radio is turned on.
   */

  void ScanRequest()
  {
    switchClientState(CLIENT_STATE_SCAN);

    //clear the states in ScanPanEntry
    memset(&g_ScanPanEntry, 0, sizeof(struct PanEntry));

    //if it is an interrupted rescan, we will continue from where it was stopped
    //XXX if(!(g_Flags & CLIENT_FLAG_RESCAN_INTERRUPTED)) {
      g_ScanPanEntry.channel = 0;
      g_ScanChannel      = 10;
    //}
    
    call CC2420Control.set_pan_id( 0xffff );
    handleScanTimeout();
  }

  /*****************************************
   * Core state machine and event handling
   *****************************************/

  event result_t Timer.fired() {
    switch (g_ClientState) {
    case CLIENT_STATE_IDLE:
      call CC2420Control.set_power_state( POWER_STATE_ACTIVE );  
      break;

    case CLIENT_STATE_SCAN:
      handleScanTimeout();
      break;

    case CLIENT_STATE_ASSOCIATE:
      handleAssociateTimeout();
      break;

    case CLIENT_STATE_ACTIVE_WAIT:
      handleActiveWaitTimeout();
      break;

    case CLIENT_STATE_SNOOZE:
    case CLIENT_STATE_SNOOZE_POWER_DOWN:
    case CLIENT_STATE_SNOOZE_POWER_UP:
      handleSnoozeTimeout();
      break;

    case CLIENT_STATE_DISASSOCIATED:  // We were in ACTIVE_WAIT and we got a disassociate notification
      signal Client.connected(FALSE);
      ScanRequest();
      break;

    default:
      break;
    }
    return SUCCESS;
  }

  event result_t AutoReScanTimer.fired() {
    g_AutoReScanTimeout++;
    return SUCCESS;
  }

  async event bool CC2420Control.is_data_pending( uint8_t src_mode, uint8_t *pan_id, uint8_t *src_addr )
  {
    return FALSE;
  }

  event void CC2420Control.power_state_change( enum POWER_STATE state )
  {
    switch ( g_ClientState ) {
    case CLIENT_STATE_IDLE:
      if ( state == POWER_STATE_ACTIVE )
	ScanRequest(); 
      else
	call Timer.start( TIMER_ONE_SHOT, TIMEOUT_FAILED_SCAN );
      break;

    case CLIENT_STATE_SNOOZE:
    case CLIENT_STATE_SNOOZE_POWER_DOWN:
    case CLIENT_STATE_SNOOZE_POWER_UP:
      if ( state == POWER_STATE_ACTIVE )
	handleSnoozePowerUp();
      else
	handleSnoozePowerDown();
      break;

    case CLIENT_STATE_SCAN:
    case CLIENT_STATE_ASSOCIATE:
    case CLIENT_STATE_ACTIVE_WAIT:
    default:
      break;
    }
  }

  void checkReScan();

  event void Radio.sendDone( struct Message *msg, result_t result, int flags )
  {
    switch ( g_ClientState ) {
    case CLIENT_STATE_ASSOCIATE:
      handleAssociateSendDone( msg, result );
      break;

    case CLIENT_STATE_ACTIVE_TX:
      recordAckRSSI(flags);
      checkReScan();
      handleActiveTxSendDone( msg, result, flags );
      break;

    case CLIENT_STATE_SCAN:
      handleScanSendDone( msg, result );
      break;

    case CLIENT_STATE_DISASSOCIATING:
      handleDisAssociateSendDone( msg, result );
      break;

    default:
      call MessagePool.free(msg);
      break;
    }
  }

  void checkReScan() {
    //Re-scan if the rssi running average goes below (rssiRef - RSSI_TOLERANCE)
    if ((g_rssiRef - g_PanEntry.rssi) > RSSI_TOLERANCE) 
      g_Flags |= CLIENT_FLAG_RESCAN;
  }
 
  event void Radio.receive( struct Message *msg ) 
  {
    struct DecodedHeader head;

    if (!call IEEEUtility.decodeHeader( msg, &head )) {
      call MessagePool.free(msg);
      return;
    }

    switch ( g_ClientState ) {
    case CLIENT_STATE_SCAN:
      // dont clear rssi here or we'll end up with the last access point always.
      handleScanMessage(msg,&head);
      break;

    case CLIENT_STATE_ASSOCIATE:
      clearRSSI();
      handleAssociateMessage(msg,&head);
      break;

    case CLIENT_STATE_ACTIVE_TX:
      recordRSSI(&head);
      checkReScan();
      handleActiveTxReceive(msg,&head);
      break;

    case CLIENT_STATE_ACTIVE_WAIT:
      recordRSSI(&head);
      checkReScan();
      handleActiveWaitReceive(msg,&head);
      break;

    case CLIENT_STATE_SNOOZE:
    case CLIENT_STATE_SNOOZE_POWER_DOWN:
    case CLIENT_STATE_SNOOZE_POWER_UP:
      recordRSSI(&head);
      checkReScan();
      handleSnoozeReceive(msg,&head);
      break;

    case CLIENT_STATE_IDLE:
    case CLIENT_STATE_DISASSOCIATED:
    case CLIENT_STATE_DISASSOCIATING:
    default:
      clearRSSI();
      call MessagePool.free(msg);
      break;
    }
  }

  void handleStandardSend( struct Message *msg )
  {
    append_queue( &g_SendQueue, msg );
  }

  /***********************************************/

  command result_t Message.send( struct Message *msg )
  {
    switch (g_ClientState) {
    case CLIENT_STATE_SNOOZE:
    case CLIENT_STATE_SNOOZE_POWER_DOWN:
    case CLIENT_STATE_SNOOZE_POWER_UP:
      handleSnoozeSend(msg);
      return SUCCESS;

    case CLIENT_STATE_ACTIVE_TX:
      handleActiveTxSend(msg);
      return SUCCESS;

    case CLIENT_STATE_ACTIVE_WAIT:
      handleActiveWaitSend(msg);
      return SUCCESS;

    case CLIENT_STATE_DISASSOCIATING:
      handleStandardSend(msg);
      return SUCCESS;

    case CLIENT_STATE_ASSOCIATE:
      handleStandardSend(msg);
      return SUCCESS;

    case CLIENT_STATE_SCAN:
      if(g_Flags & CLIENT_FLAG_RESCAN)
        handleStandardSend(msg);
      return SUCCESS;
    }

    g_PktDrop++;
    return FAIL;  // Don't allow sending if we're not connected
  }

  /*****************************************************************/

  const struct Param s_Client[] = {
    { "pan_id",  PARAM_TYPE_HEX16,   &g_PanEntry.id },
    { "saddr",   PARAM_TYPE_UINT16,  &g_PanEntry.saddr },
    { "channel", PARAM_TYPE_UINT8,   &g_PanEntry.channel },
    { "rssi",    PARAM_TYPE_INT8,    &g_PanEntry.rssi },
    { "rssiRef", PARAM_TYPE_INT8,    &g_rssiRef },
    { "flags",   PARAM_TYPE_HEX8,    &g_PanEntry.flags },
    { "state",   PARAM_TYPE_UINT8,   &g_ClientState },
    { "scanChannel",   PARAM_TYPE_UINT8,  &g_ScanChannel },
    { "snoozeTimeout",   PARAM_TYPE_UINT8,  &g_SnoozeTimeout },
    { "autoReScanTimeout",   PARAM_TYPE_UINT8,  &g_AutoReScanTimeout },
    { "pkt_dropped",   PARAM_TYPE_UINT8,  &g_PktDrop },
    { NULL, 0, NULL }
  };

  struct ParamList g_ClientList   = { "client",   &s_Client[0] };

  command result_t ParamView.init()
  {
    signal ParamView.add( &g_ClientList );
    return SUCCESS;
  }
}


