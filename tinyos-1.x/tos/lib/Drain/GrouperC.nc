//$Id: GrouperC.nc,v 1.1 2005/10/27 21:31:04 gtolle Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

includes Grouper;
includes Ident;

/**
 * This component provides the ability to remotely set group
 * membership for nodes.
 *
 * @author Gilman Tolle <get@cs.berkeley.edu>
 */

configuration GrouperC {
  provides interface StdControl;
}

implementation {

  components 
    GrouperM,
    GroupManagerC,
    DripC, 
    DripStateC,
    GenericComm,
    LedsC;

#if defined(PLATFORM_TELOSB)
  components DS2411C;
#endif

  StdControl = GrouperM;

  GrouperM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_GROUPERCMDMSG];
  GrouperM.Receive -> DripC.Receive[AM_GROUPERCMDMSG];
  GrouperM.Drip -> DripC.Drip[AM_GROUPERCMDMSG];
  DripC.DripState[AM_GROUPERCMDMSG] -> DripStateC.DripState[unique("DripState")];

#if defined(PLATFORM_TELOSB)
  GrouperM.DS2411 -> DS2411C;
#endif

  GrouperM.GroupManager -> GroupManagerC;
  GrouperM.Leds -> LedsC;
}
