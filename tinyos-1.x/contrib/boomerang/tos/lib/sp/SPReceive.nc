// $Id: SPReceive.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $ 
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
 * Standard receiving interface for receiving messages from link protocols.
 * SPReceive will signal messages on a particular active message type
 * from all available underlying links.  
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface SPReceive
{
  /**
   * Notification that a packet (TOSMsg) has been received.
   * The pointers passed into the receive function are <b>only valid</b>
   * within the context of the function.  Once the callee returns control
   * to the caller, the pointers are no longer valid.  Users of this
   * interface must copy data or perform actions before returning from
   * the receive handler.
   * <p>
   * To access the device on which the message was received, call the
   * <tt>SPMessage.getDev(sp_message_t*)</tt>
   * and then query the device using the <tt>SPInterface</tt> interface.
   *
   * @param spmsg An sp_message_t structure containing metadata about the
   *              received message.  Access sp_message_t fields <b>only</b>
   *              through the SPMessage interface.
   * @param tosmsg The packet received.
   * @param result Indication of an error, if any, during message reception.
   */
  event void receive(sp_message_t* spmsg, TOS_MsgPtr tosmsg, sp_error_t result);
}
