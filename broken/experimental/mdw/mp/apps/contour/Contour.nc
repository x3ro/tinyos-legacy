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
 * Contour finding: Find boundary points between regions in the sensor 
 * network above or below a given threshold sensor reading.
 */
configuration Contour {
}
implementation {
  components Main, ContourM, TimerC, Photo, 
    YaoNeighborhood, FakeLocation, SharedVarOneHop, Collective;

  Main.StdControl -> ContourM.StdControl;
  Main.StdControl -> Photo;

  ContourM.ADC -> Photo;
  ContourM.SV_location -> SharedVarOneHop.SharedVar[0];
  ContourM.SV_belowset -> SharedVarOneHop.SharedVar[1];
  ContourM.Neighborhood -> YaoNeighborhood;
  ContourM.Location -> FakeLocation;
  ContourM.Timer -> TimerC.Timer[unique("Timer")];
  ContourM.Barrier -> Collective;

}

