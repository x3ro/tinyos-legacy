// $Id: GenericCommPromiscuous.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * GenericCommPromiscuous wrapper for legacy support for 
 * TinyOS 1.x applications.  All new applications should use 
 * SPC instead of GenericCommPromiscuous.  All data traffic
 * passed through SPC is promiscuous, so there is no longer
 * a need for a separate promiscuous component.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration GenericCommPromiscuous
{
  provides {
    interface StdControl as Control;
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }
}
implementation
{

#warning "GenericCommPromiscuous is deprecated, please use GenericComm instead"

  // GenericCommPromiscuous is just the same as GenericComm now
  components GenericComm as Comm;
  Control = Comm;
  SendMsg = Comm;
  ReceiveMsg = Comm;
  
}
