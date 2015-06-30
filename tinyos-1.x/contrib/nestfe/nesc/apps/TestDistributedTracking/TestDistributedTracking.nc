/*									tab:2
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

/*
 * @author Michael Manzo <mpm@eecs.berkeley.edu>
 */

includes DistributedTracking;
includes Bcast;
includes DetectionEvent; //for definition of location_t type in RegistryC

configuration TestDistributedTracking {
}

implementation {
  components Main, 
    DistributedTrackingC, 
    GenericComm, 
    DrainC as RouteToPoint,
    KrakenC,
#ifdef USE_DETECTIONEVENT
    DetectionEventC,
#endif
#ifdef USE_SIMPLE_THRESHOLD
    PIRSimpleThreshEventC,
#endif
#ifdef USE_PIRDETECT
    PIRDetectEventC,
#endif
#ifdef USE_PIRRAWDRIVER
    PIRRawDriverC,
#endif
    TimerC;

  Main.StdControl -> KrakenC;
#ifdef USE_DETECTIONEVENT
  Main.StdControl -> DetectionEventC; 
#endif
  Main.StdControl -> DistributedTrackingC;
  Main.StdControl -> RouteToPoint;
  Main.StdControl -> GenericComm;

#ifdef USE_DETECTIONEVENT
  Main.StdControl -> DetectionEventC;
#endif

#ifdef USE_PIRRAWDRIVER
  Main.StdControl -> PIRRawDriverC;
#else
#ifdef USE_SIMPLE_THRESHOLD
  Main.StdControl -> PIRSimpleThreshEventC;
#else
#ifdef USE_PIRRAWDRIVER
Main.StdControl -> PIRRawDriverC;
#endif
#ifdef USE_PIRDETECT
  Main.StdControl -> PIRDetectEventC;
#endif
#endif
#endif

  Main.StdControl -> TimerC;
}
