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

includes YaoNeighborhood;

/**
 * YaoNeighborhood: An approximate planar mesh based on a pruned Yao graph.
 * See YaoNeighborhooM.nc for details.
 */
configuration YaoNeighborhood {
  provides {
    interface Neighborhood;
  }
} implementation {

  components Main, RadioNeighborhood, YaoNeighborhoodM, TimerC, 
    GenericComm, QueuedSend, SharedVarOneHop, FakeLocation;

  Neighborhood = YaoNeighborhoodM;

  Main.StdControl -> YaoNeighborhoodM;
  Main.StdControl -> GenericComm;

  YaoNeighborhoodM.SV_location -> SharedVarOneHop.SharedVar[2];
  YaoNeighborhoodM.RadioNeighborhood -> RadioNeighborhood.Neighborhood;
  YaoNeighborhoodM.Location -> FakeLocation;
  YaoNeighborhoodM.Timer -> TimerC.Timer[unique("Timer")];
  YaoNeighborhoodM.SendPickEdgeMsg -> QueuedSend.SendMsg[AM_YAONEIGHBORHOOD_PICKEDGEMSG];
  YaoNeighborhoodM.ReceivePickEdgeMsg -> GenericComm.ReceiveMsg[AM_YAONEIGHBORHOOD_PICKEDGEMSG];
  YaoNeighborhoodM.SendInvalidateMsg -> QueuedSend.SendMsg[AM_YAONEIGHBORHOOD_INVALIDATEMSG];
  YaoNeighborhoodM.ReceiveInvalidateMsg -> GenericComm.ReceiveMsg[AM_YAONEIGHBORHOOD_INVALIDATEMSG];

} 
