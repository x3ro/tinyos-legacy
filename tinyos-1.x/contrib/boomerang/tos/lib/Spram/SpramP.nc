/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

#include "Spram.h"

/**
 * Implementation of Spram.
 *
 * @author Cory Sharp, Moteiv Corporation <info@moteiv.com>
 */
generic module SpramP( uint16_t MaxSizeBytes ) {
  provides interface Init;
  provides interface Spram;

  uses interface BitVector as PageVector;
  uses interface Random;

  uses interface SPSend as RequestSend;
  uses interface SPReceive as RequestReceive;

  uses interface SPSend as DataSend;
  uses interface SPReceive as DataReceive;

  uses interface Timer2<TMilli> as AdvertiseTimer;
  uses interface Timer2<TMilli> as BurstTimer;
  uses interface Timer2<TMilli> as ParentTimer;
  uses interface Timer2<TMilli> as RequestTimer;
  uses interface LocalTime<TMilli>;
}
implementation {

  enum {
    SPRAM_ADV_MILLI_LOG2 = 11,
    SPRAM_BURST_MILLI_LOG2 = 0, // 0 is allowed for burst backoff
    SPRAM_REQ_MILLI_LOG2 = 7,

    SPRAM_PARENT_TIMEOUT_MILLI = 1024,
    SPRAM_GOODRUN_BREAK = 10,

    MAX_SIZE_BYTES = MaxSizeBytes,

    NOT_LOCKED = 0,
    LOCKED_BY_RADIO = 1,
    LOCKED_BY_USER = 2,
  };

  uint8_t m_data[MAX_SIZE_BYTES];
  uint16_t m_size;
  uint16_t m_versionToken;
  uint8_t m_version;
  bool m_complete;
  bool m_no_version;
  bool m_locked_state;

  sp_message_t m_advertise_sp;
  sp_message_t m_burst_sp;
  sp_message_t m_request_sp;
  TOS_Msg m_advertise_msg;
  TOS_Msg m_burst_msg;
  TOS_Msg m_request_msg;

  bool m_advertise_active;
  bool m_burst_active;
  bool m_request_active;
  bool m_uart_active;
  uint16_t m_burst_begin;
  uint16_t m_burst_end;
  uint16_t m_parent_addr;
  uint16_t m_parent_quality;


  // forward declares

  void start_advertise();
  void stop_advertise();
  void start_request();
  void prepare_data_msg( TOS_MsgPtr msg, uint16_t page );
  void start_burst( uint16_t page_begin, uint16_t page_end );
  void stop_burst();

  uint16_t min_u16( uint16_t a, uint16_t b ) {
    return (a<b) ? a : b;
  }


  // calculate timeouts

  uint16_t calc_backoff( uint16_t base, uint16_t rand_mask ) {
    return base + (call Random.rand() & rand_mask);
  }

  uint16_t backoff_advertise() {
    return calc_backoff( 1 << (SPRAM_ADV_MILLI_LOG2-1), (1 << SPRAM_ADV_MILLI_LOG2)-1 );
  }

  uint16_t backoff_burst() {
    return calc_backoff( SPRAM_BURST_MILLI_LOG2 ? 1 << (SPRAM_BURST_MILLI_LOG2-1) : 0, (1 << SPRAM_BURST_MILLI_LOG2)-1 );
  }

  uint16_t backoff_request() {
    return calc_backoff( 1 << (SPRAM_REQ_MILLI_LOG2-1), (1 << SPRAM_REQ_MILLI_LOG2)-1 );
  }


  /* == Manage image ==
  
     * A new image aborts any current behavior
     * Flushes the current image
     * Starts a request timer
  */

  void new_image( uint16_t size, uint8_t version, uint16_t token ) {
    stop_burst();

    m_version = version;
    m_versionToken = token;
    m_size = min_u16( size, MAX_SIZE_BYTES );
    m_complete = FALSE;
    m_no_version = FALSE;
    call PageVector.clearAll();

    start_advertise();
    start_request();

    m_locked_state = LOCKED_BY_RADIO;
    signal Spram.locked(); //"currently invalid"
  }


  /* == Manage parent ==

     * the parent is used for addressing requests

     * uart as a parent dominates all radio parents until its timeout
     ** dominates here means that radio messages are ignored until the timeout
     ** and any radio burst is stopped

     * a parent with better lqi overrides one with worse lqi

     * if the parent times out
     ** then it defaults back to broadcast
     ** which allows a new parent to be selected

     * the timeout is reset if
     ** a new parent is selected
     ** current parent updates its lqi
  */

  void set_parent( uint16_t addr, uint8_t quality ) {
    if( (!m_uart_active)
        && ( (quality > m_parent_quality)
             || (m_parent_addr == TOS_BCAST_ADDR)
             || (m_parent_addr == addr) ) )
    {
      m_parent_addr = addr;
      m_parent_quality = quality;
      call ParentTimer.startOneShot( SPRAM_PARENT_TIMEOUT_MILLI );
    }
  }

  event void ParentTimer.fired() {
    m_parent_addr = TOS_BCAST_ADDR;
    m_uart_active = FALSE;
  }


  bool uart_dominates( sp_message_t* sp ) {
    if( sp->dev == SP_I_UART ) {
      if( !m_uart_active )
        stop_burst();
      m_uart_active = TRUE;
      m_parent_addr = TOS_UART_ADDR;
      call ParentTimer.startOneShot( SPRAM_PARENT_TIMEOUT_MILLI );
      return TRUE;
    }
    else {
      return !m_uart_active;
    }
  }

  bool is_sharing() {
    return m_locked_state != LOCKED_BY_USER;
  }


  /* == Manage advertisements ==

     * Advertisements occur peridocially
     ** Unless there is no local version

     * Are deferred by any other behavior
     ** Incoming/outgoing requests
     ** Incoming/outgoing bursts

     * Old advertisements are ignored

     * Advertisements are broadcast over the radio
     * Or over the uart if it is active
  */

  void start_advertise() {
    m_advertise_active = TRUE;
    call AdvertiseTimer.startOneShot( backoff_advertise() );
  }

  void stop_advertise() {
    m_advertise_active = FALSE;
    call AdvertiseTimer.stop();
  }

  task void send_advertise_data_msg() {
    if( call DataSend.send( &m_advertise_sp, &m_advertise_msg, m_advertise_msg.addr, m_advertise_msg.length ) != SUCCESS )
      post send_advertise_data_msg();
  }

  event void AdvertiseTimer.fired() {
    if( is_sharing() && m_advertise_active ) {
      prepare_data_msg( &m_advertise_msg, 0 );
      post send_advertise_data_msg();
    }
  }


  /* == Manage bursts ==

     * Bursts are a response to a data request that can be satisfied
     * Or to a request for version information even if there is no local version

     * Are always broadcast over the radio
     * Or over the uart if it is active

     * An ongoing burst ignores new burst requests
  */

  void continue_burst();

  void start_burst( uint16_t page_begin, uint16_t page_end ) {
    if( m_burst_active == FALSE ) {
      m_burst_active = TRUE;
      m_burst_begin = page_begin;
      m_burst_end = page_end;
      continue_burst();
    }
  }

  void stop_burst() {
    m_burst_active = FALSE;
  }

  task void send_burst_data_msg() {
    if( call DataSend.send( &m_burst_sp, &m_burst_msg, m_burst_msg.addr, m_burst_msg.length ) != SUCCESS )
      post send_burst_data_msg();
  }

  void send_burst() {
    if( m_burst_active ) {
      while( m_burst_begin < m_burst_end ) {
        if( m_no_version || call PageVector.get(m_burst_begin) ) {
          prepare_data_msg( &m_burst_msg, m_burst_begin++ );
          post send_burst_data_msg();
          if( m_no_version )
            m_burst_end = m_burst_begin;
          return;
        }
        else {
          m_burst_begin++;
        }
      }
      m_burst_active = FALSE;
    }
  }

  void continue_burst() {
    if( SPRAM_BURST_MILLI_LOG2 == 0 )
      send_burst();
    else
      call BurstTimer.startOneShot( backoff_burst() );
  }

  event void BurstTimer.fired() {
    if( is_sharing() && (SPRAM_BURST_MILLI_LOG2 != 0) )
      send_burst();
  }


  /* == Manage data ==

     * Data messages come from burst or advertisement
     * Received data messages do not distinguish between the two
  */

  void prepare_data_msg( TOS_MsgPtr msg, uint16_t page ) {
    SpramDataMsg_t* body = (SpramDataMsg_t*)msg->data;

    body->addrSender = TOS_LOCAL_ADDRESS;
    body->bytesBegin = SPRAM_BYTES_PER_MSG * page;
    body->bytesTotal = m_size;
    body->versionToken = m_versionToken;
    body->version = m_version;
    body->flags = 0;
    if( m_no_version )
      body->flags |= SPRAM_FLAG_NO_VERSION;
    if( m_complete )
      body->flags |= SPRAM_FLAG_COMPLETE_VERSION;
    memcpy( body->bytes, m_data+body->bytesBegin, SPRAM_BYTES_PER_MSG );

    msg->addr = m_uart_active ? TOS_UART_ADDR : TOS_BCAST_ADDR;
    msg->length = sizeof(SpramDataMsg_t) + SPRAM_BYTES_PER_MSG;
  }

  event void DataSend.sendDone( sp_message_t* sp, sp_message_flags_t flags, sp_error_t error ) {
    if( sp == &m_burst_sp )
      continue_burst();
    else if( sp == &m_advertise_sp )
      start_advertise();
  }


  // >0 ==> remote version is newer
  // =0 ==> remote version is current
  // <0 ==> remote version is older
  int compare_remote_version( uint8_t version, uint16_t token, uint8_t nover ) {
    if( m_no_version ) {
      return (nover ? 0 : 1);
    }
    else if( nover ) {
      return -1;
    }
    else {
      int8_t verDelta = version - m_version;
      return (verDelta == 0) ? (token - m_versionToken) : verDelta;
    }
  }


  event void DataReceive.receive( sp_message_t* spmsg, TOS_MsgPtr msg, sp_error_t result ) {

    if( is_sharing() && uart_dominates(spmsg) ) {

      SpramDataMsg_t* body = (SpramDataMsg_t*)msg->data;
      uint8_t remote_nover = body->flags & SPRAM_FLAG_NO_VERSION;
      int versionDelta = compare_remote_version( body->version, body->versionToken, remote_nover );

      if( versionDelta > 0 )
        new_image( body->bytesTotal, body->version, body->versionToken );

      // if the remote version is current or better and not "no version"
      if( (versionDelta >= 0) && !remote_nover ) {

        // if we have an incomplete image, and this message is valid, take the bytes from this message
        if( (m_complete == FALSE) && (body->bytesBegin < m_size) ) {

          const uint16_t page = body->bytesBegin / SPRAM_BYTES_PER_MSG;
          if( !call PageVector.get(page) ) {

            // prevent buffer overrun
            uint16_t length = min_u16( msg->length-sizeof(SpramDataMsg_t), m_size-body->bytesBegin );

            set_parent( body->addrSender, msg->lqi );

            m_no_version = FALSE;
            memcpy( m_data+body->bytesBegin, body->bytes, length );
            call PageVector.set( page );
          }

          // defer pending requests
          start_request();
        }

        // defer pending advertisements
        start_advertise();
      }
    }
  }


  /* == Manage requests ==

     * Requests are initiated by a new image
     * And stop only when the image is complete

     * Requests are defferred by
     ** Incoming data with the same or better version number

     * Responses to broadcast requests only return the first requested page
     ** This allows the receiver to select a suitable parent
  */

  void start_request() {
    m_request_active = TRUE;
    call RequestTimer.startOneShot( backoff_request() );
  }

  void stop_request() {
    m_request_active = FALSE;
    m_uart_active = FALSE;
    m_parent_addr = TOS_UART_ADDR;
    call RequestTimer.stop();
  }


  task void updated() {
    signal Spram.updated();
  }


  task void send_request_msg() {
    if( call RequestSend.send( &m_request_sp, &m_request_msg, m_request_msg.addr, m_request_msg.length ) != SUCCESS )
      post send_request_msg();
  }


  bool prepare_request_msg( uint16_t begin, uint16_t end ) {
    end = min_u16( end, min_u16( m_size, MAX_SIZE_BYTES ) );
    if( begin < end ) {
      SpramRequestMsg_t* body = (SpramRequestMsg_t*)m_request_msg.data;

      m_request_msg.addr = m_parent_addr;
      m_request_msg.length = sizeof(SpramRequestMsg_t);

      body->addrRequester = TOS_LOCAL_ADDRESS;
      body->bytesBegin = begin;
      body->bytesEnd = end;
      body->bytesTotal = m_size;
      body->versionToken = m_versionToken;
      body->version = m_version;
      body->flags = 0;
      if( m_no_version )
        body->flags |= SPRAM_FLAG_NO_VERSION;
      if( m_complete )
        body->flags |= SPRAM_FLAG_COMPLETE_VERSION;
      return TRUE;
    }

    return FALSE;
  }


  void formulate_request() {
    if( m_complete == FALSE ) {
      uint16_t req_begin = 1;
      uint16_t req_end = 0;
      //uint16_t iend = (m_size / SPRAM_BYTES_PER_MSG) + 1;
      uint16_t iend = (m_size + SPRAM_BYTES_PER_MSG - 1) / SPRAM_BYTES_PER_MSG;
      uint16_t missing = 0;
      uint16_t goodrun = 0;
      uint16_t i;

      if( iend > call PageVector.size() )
        iend = call PageVector.size();

      for( i=0; i<iend; i++ ) {
        if( !call PageVector.get(i) ) {
          missing++;
          goodrun = 0;
          if( req_begin > req_end )
            req_begin = i;
          req_end = i+1;
        }
        else if( (missing > 0) && (++goodrun >= SPRAM_GOODRUN_BREAK) ) {
          break;
        }
      }

      if( prepare_request_msg( SPRAM_BYTES_PER_MSG*req_begin, SPRAM_BYTES_PER_MSG*req_end ) ) {
        post send_request_msg();
      }
      else {
        m_complete = TRUE;
        stop_request();
        post updated();
      }
    }
  }


  event void RequestTimer.fired() {
    if( is_sharing() && m_request_active )
      formulate_request();
  }


  event void RequestSend.sendDone( sp_message_t* sp, sp_message_flags_t flags, sp_error_t error ) {
    if( sp == &m_request_sp ) {
      if( m_request_active )
        start_request();
    }
  }


  event void RequestReceive.receive( sp_message_t* spmsg, TOS_MsgPtr msg, sp_error_t result ) {

    if( is_sharing() && uart_dominates(spmsg) ) {

      SpramRequestMsg_t* body = (SpramRequestMsg_t*)msg->data;
      uint8_t remote_nover = body->flags & SPRAM_FLAG_NO_VERSION;
      int versionDelta = compare_remote_version( body->version, body->versionToken, remote_nover );
      uint16_t begin_page = 0;
      uint16_t end_page = 0;

      if( remote_nover || (versionDelta == 0) ) {
        begin_page = body->bytesBegin/SPRAM_BYTES_PER_MSG;
        end_page = (body->bytesEnd + SPRAM_BYTES_PER_MSG - 1) / SPRAM_BYTES_PER_MSG;
      }
      else if( versionDelta > 0 ) {
        new_image( body->bytesTotal, body->version, body->versionToken );
        set_parent( body->addrRequester, msg->lqi );
        start_request();
      }
      else {
        begin_page = 0;
        end_page = (m_size + SPRAM_BYTES_PER_MSG - 1) / SPRAM_BYTES_PER_MSG;
      }

      if( begin_page < end_page ) {
        // non-uart broadcast requests only get the first requested page
        if( (msg->addr == TOS_BCAST_ADDR) && (spmsg->dev != SP_I_UART) )
          end_page = begin_page + 1;
        start_burst( begin_page, end_page );
      }

      // if the remote version is better or equivalent, hold off on advertising the local version
      if( versionDelta >= 0 )
        start_advertise();
    }
  }



  // == Initialization ==

  void initData() {
    m_size = 0;
    m_versionToken = 0;
    m_version = 0;
    memset( m_data, 0, sizeof(m_data) );
    m_complete = FALSE;
    m_no_version = TRUE;
    m_locked_state = NOT_LOCKED;
    call PageVector.clearAll();
    stop_advertise();
  }


  command result_t Init.init() {
    initData();
    call Random.init();
    return SUCCESS;
  }


  // == Spram interface ==

  async command void* Spram.getData() {
    return m_data;
  }

  command uint16_t Spram.getSizeBytes() {
    return m_size;
  }

  command void Spram.publish( uint16_t bytes ) {
    m_version++;
    m_versionToken = call LocalTime.get();
    m_size = bytes;
    m_complete = TRUE;
    m_no_version = FALSE;
    call PageVector.setAll();

    m_locked_state = NOT_LOCKED;
    start_advertise();
  }

  default event void Spram.locked() {
  }

  default event void Spram.updated() {
  }

  command bool Spram.isValid() {
    return (m_complete == TRUE) && (m_no_version == FALSE);
  }

  command bool Spram.isLocked() {
    return !is_sharing();
  }

  // Spram locking is entirely EXPERIMENTAL
  command result_t Spram.lock() {
    if( is_sharing() ) {
      m_locked_state = LOCKED_BY_USER;
      return SUCCESS;
    }
    return FAIL;
  }

  command void Spram.invalidate() {
    initData();
  }
}

