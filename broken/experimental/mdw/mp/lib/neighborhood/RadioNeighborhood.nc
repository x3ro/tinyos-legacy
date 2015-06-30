/* Copyright (c) 2002 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704. Attention: Intel License Inquiry.  
 * 
 * Author: Matt Welsh <mdw@eecs.harvard.edu>
 */

includes RadioNeighborhood;

/**
 * RadioNeighborhood: Pick all one-hop radio neighbors.
 */
configuration RadioNeighborhood {
  provides {
    interface Neighborhood;
  }
} implementation {

  components Main, RadioNeighborhoodM, TimerC, LedsC, GenericComm as Comm;

  Neighborhood = RadioNeighborhoodM;

  Main.StdControl -> Comm;
  Main.StdControl -> RadioNeighborhoodM;

  RadioNeighborhoodM.Leds -> LedsC;
  RadioNeighborhoodM.Timer -> TimerC.Timer[unique("Timer")];
  RadioNeighborhoodM.SendMsg -> Comm.SendMsg[AM_RADIONEIGHBORHOOD_BEACONMSG];
  RadioNeighborhoodM.ReceiveMsg -> Comm.ReceiveMsg[AM_RADIONEIGHBORHOOD_BEACONMSG];

} 
