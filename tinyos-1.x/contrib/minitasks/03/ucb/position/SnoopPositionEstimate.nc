/*									tab:4
 *
 *
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * Description: Filter snooped packets by RSSI to guess general location.
 * History:   July 10, 2003         Inception.
 *
 */


configuration SnoopPositionEstimate {
	provides interface StdControl;
}

implementation {
	components SnoopPositionEstimateM, TimerC, RandomLFSR;
	components RoutingC, ConfigC, RSSILocalizationRoutingM;

	StdControl = SnoopPositionEstimateM;
	SnoopPositionEstimateM.Timer -> TimerC.Timer[unique("Timer")];
	SnoopPositionEstimateM.Random -> RandomLFSR;
	SnoopPositionEstimateM.SendMsg -> RoutingC.RoutingSendBySingleBroadcast[66];
	// This is autowired.  Sorry, this is REALLY BAD to do without better
	// warnings / errors / documentation.
	// SnoopPositionEstimateM.Config_SnoopEstimationRate -> ConfigC;
	SnoopPositionEstimateM.RSSILocalizationRouting -> RSSILocalizationRoutingM;
}
