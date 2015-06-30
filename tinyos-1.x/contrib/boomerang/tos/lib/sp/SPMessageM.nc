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
 * Implementation of abstract field accessors for SPMessage.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
module SPMessageM {
  provides interface SPMessage;
}
implementation {
  command TOS_Msg* SPMessage.getTosMsg( sp_message_t* spmsg ) {
    return spmsg->msg;
  }

  command sp_address_t SPMessage.getAddr( sp_message_t* spmsg ) {
    return spmsg->addr;
  }

  command sp_device_t SPMessage.getDev( sp_message_t* spmsg ) {
    return spmsg->dev;
  }

  command sp_message_flags_t SPMessage.getFlags( sp_message_t* spmsg ) {
    return spmsg->flags;
  }

  command uint8_t SPMessage.getQuantity( sp_message_t* spmsg ) {
    return spmsg->quantity;
  }

}
