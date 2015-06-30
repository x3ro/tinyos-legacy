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
 * Implementation of abstract data types for SP messages.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPMessage {
  
  /**
   * Get the first TOS_Msg associated with this SP message.
   */
  command TOS_Msg* getTosMsg( sp_message_t* spmsg );

  /**
   * Get the destination address of the message.
   */
  command sp_address_t getAddr( sp_message_t* spmsg );

  /**
   * Get the destination device used for this message
   */
  command sp_device_t getDev( sp_message_t* spmsg );

  /**
   * Get the flags associated with the message.
   */
  command sp_message_flags_t getFlags( sp_message_t* spmsg );

  /**
   * Get the number of message futures for a particular message.
   */
  command uint8_t getQuantity( sp_message_t* spmsg );

}
