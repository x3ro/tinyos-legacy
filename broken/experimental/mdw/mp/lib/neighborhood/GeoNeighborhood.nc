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

/**
 * GeoNeighborhood: Pick all one-hop radio neighbors within a given radius 
 * of the node.
 */
configuration GeoNeighborhood {
  provides {
    interface Neighborhood;
  }
} implementation {

  components Main, RadioNeighborhood, GeoNeighborhoodM, 
    SharedVarOneHop, FakeLocation, TimerC;

  Neighborhood = GeoNeighborhoodM;

  Main.StdControl -> GeoNeighborhoodM;
  Main.StdControl -> TimerC;
  GeoNeighborhoodM.SV_location -> SharedVarOneHop.SharedVar[3];
  GeoNeighborhoodM.RadioNeighborhood -> RadioNeighborhood.Neighborhood;
  GeoNeighborhoodM.Location -> FakeLocation;
  GeoNeighborhoodM.Timer -> TimerC.Timer[unique("Timer")];

} 
