/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
// $Id: RobotTB_AM.h,v 1.3 2005/04/15 20:10:07 phoebusc Exp $
/** Location for putting all AM types of messages used.  This is to
 *  ensure that when an author commits his/her files into the
 *  repository, he/she is aware of any AM type conflicts with other
 *  message types in the repository.  Each commit adding a new message
 *  type should involve a "merge" with this file.
 *
 *  By reducing AM type conflicts in the repository, we hope that
 *  multiple applications can be running on the network at the same
 *  time with the same group ID, without conflict.
 *
 *  All other mesasge files should have an #include "RobotTB_AM.h"
 *  statement at the top.
 *  
 *  @author Phoebus Chen
 *  @modified 12/7/2004 Added Multihop message AM IDs
 *  @modified 9/30/2004 First Implementation
 */

/* Note For Multihop messages:
 * Multiphop embedded packets for MIG should duplicate AM IDs of
 * original packet (see README.ucbRoboApps for details).
 *
 * If you are using two different routing schemes for disseminating
 * and aggregating packets, you should choose two distinct AM packet
 * IDs, one for dissemination and one for aggregation. This is so that
 * the base station can distinguish between the two types and parse
 * the packets properly.  Again, for more details, read
 * README.ucbRoboApps .
 *
 * Naming Convention:
 * Multihop messages AM ID Range 100-200.
 * Multihop messages should have MHOP or BCAST (or equivalent) in AM name.
 * Messages for MIG should have _MIG appended to AM Name.
 */

// Please put the application name next to an AM type in comments.
enum {
  AM_MAGREPORTMSG = 1, //MagLightTrail, MagLocalAggRpt
  AM_MAGQUERYCONFIGMSG = 2, //MagLightTrail, MagLocalAggRpt
  AM_MAGLEADERREPORTMSG = 3, //MagLocalAggRpt

  //Multihop messages.  Do not use 250, used by AM_MULTIHOPMSG or 3,
  //used by AM_DEBUGPACKET in MintRoute.
  //
  //Also, MintRoute apparently uses AM id = 3, without using the
  //defined constant AM_DEBUGPACKET = 3 in MultiHop.h . See
  //WMEWMAMultiHopRouter.nc
  AM_MAGDEBUGMSG = 100, //General Debug Messages
  AM_MAGREPORTMHOPMSG = 101, //MagMHopRpt
  AM_MAGREPORTMHOPMSG_MIG = 101, //MagMHopRpt
  AM_MAGQUERYCONFIGBCASTMSG = 102, //MagMHopRpt
  AM_MAGQUERYCONFIGBCASTMSG_MIG = 102, //MagMHopRpt
  AM_MAGQUERYRPTMHOPMSG = 103, //MagMHopRpt
  AM_MAGQUERYRPTMHOPMSG_MIG = 103, //MagMHopRpt
};

