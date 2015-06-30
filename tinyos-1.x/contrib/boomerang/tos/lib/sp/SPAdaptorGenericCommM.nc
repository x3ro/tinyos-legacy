/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * Implementation of an adapter that converts standard TOS_Msg packets
 * into sp_message_t messages, dispatches them to SP, and then
 * decomposes the messages back into packets after transmission.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPAdaptorGenericCommM {
  provides {
    interface SendMsg[uint8_t id];
  }
  uses {
    interface SPSend[uint8_t id];
  }
}
implementation {

  sp_message_t m_pool[SP_SIZE_ADAPTOR_POOL];

  bool contains( sp_message_t* _msg ) {
#if 0
    const sp_message_t* p = m_pool + 0;
    const sp_message_t* pend = m_pool + SP_SIZE_ADAPTOR_POOL;
    for( ; p!=pend; p++ ) {
      if( p == _msg )
        return TRUE;
    }
    return FALSE;
#endif
#if 1
    return (_msg >= m_pool+0) && (_msg < m_pool+SP_SIZE_ADAPTOR_POOL);
#endif
  }

  command result_t SendMsg.send[uint8_t id](uint16_t addr, uint8_t length, TOS_MsgPtr _msg) {
    sp_message_t* p = m_pool + 0;
    const sp_message_t* pend = m_pool + SP_SIZE_ADAPTOR_POOL;

    for ( ; p!=pend; p++ ) {
      if (p->msg == NULL) {
        p->msg = _msg;

        // try to send the message
        if (call SPSend.send[id](p, _msg, addr, length) == SUCCESS)
          return SUCCESS;

        p->msg = NULL;
        return FAIL;
      }
    }

    // no room at the inn or a failure occurred
    return FAIL;
  }
  
  event void SPSend.sendDone[uint8_t id](sp_message_t* _msg, sp_message_flags_t flags, sp_error_t _success) {

    // Could probably also get away with this even cheaper check, which only
    // does bad things if other components are doing bad things:
    //   if( (_msg >= m_pool+0) && (_msg < m_pool+SP_SIZE_ADAPTOR_POOL) )

    //if( (_msg >= m_pool+0) && (_msg < m_pool+SP_SIZE_ADAPTOR_POOL) ) {
    if (contains(_msg)) {
      TOS_MsgPtr _stack = _msg->msg;
      _msg->msg = NULL;
      signal SendMsg.sendDone[_stack->type](_stack, (_success == SP_SUCCESS));
    }
  }

  default event result_t SendMsg.sendDone[uint8_t id](TOS_MsgPtr p, result_t s) { return SUCCESS; }

}
