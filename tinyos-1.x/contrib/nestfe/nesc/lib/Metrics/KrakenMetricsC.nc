/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: KrakenMetricsC.nc,v 1.2 2005/11/17 23:02:38 phoebusc Exp $
/**
 * Module with handy functions for measuring network characteristics for
 * the Kraken application.  See KrakenMetricsM.nc for details.
 * 
 * USAGE NOTES:
 * Assumes initialization of GenericComm and DrainC by other components
 *
 * @author Phoebus Chen
 * @modified 11/8/2005 Created
 */

includes MetricsMsg;

configuration KrakenMetricsC {
  provides interface StdControl;
}
implementation {
  components KrakenMetricsM;
  components DrainC;
  components GenericComm as Comm;
  components CC2420RadioC;
  components NoLeds as LedsC;

  StdControl = KrakenMetricsM;
  //Just like DetectionEventM, assumes Generic Comm and Drain are
  //already initialized by other components in Kraken

  KrakenMetricsM.Leds -> LedsC;
  KrakenMetricsM.CC2420Control -> CC2420RadioC;
  
  KrakenMetricsM.ReceiveCmd -> Comm.ReceiveMsg[AM_METRICSCMDMSG];
  KrakenMetricsM.SendReplyMsg -> DrainC.SendMsg[AM_METRICSREPLYMSG];
  KrakenMetricsM.Send -> DrainC.Send[AM_METRICSREPLYMSG]; // for send buffer
}

