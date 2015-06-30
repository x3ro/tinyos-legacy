//$Id: DrainC.nc,v 1.1.1.1 2007/11/05 19:09:10 jpolastre Exp $

/*									
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

includes Drain;

/**
 * DrainC provides a many-to-one collection routing service.
 * <p>
 * Use the SendMsg interface to send a message up the tree.
 * <p>
 * Why does DrainC provide SendMsg instead of Send? Because it provides an
 * argument for a destination address. This will eventually be used to
 * select between multiple trees when sending a message, but for now,
 * it is used to decide whether to send a message up the tree, to the
 * link-local broadcast address, or to the local serial connection.
 * <p>
 * TOS_DEFAULT_ADDR means "the tree" (defined in Drain.h) <br>
 * TOS_BCAST_ADDR means "the link-local broadcast" <br>
 * TOS_UART_ADDR means "the serial connection" <br>
 * <p>
 * All messages will contain the Drain header.
 * <p>
 * The Send interface is also provided because it provides getBuffer().
 * Don't use Send.send().
 * <p>
 * The Receive interface doesn't do anything currently, but will
 * eventually be used to deliver messages that have been routed down
 * the tree from the root.
 * <p>
 * Intercept and Snoop have the usual meanings.
 * <p>
 * NOTE: Drain provides three Nucleus attributes for status
 * reporting. You do not have to include the Nucleus system to use
 * Drain, but to compile it, you must make sure that the Nucleus
 * directory is in the include path, so Attrs.h can be found.
 * <p>
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

configuration DrainC {
  
  provides {
    interface StdControl;

    interface Drain;
    interface DrainGroup;

    interface RouteControl;

    interface SendMsg[uint8_t id];
    interface Send[uint8_t id];

    interface Receive[uint8_t id];

    interface Intercept[uint8_t id];
    interface Intercept as Snoop[uint8_t id];
  }
}

implementation {

  components 
    DrainM, 
    DrainLinkEstM,
    DrainGroupManagerM,
    GroupManagerC,
    GenericComm, 
    RandomLFSR,
    TimerC,
    LedsC;

#if defined(_CC2420CONST_H)
  components CC2420RadioC;
#endif

#if defined(_CC1KCONST_H)
  components CC1000RadioC;
#endif

  StdControl = DrainM.StdControl;

  SendMsg = DrainM.SendMsg;
  Send = DrainM.Send;

  Intercept = DrainM.Intercept;
  Snoop = DrainM.Snoop;
  Receive = DrainM.Receive;

  Drain = DrainLinkEstM.Drain;
  DrainGroup = DrainGroupManagerM.DrainGroup;
  RouteControl = DrainLinkEstM;

  DrainM.SubControl -> GenericComm;
  DrainM.SubControl -> DrainLinkEstM;

  DrainM.Leds -> LedsC;

  DrainM.DrainLinkEst -> DrainLinkEstM;

  DrainM.LinkSendMsg -> GenericComm.SendMsg[AM_DRAINMSG];
  DrainM.LinkReceiveMsg -> GenericComm.ReceiveMsg[AM_DRAINMSG];

  DrainM.Timer -> TimerC.Timer[unique("Timer")];
  DrainM.PostFailTimer -> TimerC.Timer[unique("Timer")];

  DrainM.DrainGroup -> DrainGroupManagerM;

  DrainLinkEstM.Timer -> TimerC.Timer[unique("Timer")];

  DrainLinkEstM.Random -> RandomLFSR;

  DrainLinkEstM.SendMsg -> GenericComm.SendMsg[AM_DRAINBEACONMSG];
  DrainLinkEstM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_DRAINBEACONMSG];
  DrainLinkEstM.Leds -> LedsC;

  DrainLinkEstM.DrainGroup -> DrainGroupManagerM;

#if defined(_CC2420CONST_H)
  DrainM.MacControl -> CC2420RadioC;
#endif

#if defined(_CC1KCONST_H)
  DrainM.MacControl -> CC1000RadioC;
#endif
  
  DrainGroupManagerM.Send -> DrainM.Send[AM_DRAINGROUPREGISTERMSG];
  DrainGroupManagerM.SendMsg -> DrainM.SendMsg[AM_DRAINGROUPREGISTERMSG];
  DrainGroupManagerM.Intercept -> DrainM.Intercept[AM_DRAINGROUPREGISTERMSG];
  DrainGroupManagerM.GroupManager -> GroupManagerC;
}
