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
// $Id: MetricsMote.nc,v 1.3 2005/11/17 23:23:48 phoebusc Exp $
/**
 * Mote with handy functions for measuring network characteristics.
 * See MetricsMoteM.nc for details.
 *
 * @author Phoebus Chen
 * @modified 10/31/2005 Copied PingPong (by Sukun Kim) over for modification
 */

includes MetricsMsg;
configuration MetricsMote
{
}
implementation
{
  components Main,
    MetricsM,
    GenericComm as Comm,
    TimerC,
    CC2420RadioC,
    LedsC;

    Main.StdControl -> MetricsM;
    Main.StdControl -> Comm;
    Main.StdControl -> TimerC;

    MetricsM.Leds -> LedsC;
    MetricsM.Timer -> TimerC.Timer[unique("Timer")];
    MetricsM.CC2420Control -> CC2420RadioC;

    MetricsM.ReceiveCmd -> Comm.ReceiveMsg[AM_METRICSCMDMSG];
    MetricsM.SendReply -> Comm.SendMsg[AM_METRICSREPLYMSG];
}

